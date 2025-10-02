import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:swift_chat/pages/home_page.dart';
import 'package:swift_chat/pages/auth/login_page.dart';
import 'package:swift_chat/providers/user_provider.dart';

class App extends ConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userProvider);

    if (user != null) {
      return const HomePage(); // user logged in
    } else {
      return const LoginPage(); // not logged in
    }
  }
}
