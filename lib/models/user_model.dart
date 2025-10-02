import 'package:pocketbase/pocketbase.dart';
import 'package:swift_chat/core/pb_client.dart';

class UserModel {
  final String id;
  final String email;
  final bool emailVerified;
  final String name;
  final String? avatar; //Only file id
  final String? username;
  final DateTime created;
  final DateTime updated;

  UserModel({
    required this.id,
    required this.email,
    required this.emailVerified,
    required this.name,
    required this.avatar,
    required this.username,
    required this.created,
    required this.updated,
  });

  factory UserModel.fromRecord(RecordModel record) {
    return UserModel(
      id: record.id,
      email: record.getStringValue('email'),
      emailVerified: record.getBoolValue('verified'),
      name: record.getStringValue('name'),
      avatar: record.getStringValue('avatar'),
      username: record.data['username'], // custom field
      created: DateTime.parse(record.created),
      updated: DateTime.parse(record.updated),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'verified': emailVerified,
      'name': name,
      'avatar': avatar,
      'username': username,
      'created': created.toIso8601String(),
      'updated': updated.toIso8601String(),
    };
  }

  UserModel copyWith({
    String? id,
    String? email,
    bool? emailVerified,
    String? name,
    String? avatar,
    String? username,
    DateTime? created,
    DateTime? updated,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      emailVerified: emailVerified ?? this.emailVerified,
      name: name ?? this.name,
      avatar: avatar ?? this.avatar,
      username: username ?? this.username,
      created: created ?? this.created,
      updated: updated ?? this.updated,
    );
  }

  /// Returns the full avatar image URL or null if not set
  String? get avatarUrl {
    if (avatar == null || avatar!.isEmpty) return null;
    final baseUrl = PBClient.instance.baseUrl; // <- use from PBClient
    return "$baseUrl/api/files/users/$id/$avatar";
  }
}
