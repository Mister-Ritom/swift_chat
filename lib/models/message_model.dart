import 'package:pocketbase/pocketbase.dart';
import 'package:swift_chat/core/pb_client.dart';
import 'user_model.dart'; // assuming your UserModel is here

class MessageModel {
  final String id;
  final String message;
  final UserModel sender;
  final DateTime? created;
  final List<String> documents; // store document filenames or urls

  MessageModel({
    required this.id,
    required this.message,
    required this.sender,
    required this.created,
    required this.documents,
  });

  // Create from PocketBase Record
  factory MessageModel.fromRecord(RecordModel record) {
    return MessageModel(
      id: record.id,
      message: record.getStringValue('message'),
      sender: UserModel.fromRecord(
        record.get<RecordModel>("expand.sender"),
      ), // assuming relation field is 'sender'
      created: DateTime.tryParse(record.getStringValue('created')),
      documents: List<String>.from(record.getListValue('documents')),
    );
  }

  // Get full link of a document (PocketBase file URL)
  static String getDocumentLink(String filename, String recordId) {
    String baseUrl =
        PBClient.instance.baseURL; // replace with your PocketBase URL
    return "$baseUrl/api/files/messages/$recordId/$filename";
  }

  // Get list of full links
  List<String> get documentLinks {
    return documents.map((doc) => getDocumentLink(doc, id)).toList();
  }
}
