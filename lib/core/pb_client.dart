import 'dart:io';
import 'package:pocketbase/pocketbase.dart';

class PBClient {
  // private constructor
  PBClient._();

  // single instance
  static final PocketBase instance = PocketBase(
    Platform.isAndroid
        ? 'http://10.0.2.2:8090' // Android emulator localhost
        : 'http://127.0.0.1:8090', // iOS, macOS, others
  );
}
