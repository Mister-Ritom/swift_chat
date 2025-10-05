import 'dart:convert';
import 'dart:developer';
import 'package:crypto/crypto.dart';
import 'package:swift_chat/core/pb_client.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:swift_chat/utils/pb_utils.dart';

final _pb = PBClient.instance;

/// Returns the chat ID for two users
String getChatId(String userId1, String userId2) {
  final ids = [userId1, userId2]..sort();
  final combined = ids.join(',');
  final bytes = utf8.encode(combined);
  return md5.convert(bytes).toString().substring(0, 15); // 32 chars hash
}

/// Get chat by ID (or null if not exists)
Future<RecordModel?> getChat(String userId1, String userId2) async {
  final chatId = getChatId(userId1, userId2);
  try {
    return await _pb.collection('chats').getOne(chatId);
  } catch (e) {
    return null; // chat does not exist
  }
}

/// Create a new chat with ID as user1,user2
Future<RecordModel> createChat(String userId1, String userId2) async {
  final chatId = getChatId(userId1, userId2);
  return await _pb
      .collection('chats')
      .create(body: {'id': chatId, 'members': "$userId1,$userId2"});
}

/// Send a message; creates chat if it doesn't exist
Future<void> sendMessage(
  String messageText,
  String senderId,
  String receiverId,
) async {
  RecordModel? chat = await getChat(senderId, receiverId);
  chat ??= await createChat(senderId, receiverId);

  await _pb
      .collection('messages')
      .create(
        body: {'message': messageText, 'chat': chat.id, 'sender': senderId},
      );
}

/// Stream messages for a chat
Stream<RecordSubscriptionEvent> messagesStream(String userId1, String userId2) {
  final chatId = getChatId(userId1, userId2);
  return streamCollection('messages');
}

/// Get all chats for a user
Future<List<RecordModel>> getUserChats(String userId) async {
  final allChats = await _pb.collection('chats').getFullList();
  return allChats.where((chat) {
    final ids = chat.id.split(',');
    return ids.contains(userId);
  }).toList();
}
