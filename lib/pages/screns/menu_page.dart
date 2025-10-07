import 'package:flutter/material.dart';
import 'package:flutter_profile_picture/flutter_profile_picture.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:swift_chat/app.dart';
import 'package:swift_chat/models/user_model.dart';
import 'package:swift_chat/pages/profile/profile_page.dart';
import 'package:swift_chat/providers/user_provider.dart';

class MenuPage extends ConsumerWidget {
  const MenuPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userRef = ref.watch(userProvider);
    if (userRef == null) return App(); //When signing out
    final user = UserModel.fromRecord(userRef);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => MyProfilePage(user: user)),
                );
              },
              child: Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors:
                        isDark
                            ? [
                              Colors.blueGrey.shade800,
                              Colors.blueGrey.shade700,
                            ]
                            : [Colors.blue.shade600, Colors.blue.shade400],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color:
                          isDark
                              ? Colors.black.withValues(alpha: 0.3)
                              : Colors.blue.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    ProfilePicture(
                      name: user.username,
                      radius: 32,
                      fontsize: 26,
                      img: user.avatarUrl,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user.username,
                            style: theme.textTheme.titleLarge?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            user.email,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.arrow_forward_ios,
                      size: 18,
                      color: Colors.white70,
                    ),
                  ],
                ),
              ),
            ),

            // Divider
            Divider(color: theme.dividerColor.withValues(alpha: 0.3)),

            // Menu items
            Expanded(
              child: ListView(
                children: [
                  const SizedBox(height: 8),
                  _buildMenuTile(
                    icon: FontAwesomeIcons.userPen,
                    label: "Edit Profile",
                    onTap: () {
                      // navigate to edit profile page
                    },
                  ),
                  _buildMenuTile(
                    icon: FontAwesomeIcons.bell,
                    label: "Notifications",
                    onTap: () {
                      // open notifications settings
                    },
                  ),
                  _buildMenuTile(
                    icon: FontAwesomeIcons.palette,
                    label: "Appearance",
                    onTap: () {
                      // theme selection / dark-light mode
                    },
                  ),
                  _buildMenuTile(
                    icon: FontAwesomeIcons.shieldHalved,
                    label: "Privacy & Security",
                    onTap: () {
                      // open privacy settings
                    },
                  ),
                  _buildMenuTile(
                    icon: FontAwesomeIcons.lock,
                    label: "Blocked Users",
                    onTap: () {
                      // show blocked users list
                    },
                  ),
                  _buildMenuTile(
                    icon: FontAwesomeIcons.gear,
                    label: "App Settings",
                    onTap: () {
                      // open general settings
                    },
                  ),
                  const Divider(),
                  _buildMenuTile(
                    icon: FontAwesomeIcons.circleQuestion,
                    label: "Help & Support",
                    onTap: () {
                      // open support / FAQ
                    },
                  ),
                  _buildMenuTile(
                    icon: FontAwesomeIcons.commentDots,
                    label: "Send Feedback",
                    onTap: () {
                      // feedback form or mailto link
                    },
                  ),
                  _buildMenuTile(
                    icon: FontAwesomeIcons.fileContract,
                    label: "Terms of Service",
                    onTap: () {
                      // open terms page
                    },
                  ),
                  _buildMenuTile(
                    icon: FontAwesomeIcons.userShield,
                    label: "Privacy Policy",
                    onTap: () {
                      // open privacy policy
                    },
                  ),
                  _buildMenuTile(
                    icon: FontAwesomeIcons.codeBranch,
                    label: "Version Info",
                    onTap: () {
                      // show app version, build info
                    },
                  ),
                  const Divider(),
                  _buildMenuTile(
                    icon: FontAwesomeIcons.arrowRightFromBracket,
                    label: "Sign Out",
                    color: Colors.redAccent,
                    onTap: () {
                      ref.read(userProvider.notifier).logout();
                    },
                  ),
                  const SizedBox(
                    height: 128,
                  ), //Without it the nav dock would be on top of sign out
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuTile({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? color,
  }) {
    return ListTile(
      leading: FaIcon(icon, color: color ?? Colors.blueAccent),
      title: Text(
        label,
        style: TextStyle(fontWeight: FontWeight.w500, color: color),
      ),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }
}
