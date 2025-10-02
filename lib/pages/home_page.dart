// screens/home_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:swift_chat/providers/user_provider.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(Object context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Swift Chat"),
        leading: IconButton(
          onPressed: () => {ref.read(userProvider.notifier).logout()},
          icon: FaIcon(FontAwesomeIcons.doorOpen, color: Colors.black),
        ),
      ),
      body: Center(child: Text("Welcome Home!")),
    );
  }
}
