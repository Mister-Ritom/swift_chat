import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart';
import 'package:swift_chat/core/pb_client.dart';
import 'package:pocketbase/pocketbase.dart';

class MessageHelper {
  static final _pb = PBClient.instance;

  /// Returns the chat ID for two users
  static String getChatId(String userId1, String userId2) {
    final ids = [userId1, userId2]..sort();
    final combined = ids.join(',');
    final bytes = utf8.encode(combined);
    return md5.convert(bytes).toString().substring(0, 15); // 32 chars hash
  }

  /// Create a new chat with ID as user1,user2
  static Future<RecordModel> createChat(String userId1, String userId2) async {
    final chatId = getChatId(userId1, userId2);
    return await _pb
        .collection('chats')
        .create(body: {'id': chatId, 'members': "$userId1,$userId2"});
  }

  static String _getFileName(String path) {
    final parts = path.split(RegExp(r'[\\/]+')); // handles both / and \
    return parts.isNotEmpty ? parts.last : '';
  }

  static Future<RecordModel?> getChat(String userId1, String userId2) async {
    final chatId = getChatId(userId1, userId2);
    final chatRecord = _pb.collection('chats').getFirstListItem('id="$chatId"');
    return chatRecord;
  }

  static Future<MultipartRequest> buildMessageRequest(
    String text,
    String chatId,
    List<File> files,
  ) async {
    final url = Uri.parse('${_pb.baseURL}/api/collections/messages/records');
    final request =
        MultipartRequest('POST', url)
          ..fields['message'] = text
          ..fields['chat'] = chatId
          ..fields['sender'] = _pb.authStore.record!.id
          ..headers['Authorization'] = 'Bearer ${_pb.authStore.token}';

    for (final file in files) {
      final length = await file.length();
      final stream = ByteStream(file.openRead());
      final multipartFile = MultipartFile(
        'documents',
        stream,
        length,
        filename: _getFileName(file.path),
      );
      request.files.add(multipartFile);
      log('Added file: ${file.path}, size: $length bytes');
    }

    return request;
  }
}
