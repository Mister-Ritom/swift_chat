import 'dart:convert';
import 'dart:developer';

import 'package:hive/hive.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:swift_chat/core/pb_client.dart';

void hiveAuthCheck() {
  final pb = PBClient.instance;
  final authBox = Hive.box(name: 'authBox');
  // Check if auth exists in Hive
  final authJson = authBox.get('authData');
  if (authJson != null) {
    log('Auth data found');
    try {
      final Map<String, dynamic> authMap = jsonDecode(authJson);
      final token = authMap['token'];
      final modelMap = Map<String, dynamic>.from(authMap['model']);

      if (token != null) {
        pb.authStore.save(token, RecordModel.fromJson(modelMap));
      }
    } catch (e) {
      // If parsing fails, clear Hive
      authBox.clear();
    }
  }
}
