import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:swift_chat/core/pb_client.dart';
import 'package:swift_chat/utils/pb_utils.dart';

class PresenceService with WidgetsBindingObserver {
  static final PresenceService _instance = PresenceService._internal();
  factory PresenceService() => _instance;
  PresenceService._internal();

  final PocketBase pb = PBClient.instance;

  Timer? _timer;
  DateTime? _lastSent;
  bool _running = false;
  StreamSubscription? _connSub;

  /// Configurable intervals
  final Duration heartbeatInterval = const Duration(seconds: 30);
  final Duration onlineThreshold = const Duration(seconds: 60);

  String? get userId => pb.authStore.record?.id;

  /// Start presence tracking (call after login)
  void start() {
    if (_running || userId == null) return;
    _running = true;

    WidgetsBinding.instance.addObserver(this);

    _sendHeartbeat(); // immediate
    _timer = Timer.periodic(heartbeatInterval, (_) => _sendHeartbeat());

    _connSub = Connectivity().onConnectivityChanged.listen((result) {
      if (result.contains(ConnectivityResult.none)) {
        _pause();
      } else {
        _resume();
      }
    });
  }

  /// Stop presence tracking (call on logout)
  void stop() {
    if (!_running) return;
    _running = false;

    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    _connSub?.cancel();
    _setOffline(); // final update
  }

  /// App lifecycle handling
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_running) return;
    if (state == AppLifecycleState.resumed) {
      _resume();
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached) {
      _pause();
    }
  }

  /// Pause updates (background / offline)
  void _pause() {
    _timer?.cancel();
  }

  /// Resume updates (foreground / online)
  void _resume() {
    _timer?.cancel();
    _sendHeartbeat();
    _timer = Timer.periodic(heartbeatInterval, (_) => _sendHeartbeat());
  }

  Future<void> _sendHeartbeat() async {
    final now = DateTime.now().toUtc();

    if (_lastSent != null &&
        now.difference(_lastSent!) < heartbeatInterval ~/ 2) {
      return; // avoid spamming
    }
    _lastSent = now;

    try {
      await pb
          .collection('users')
          .update(userId!, body: {'lastSeen': now.toIso8601String()});
    } catch (_) {
      // ignore errors (best-effort)
    }
  }

  Future<void> _setOffline() async {
    try {
      await pb
          .collection('users')
          .update(
            userId!,
            body: {'lastSeen': DateTime.now().toUtc().toIso8601String()},
          );
    } catch (_) {}
  }
}

bool checkuserOnline(
  String lastSeenIso, {
  Duration threshold = const Duration(seconds: 60),
}) {
  if (lastSeenIso.isEmpty) return false;
  try {
    final lastSeen = DateTime.parse(lastSeenIso).toUtc();
    return DateTime.now().toUtc().difference(lastSeen) < threshold;
  } catch (_) {
    return false;
  }
}

Widget userOnlineWidget({
  required String userId,
  required Widget onlineWidget,
  required Widget Function(String lastSeen) offlineWidget,
}) {
  return StreamBuilder<RecordSubscriptionEvent>(
    stream: streamCollection("users", userId),
    builder: (context, snapshot) {
      String lastSeen = "";
      if (snapshot.hasData) {
        final event = snapshot.data!;
        lastSeen = event.record?.getStringValue("lastSeen") ?? '';
        if (checkuserOnline(lastSeen)) {
          return onlineWidget;
        }
      }
      return offlineWidget(lastSeen);
    },
  );
}
