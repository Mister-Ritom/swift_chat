import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_profile_picture/flutter_profile_picture.dart';
import 'package:swift_chat/models/user_model.dart';
import 'package:swift_chat/utils/mapping.dart';

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
    final size = MediaQuery.of(context).size;

    return Scaffold(
      appBar: AppBar(title: const Text("My Profile")),
      body: Column(
        children: [
          SizedBox(
            width: size.width,
            height: 250,
            child: Stack(
              alignment: Alignment.center,
              children: [
                _buildCoverImage(user.coverUrl, size.width, 250),

                // Centered profile + info row
                Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Profile Picture with border
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                      ),
                      child: ProfilePicture(
                        name: user.username,
                        radius: 50,
                        fontsize: 22,
                        img: user.avatarUrl,
                      ),
                    ),
                    const SizedBox(width: 16),

                    // Frosted Info Card
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                        child: Container(
                          width: size.width * 0.55,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          color: Colors.black.withValues(alpha: 0.4),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                user.name.isEmpty ? "No name" : user.name,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                "@${user.username}",
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 16,
                                ),
                              ),
                              if (user.created != null)
                                Text(
                                  "Joined ${timeAgo(user.created!, limit: false)}",
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 14,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCoverImage(String? img, double width, double height) {
    if (img == null) {
      return Container(
        width: width,
        height: height,
        color: Colors.grey.shade700,
        child: const Icon(Icons.image, size: 64, color: Colors.white70),
      );
    }
    return Image.network(img, width: width, height: height, fit: BoxFit.cover);
  }
}
