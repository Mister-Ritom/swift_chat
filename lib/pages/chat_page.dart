import 'package:flutter/material.dart';
import 'package:swift_chat/models/user_model.dart';

class ChatPage extends StatefulWidget {
  final UserModel receiver;
  const ChatPage({super.key, required this.receiver});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  @override
  Widget build(BuildContext context) {
    final user = widget.receiver;
    return Scaffold(
      appBar: AppBar(title: Text('Chat with ${user.username}')),
      body: Stack(children: [
          
        ],
      ),
    );
  }
}
