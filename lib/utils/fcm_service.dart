import 'dart:convert';
import 'dart:developer';
import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;
import 'package:googleapis_auth/auth_io.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:swift_chat/core/pb_client.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

/// Background message handler
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  log('Handling a background message: ${message.messageId}');
  await flutterLocalNotificationsPlugin.show(
    0,
    message.notification?.title ?? 'New Notification',
    message.notification?.body ?? '',
    const NotificationDetails(
      android: AndroidNotificationDetails(
        'channel_id',
        'channel_name',
        importance: Importance.max,
        priority: Priority.high,
      ),
    ),
  );
}

class FCMService {
  /// Save FCM token to PocketBase
  static Future<void> saveFCMToken() async {
    final pb = PBClient.instance;
    final fcmToken = await FirebaseMessaging.instance.getToken();
    log("FCM Token: $fcmToken");

    if (fcmToken != null && pb.authStore.isValid) {
      final userRecord = pb.authStore.record!;
      await pb
          .collection('users')
          .update(userRecord.id, body: {'fcm_token': fcmToken});
    }
  }

  /// Setup listeners for foreground, background & on-click notifications
  static Future<void> setupFCMListeners() async {
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const initSettings = InitializationSettings(android: androidSettings);
    await flutterLocalNotificationsPlugin.initialize(initSettings);

    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      log("Foreground message received: ${message.notification?.title}");
      flutterLocalNotificationsPlugin.show(
        0,
        message.notification?.title ?? 'New Notification',
        message.notification?.body ?? '',
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'channel_id',
            'channel_name',
            importance: Importance.max,
            priority: Priority.high,
          ),
        ),
      );
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      log("Notification clicked: ${message.data}");
      // Navigate to specific chat or handle accordingly
    });
  }

  /// Load service account JSON from assets
  static Future<ServiceAccountCredentials> _loadServiceAccount() async {
    final jsonString = await rootBundle.loadString('assets/configs/notif.json');
    final jsonMap = json.decode(jsonString);
    return ServiceAccountCredentials.fromJson(jsonMap);
  }

  /// Get OAuth2 access token
  static Future<String> getAccessToken() async {
    final credentials = await _loadServiceAccount();
    final scopes = ['https://www.googleapis.com/auth/firebase.messaging'];
    final client = await clientViaServiceAccount(credentials, scopes);
    return client.credentials.accessToken.data;
  }

  /// Send push notification using FCM HTTP v1 API
  static Future<void> sendPushNotification({
    required String fcmToken,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    final accessToken = await getAccessToken();

    // Extract project ID from service account JSON
    final jsonString = await rootBundle.loadString('assets/configs/notif.json');
    final projectId = json.decode(jsonString)['project_id'];

    final url = Uri.parse(
      'https://fcm.googleapis.com/v1/projects/$projectId/messages:send',
    );

    final payload = {
      'message': {
        'token': fcmToken,
        'notification': {'title': title, 'body': body},
        'data': data ?? {},
      },
    };

    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(payload),
    );

    if (response.statusCode == 200) {
      log('Notification sent successfully!');
    } else {
      log('Error sending notification: ${response.body}');
    }
  }
}
