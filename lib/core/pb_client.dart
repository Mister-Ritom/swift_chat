import 'package:pocketbase/pocketbase.dart';

class PBClient {
  // private constructor
  PBClient._();

  // single instance
  static final PocketBase instance = PocketBase('http://127.0.0.1:8090');
}
