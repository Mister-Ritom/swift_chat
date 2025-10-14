import 'package:flutter/foundation.dart';
import 'package:pocketbase/pocketbase.dart';

class PBClient {
  // private constructor
  PBClient._();

  static final PocketBase instance = PocketBase(
    kReleaseMode
        ? 'https://pocketbase-production-8263.up.railway.app'
        : kIsWeb
        ? 'http://127.0.0.1:8090' // web localhost
        : (defaultTargetPlatform == TargetPlatform.android
            ? 'http://10.0.2.2:8090' // Android emulator
            : 'http://127.0.0.1:8090'), // iOS, macOS, others
  );
}
