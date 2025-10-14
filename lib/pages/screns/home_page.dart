import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_profile_picture/flutter_profile_picture.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:swift_chat/core/pb_client.dart';
import 'package:swift_chat/models/user_model.dart';
import 'package:swift_chat/pages/chat/chat_page.dart';
import 'package:swift_chat/providers/chat_receiver_provider.dart';
import 'package:swift_chat/utils/presence_service.dart';

class HomePage extends ConsumerWidget {
  final bool isMobile;
  const HomePage({super.key, this.isMobile = true});

  Future<ResultList<RecordModel>> getChatsForUser(int page) {
    final pb = PBClient.instance;
    final currentUserId = pb.authStore.record!.id;
    return pb
        .collection('chats')
        .getList(page: page, filter: 'members~"$currentUserId"');
  }

  Future<List<UserModel>> getChatMembers(List<RecordModel> chatItems) async {
    final pb = PBClient.instance;
    final currentUserId = pb.authStore.record!.id;
    final Set<String> otherUserIds = {};

    // Collect all unique other user IDs
    for (var chat in chatItems) {
      final members = chat.getStringValue('members').split(',');
      if (members.isNotEmpty) {
        final otherUserId = members.firstWhere(
          (id) => id != currentUserId,
          orElse: () => "",
        );
        otherUserIds.add(otherUserId);
      }
    }

    // Fetch all users in parallel
    final futures = otherUserIds.map((id) async {
      try {
        final record = await pb.collection('users').getOne(id);
        return UserModel.fromRecord(record);
      } catch (e, s) {
        log('Error fetching user $id', error: e, stackTrace: s);
        return null;
      }
    });

    // Wait for all futures to complete and remove nulls
    final users = (await Future.wait(futures)).whereType<UserModel>().toList();

    return users;
  }

  @override
  Widget build(BuildContext homeContext, WidgetRef ref) {
    return Scaffold(
      appBar:
          isMobile
              ? AppBar(
                automaticallyImplyLeading: false,
                leading: null,
                title: Text(
                  "Swift Chat",
                  style: GoogleFonts.pacifico(letterSpacing: 5, fontSize: 24),
                ),
                toolbarHeight: 96,
              )
              : null,
      body: Padding(
        padding: EdgeInsets.only(
          top: isMobile ? 12 : 0,
        ), //Some margin from the appbar
        child: FutureBuilder<ResultList<RecordModel>>(
          future: getChatsForUser(1),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              log(
                "Error trying to get public users",
                error: snapshot.error,
                stackTrace: snapshot.stackTrace,
              );
            }
            if (!snapshot.hasData) return SizedBox.shrink();
            final records = snapshot.data!.items;
            return FutureBuilder<List<UserModel>>(
              future: getChatMembers(records),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  final items = snapshot.data!;
                  return ListView.separated(
                    separatorBuilder: (context, index) {
                      return SizedBox(height: 8);
                    },
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final user = items[index];
                      return ListTile(
                        onTap: () {
                          if (!isMobile) {
                            ref
                                .read(receiverProvider.notifier)
                                .updateReceiver(user);
                          } else {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ChatPage(receiver: user),
                              ),
                            );
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
                              top: 0, // position at the bottom-right
                              right: 0,
                              child: userOnlineWidget(
                                userId: user.id,
                                onlineWidget: Container(
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    color: Colors.lightGreen,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color:
                                          Colors
                                              .white, // adds a small border around the dot
                                      width: 2,
                                    ),
                                  ),
                                ),
                                offlineWidget: (_) => SizedBox.shrink(),
                              ),
                            ),
                          ],
                        ),

                        title: Text(user.username),
                      );
                    },
                  );
                }
                return SizedBox.shrink();
              },
            );
          },
        ),
      ),
    );
  }
}
