// screens/home_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:swift_chat/models/user_model.dart';
import 'package:swift_chat/pages/chat_page.dart';
import 'package:swift_chat/providers/user_provider.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Swift Chat"),
        leading: IconButton(
          onPressed: () => {ref.read(userProvider.notifier).logout()},
          icon: FaIcon(FontAwesomeIcons.doorOpen, color: Colors.black),
        ),
      ),
      body: ElevatedButton(
        onPressed:
            () => {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (_) => ChatPage(
                        receiver: UserModel(
                          id: "abcd1234xyz",
                          email: "john.doe@example.com",
                          emailVerified: true,
                          name: "John Doe",
                          avatar:
                              "avatar123.png", // PocketBase stores just the file name/id
                          username: "johndoe16",
                          created: DateTime.now().subtract(
                            const Duration(days: 10),
                          ),
                          updated: DateTime.now(),
                        ),
                      ),
                ),
              ),
            },
        child: Text("Chat"),
      ),
    );
  }
}
