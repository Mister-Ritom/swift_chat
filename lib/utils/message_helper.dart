import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart';
import 'package:swift_chat/core/pb_client.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:swift_chat/utils/file_picker_helper.dart';

class MessageHelper {
  static final _pb = PBClient.instance;

  /// Returns the chat ID for two users
  static String _getChatId(String userId1, String userId2) {
    final ids = [userId1, userId2]..sort();
    final combined = ids.join(',');
    final bytes = utf8.encode(combined);
    return md5.convert(bytes).toString().substring(0, 15); // 32 chars hash
  }

  /// Create a new chat with ID as user1,user2
  static Future<RecordModel> createChat(String userId1, String userId2) async {
    final chatId = _getChatId(userId1, userId2);
    return await _pb
        .collection('chats')
        .create(body: {'id': chatId, 'members': "$userId1,$userId2"});
  }

  static Future<RecordModel?> getChat(String userId1, String userId2) async {
    final chatId = _getChatId(userId1, userId2);
    final chats = await _pb.collection('chats').getList(filter: 'id="$chatId"');
    if (chats.items.isEmpty) return null;
    return chats.items[0];
  }

  static Future<RecordModel> getChatCreate(
    String userId1,
    String userId2,
  ) async {
    var chatRecord = await getChat(userId1, userId2);
    chatRecord ??= await createChat(userId1, userId2);
    return chatRecord;
  }

  /// Build a multipart request to send message + files
  static Future<MultipartRequest> buildMessageRequest(
    String text,
    String chatId,
    List<PickedFileData> files,
  ) async {
    final url = Uri.parse('${_pb.baseURL}/api/collections/messages/records');
    final request =
        MultipartRequest('POST', url)
          ..fields['message'] = text
          ..fields['chat'] = chatId
          ..fields['sender'] = _pb.authStore.record!.id
          ..headers['Authorization'] = 'Bearer ${_pb.authStore.token}';

    for (final file in files) {
      if (kIsWeb && file.bytes != null) {
        // Web: use bytes directly
        request.files.add(
          MultipartFile.fromBytes(
            'documents',
            file.bytes!,
            filename: file.name,
          ),
        );
        log(
          'Added web file: ${file.name}, size: ${file.bytes!.lengthInBytes} bytes',
        );
      } else if (!kIsWeb && file.path != null) {
        // Mobile: use File path
        final length = await File(file.path!).length();
        final stream = ByteStream(File(file.path!).openRead());
        final multipartFile = MultipartFile(
          'documents',
          stream,
          length,
          filename: file.name,
        );
        request.files.add(multipartFile);
        log('Added mobile file: ${file.path}, size: $length bytes');
      }
    }

    return request;
  }
}
