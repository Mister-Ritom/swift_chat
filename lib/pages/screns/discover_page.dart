import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_profile_picture/flutter_profile_picture.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:swift_chat/core/pb_client.dart';
import 'package:swift_chat/models/user_model.dart';
import 'package:swift_chat/pages/chat/chat_page.dart';
import 'package:swift_chat/providers/chat_receiver_provider.dart';
import 'package:swift_chat/utils/presence_service.dart';

class DiscoverPage extends ConsumerStatefulWidget {
  final bool isMobile;
  const DiscoverPage({super.key, this.isMobile = true});

  @override
  ConsumerState<DiscoverPage> createState() => _DiscoverPageState();
}

class _DiscoverPageState extends ConsumerState<DiscoverPage> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;
  late Future<List<UserModel>> _futureUsers;
  final pb = PBClient.instance;

  @override
  void initState() {
    super.initState();
    _futureUsers = getPublicUsers(); // initial fetch
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged() {
    // Debounce to prevent excessive network calls while typing
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      setState(() {
        _futureUsers = getPublicUsers(query: _searchController.text.trim());
      });
    });
  }

  Future<List<UserModel>> getPublicUsers({String query = ''}) async {
    final currentId = pb.authStore.record!.id;

    // Build the filter dynamically
    String filter = 'publicAccount=true && id!="$currentId"';
    if (query.isNotEmpty) {
      // Case-insensitive partial match on username or email
      final escaped = query.replaceAll('"', '\\"');
      filter += ' && (username?~"$escaped")';
    }

    final recordList = await pb.collection("users").getList(filter: filter);

    if (recordList.items.isEmpty) return [];

    return recordList.items.map(UserModel.fromRecord).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: null,
        title: TextField(
          controller: _searchController,
          decoration: const InputDecoration(
            hintText: 'Search users...',
            prefixIcon: Icon(Icons.search),
            border: InputBorder.none,
          ),
        ),
      ),
      body: FutureBuilder<List<UserModel>>(
        future: _futureUsers,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final users = snapshot.data ?? [];
          if (users.isEmpty) {
            return const Center(child: Text('No users found.'));
          }

          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];
              return ListTile(
                onTap: () {
                  {
                    if (!widget.isMobile) {
                      ref.read(receiverProvider.notifier).updateReceiver(user);
                    } else {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ChatPage(receiver: user),
                        ),
                      );
                    }
                  }
                },
                leading: Stack(
                  children: [
                    ProfilePicture(
                      name: user.username,
                      radius: 32,
                      fontsize: 24,
                      img: user.avatarUrl,
                    ),
                    Positioned(
                      top: 0,
                      right: 0,
                      child: userOnlineWidget(
                        userId: user.id,
                        onlineWidget: Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: Colors.lightGreen,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                        ),
                        offlineWidget: (_) => const SizedBox.shrink(),
                      ),
                    ),
                  ],
                ),
                title: Text(user.username),
                subtitle:
                    widget.isMobile
                        ? user.bio.isNotEmpty
                            ? Text(user.bio)
                            : null
                        : null,
              );
            },
          );
        },
      ),
    );
  }
}
