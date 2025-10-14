import 'dart:io';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_profile_picture/flutter_profile_picture.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:swift_chat/core/pb_client.dart';
import 'package:swift_chat/models/user_model.dart';
import 'package:swift_chat/utils/file_picker_helper.dart';
import 'package:swift_chat/utils/mapping.dart';
import 'package:swift_chat/providers/user_provider.dart';

class MyProfilePage extends ConsumerStatefulWidget {
  final UserModel user;
  const MyProfilePage({super.key, required this.user});

  @override
  ConsumerState<MyProfilePage> createState() => _MyProfilePageState();
}

class _MyProfilePageState extends ConsumerState<MyProfilePage> {
  bool isEditing = false;
  late TextEditingController nameCtrl;
  late TextEditingController bioCtrl;
  PickedFileData? newAvatar;
  PickedFileData? newCover;
  bool isSaving = false;
  bool isPublic = false;

  final PocketBase _pb = PBClient.instance;

  @override
  void initState() {
    super.initState();
    nameCtrl = TextEditingController(text: widget.user.name);
    bioCtrl = TextEditingController(text: widget.user.bio);
    isPublic = widget.user.publicAccount;
  }

  @override
  void dispose() {
    nameCtrl.dispose();
    bioCtrl.dispose();
    super.dispose();
  }

  Future<void> saveChanges() async {
    if (isSaving) return;
    setState(() => isSaving = true);

    try {
      final userId = _pb.authStore.record!.id;
      final body = {
        'name': nameCtrl.text.trim(),
        'bio': bioCtrl.text.trim(),
        'publicAccount': isPublic,
      };

      final files = <http.MultipartFile>[];
      if (newAvatar != null) {
        if (kIsWeb && newAvatar!.bytes != null) {
          files.add(
            http.MultipartFile.fromBytes(
              'avatar',
              newAvatar!.bytes!,
              filename: 'avatar_${DateTime.now().millisecondsSinceEpoch}.jpg',
            ),
          );
        } else if (!kIsWeb && newAvatar!.path != null) {
          files.add(
            await http.MultipartFile.fromPath(
              'avatar',
              newAvatar!.path!,
              filename: 'avatar_${DateTime.now().millisecondsSinceEpoch}.jpg',
            ),
          );
        }
      }

      if (newCover != null) {
        if (kIsWeb && newCover!.bytes != null) {
          files.add(
            http.MultipartFile.fromBytes(
              'cover',
              newCover!.bytes!,
              filename: 'cover_${DateTime.now().millisecondsSinceEpoch}.jpg',
            ),
          );
        } else if (!kIsWeb && newCover!.path != null) {
          files.add(
            await http.MultipartFile.fromPath(
              'cover',
              newCover!.path!,
              filename: 'cover_${DateTime.now().millisecondsSinceEpoch}.jpg',
            ),
          );
        }
      }

      final updated = await _pb
          .collection('users')
          .update(userId, body: body, files: files);
      ref.read(userProvider.notifier).updateUser(updated);

      if (!mounted) return;
      setState(() => isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully!')),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      setState(() => isSaving = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to update profile: $e')));
    }
  }

  Future<void> changePassword() async {
    final newPasswordCtrl = TextEditingController();
    final confirmPasswordCtrl = TextEditingController();
    final oldPasswordCtrl = TextEditingController();

    await showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text("Change Password"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: oldPasswordCtrl,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: "Current Password",
                  ),
                ),
                TextField(
                  controller: newPasswordCtrl,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: "New Password"),
                ),
                TextField(
                  controller: confirmPasswordCtrl,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: "Confirm Password",
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  "Cancel",
                  style: Theme.of(
                    context,
                  ).textTheme.labelMedium?.copyWith(color: Colors.grey),
                ),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (newPasswordCtrl.text != confirmPasswordCtrl.text ||
                      newPasswordCtrl.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Passwords do not match or are empty"),
                      ),
                    );
                    return;
                  }
                  try {
                    await _pb
                        .collection('users')
                        .update(
                          _pb.authStore.record!.id,
                          body: {
                            'oldPassword': oldPasswordCtrl.text,
                            'password': newPasswordCtrl.text,
                            'passwordConfirm': confirmPasswordCtrl.text,
                          },
                        );
                    if (mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Password updated successfully"),
                        ),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text("Failed to update password: $e"),
                        ),
                      );
                    }
                  }
                },
                child: Text(
                  "Save",
                  style: Theme.of(
                    context,
                  ).textTheme.labelMedium?.copyWith(color: Colors.white),
                ),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.user;
    final size = MediaQuery.of(context).size;

    return Scaffold(
      appBar: AppBar(
        title: const Text("My Profile"),
        actions: [
          IconButton(
            icon: Icon(isEditing ? Icons.close : Icons.edit),
            onPressed: () => setState(() => isEditing = !isEditing),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(
              width: size.width,
              height: 250,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  buildCoverImage(
                    newCover, // PickedFileData? from file picker
                    user.coverUrl, // fallback network URL
                    size.width,
                    250,
                  ),
                  Positioned(
                    right: 16,
                    top: 16,
                    child: ifEditingButton(isCover: true),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Stack(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 3),
                            ),
                            child:
                                newAvatar != null
                                    ? ClipOval(
                                      child: buildCoverImage(
                                        newAvatar,
                                        null,
                                        100,
                                        100,
                                      ),
                                    )
                                    : ProfilePicture(
                                      name: user.username,
                                      radius: 50,
                                      fontsize: 22,
                                      img: user.avatarUrl,
                                    ),
                          ),
                          if (isEditing)
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: InkWell(
                                onTap: () async {
                                  final files =
                                      await FilePickerHelper.pickImages();
                                  if (files.isNotEmpty) {
                                    setState(() {
                                      newAvatar = files[0];
                                    });
                                  }
                                },
                                child: const CircleAvatar(
                                  radius: 16,
                                  backgroundColor: Colors.black54,
                                  child: Icon(
                                    Icons.camera_alt,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(width: 16),
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
                                isEditing
                                    ? TextField(
                                      controller: nameCtrl,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                      ),
                                      decoration: InputDecoration(
                                        hintText: "Name",
                                        hintStyle: const TextStyle(
                                          color: Colors.white70,
                                        ),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          borderSide: const BorderSide(
                                            color: Colors.white70,
                                            width: 1.5,
                                          ),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          borderSide: const BorderSide(
                                            color: Colors.white70,
                                            width: 1.5,
                                          ),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          borderSide: const BorderSide(
                                            color: Colors.blueAccent,
                                            width: 2,
                                          ),
                                        ),
                                        isDense: true,
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 6,
                                            ),
                                      ),
                                    )
                                    : Text(
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
                                    fontSize: 14,
                                  ),
                                ),
                                if (user.created != null)
                                  Text(
                                    "Joined ${timeAgo(user.created!, limit: false)}",
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 12,
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
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Bio",
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child:
                        isEditing
                            ? TextField(
                              controller: bioCtrl,
                              maxLines: null,
                              decoration: InputDecoration(
                                hintText: "Write something about yourself...",
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            )
                            : Text(
                              user.bio.isNotEmpty == true
                                  ? user.bio
                                  : "No bio added.",
                              style: const TextStyle(fontSize: 16),
                            ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "Email",
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user.email,
                    style: const TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text("Public Account"),
                    value: isPublic,
                    onChanged:
                        isEditing
                            ? (val) => setState(() => isPublic = val)
                            : null,
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    leading: const Icon(Icons.lock),
                    title: const Text("Change Password"),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: changePassword,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            if (isEditing)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: ElevatedButton.icon(
                  onPressed: saveChanges,
                  icon: const Icon(Icons.save),
                  label: const Text("Save Changes"),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                    backgroundColor: Colors.blueAccent,
                  ),
                ),
              ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget ifEditingButton({required bool isCover}) {
    if (!isEditing) return const SizedBox.shrink();
    return InkWell(
      onTap: () async {
        if (!isCover) return;
        final files = await FilePickerHelper.pickImages();
        if (files.isNotEmpty) {
          setState(() {
            newCover = files[0];
          });
        }
      },
      child: const CircleAvatar(
        radius: 20,
        backgroundColor: Colors.black54,
        child: Icon(Icons.camera_alt, color: Colors.white, size: 20),
      ),
    );
  }

  Widget buildCoverImage(
    PickedFileData? file,
    String? networkUrl,
    double width,
    double height,
  ) {
    // 1. No image: show placeholder
    if ((file == null || (file.path == null && file.bytes == null)) &&
        (networkUrl == null || networkUrl.isEmpty)) {
      return Container(
        width: width,
        height: height,
        color: Colors.grey.shade700,
        child: const Icon(Icons.image, size: 64, color: Colors.white70),
      );
    }

    // 2. File selected
    if (file != null) {
      if (kIsWeb && file.bytes != null) {
        // Web: use Image.memory
        return Image.memory(
          file.bytes!,
          width: width,
          height: height,
          fit: BoxFit.cover,
        );
      } else if (!kIsWeb &&
          file.path != null &&
          File(file.path!).existsSync()) {
        // Mobile: use Image.file
        return Image.file(
          File(file.path!),
          width: width,
          height: height,
          fit: BoxFit.cover,
        );
      }
    }

    // 3. Fallback: network image
    return Image.network(
      networkUrl!,
      width: width,
      height: height,
      fit: BoxFit.cover,
    );
  }
}
