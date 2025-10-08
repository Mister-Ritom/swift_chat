import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:pocketbase/pocketbase.dart';

class PBClient {
  // private constructor
  PBClient._();

  // single instance
  static final PocketBase instance = PocketBase(
    kReleaseMode
        ? 'https://pocketbase-production-8263.up.railway.app'
        : Platform.isAndroid
        ? 'http://10.0.2.2:8090' // Android emulator localhost
        : 'http://127.0.0.1:8090', // iOS, macOS, others
  );
}
