import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:swift_chat/models/user_model.dart';

class MyProfilePage extends StatefulWidget {
  final UserModel user;
  const MyProfilePage({super.key, required this.user});

  @override
  State<MyProfilePage> createState() => _MyProfilePageState();
}

class _MyProfilePageState extends State<MyProfilePage> {
  @override
  Widget build(BuildContext context) {
    final user = widget.user;
    return Scaffold(
      appBar: AppBar(title: Text("My Profile")),
      body: Column(children: [
        
      ],
    ),
    );
  }
}
