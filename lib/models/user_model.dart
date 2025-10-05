import 'package:pocketbase/pocketbase.dart';
import 'package:swift_chat/core/pb_client.dart';

class UserModel {
  final String id;
  final String email;
  final bool emailVerified;
  final String name;
  final String? avatar; // Only file id
  final String username;
  final bool publicAccount;
  final DateTime? created;
  final DateTime? updated;
  final DateTime? lastSeen;

  UserModel({
    required this.id,
    required this.email,
    required this.emailVerified,
    required this.name,
    required this.avatar,
    required this.username,
    required this.publicAccount,
    this.created,
    this.updated,
    this.lastSeen,
  });

  factory UserModel.fromRecord(RecordModel record) {
    return UserModel(
      id: record.id,
      email: record.getStringValue('email'),
      emailVerified: record.getBoolValue('verified'),
      name: record.getStringValue('name'),
      avatar: record.getStringValue('avatar'),
      username: record.getStringValue('username'),
      publicAccount: record.getBoolValue('publicAccount'),
      created: _parseDate(record.getStringValue('created')),
      updated: _parseDate(record.getStringValue('updated')),
      lastSeen: _parseDate(record.getStringValue('lastSeen')),
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
      'publicAccount': publicAccount,
      'created': created?.toIso8601String(),
      'updated': updated?.toIso8601String(),
      'lastSeen': lastSeen?.toIso8601String(),
    };
  }

  UserModel copyWith({
    String? id,
    String? email,
    bool? emailVerified,
    String? name,
    String? avatar,
    String? username,
    bool? publicAccount,
    DateTime? created,
    DateTime? updated,
    DateTime? lastSeen,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      emailVerified: emailVerified ?? this.emailVerified,
      name: name ?? this.name,
      avatar: avatar ?? this.avatar,
      username: username ?? this.username,
      publicAccount: publicAccount ?? this.publicAccount,
      created: created ?? this.created,
      updated: updated ?? this.updated,
      lastSeen: lastSeen ?? this.lastSeen,
    );
  }

  /// Returns the full avatar image URL or null if not set
  String? get avatarUrl {
    if (avatar == null || avatar!.isEmpty) return null;
    final baseUrl = PBClient.instance.baseURL; // <- use from PBClient
    return "$baseUrl/api/files/users/$id/$avatar";
  }

  static DateTime? _parseDate(String? value) {
    if (value == null || value.isEmpty) return null;
    return DateTime.tryParse(value);
  }
}
