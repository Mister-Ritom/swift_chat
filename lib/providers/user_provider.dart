import 'dart:convert';
import 'dart:developer';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:swift_chat/core/pb_client.dart';

class UserNotifier extends StateNotifier<RecordModel?> {
  UserNotifier()
    : super(
        PBClient.instance.authStore.isValid
            ? PBClient.instance.authStore.record
            : null,
      );

  final PocketBase _pb = PBClient.instance;
  final String _boxName = 'authBox';
  final String _authKey = 'authData';

  /// Save auth to Hive
  Future<void> _saveToHive() async {
    final box = Hive.box(name: _boxName);
    final data = {
      'token': _pb.authStore.token,
      'model': _pb.authStore.record?.toJson(),
    };
    box.put(_authKey, jsonEncode(data));
    log('Auth saved to Hive');

    // Debug: print contents
    await debugHive();
  }

  /// Delete auth from Hive
  Future<void> _deleteFromHive() async {
    final box = Hive.box(name: _boxName);
    box.delete(_authKey);
    log('Auth deleted from Hive');

    // Debug: print contents
    await debugHive();
  }

  /// Debug function to print Hive contents
  Future<void> debugHive() async {
    final box = Hive.box(name: _boxName);
    final authJson = box.get(_authKey);
    if (authJson != null) {
      final Map<String, dynamic> authMap = jsonDecode(authJson);
      log("Hive token: ${authMap['token']}");
      log("Hive user model: ${authMap['model']}");
    } else {
      log("Hive authBox is empty");
    }
  }

  /// Login
  Future<void> login(String email, String password) async {
    final authData = await _pb
        .collection('users')
        .authWithPassword(email, password);
    state = authData.record;
    await _saveToHive();
    log('Login success');
  }

  /// Register
  Future<void> register(String username, String email, String password) async {
    await _pb
        .collection('users')
        .create(
          body: {
            'username': username,
            'email': email,
            'password': password,
            'passwordConfirm': password,
          },
        );
    log('User registered');
    await login(email, password);
  }

  /// Logout
  Future<void> logout() async {
    _pb.authStore.clear();
    state = null;
    await _deleteFromHive();
    log('User logged out');
  }

  bool get isLoggedIn => state != null;
}

// Provider
final userProvider = StateNotifierProvider<UserNotifier, RecordModel?>(
  (ref) => UserNotifier(),
);
