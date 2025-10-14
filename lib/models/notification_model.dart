import 'package:pocketbase/pocketbase.dart';

class NotificationModel {
  final String id; // PocketBase record ID
  final int files; // Number of files attached
  final String text; // Message text (0–300 chars)
  final RecordModel sender; // Sender user ID
  final String receiver; // Receiver user ID
  final String chat; // Chat ID
  final bool isRead; // Read status
  final DateTime? created;

  NotificationModel({
    required this.id,
    required this.files,
    required this.text,
    required this.sender,
    required this.receiver,
    required this.chat,
    this.isRead = false,
    required this.created,
  });
  factory NotificationModel.fromRecord(RecordModel record) {
    return NotificationModel(
      id: record.id,
      files: record.getIntValue('files'),
      text: record.getStringValue('text'),
      sender: record.get("expand.sender"),
      receiver: record.getStringValue('receiver'),
      chat: record.getStringValue('chat'),
      isRead: record.getBoolValue('isRead'),
      created: DateTime.tryParse(record.getStringValue('created')), // nullable
    );
  }
}
