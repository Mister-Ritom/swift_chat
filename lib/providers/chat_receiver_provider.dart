import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:swift_chat/models/user_model.dart';

class ChatReceiverProvider extends StateNotifier<UserModel?> {
  ChatReceiverProvider() : super(null);
  void updateReceiver(UserModel updated) {
    state = updated;
  }
}

// Provider
final receiverProvider =
    StateNotifierProvider<ChatReceiverProvider, UserModel?>(
      (ref) => ChatReceiverProvider(),
    );
