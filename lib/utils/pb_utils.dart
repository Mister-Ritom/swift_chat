import 'dart:async';
import 'dart:convert';
import 'dart:developer';

import 'package:hive/hive.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:swift_chat/core/pb_client.dart';
import 'package:swift_chat/utils/presence_service.dart';

final _pb = PBClient.instance;
void hiveAuthCheck() {
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
        _pb.authStore.save(token, RecordModel.fromJson(modelMap));

        // ✅ Start presence service immediately after restoring auth
        PresenceService().start();
      }
    } catch (e) {
      // If parsing fails, clear Hive
      authBox.clear();
    }
  }
}

Stream<RecordSubscriptionEvent> streamCollection(
  String collection, [
  String topic = "*",
  String? filter,
]) {
  late StreamController<RecordSubscriptionEvent> controller;

  controller = StreamController<RecordSubscriptionEvent>.broadcast(
    onListen: () async {
      try {
        await _pb.collection(collection).subscribe(topic, (e) {
          if (!controller.isClosed) {
            controller.add(e);
          }
        }, filter: filter);
        log("Subscribed to collection '$collection' with topic '$topic'");
      } catch (e, stackTrace) {
        log(
          "Failed to subscribe to collection '$collection' with topic '$topic'",
          error: e,
          stackTrace: stackTrace,
        );
        if (!controller.isClosed) controller.addError(e, stackTrace);
      }
    },
    onCancel: () async {
      try {
        await _pb.collection(collection).unsubscribe(topic);
        log("Unsubscribed from collection '$collection' with topic '$topic'");
      } catch (e, stackTrace) {
        log(
          "Failed to unsubscribe from collection '$collection' with topic '$topic'",
          error: e,
          stackTrace: stackTrace,
        );
      }
    },
  );

  return controller.stream;
}
