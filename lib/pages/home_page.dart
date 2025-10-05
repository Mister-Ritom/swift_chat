import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_profile_picture/flutter_profile_picture.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:swift_chat/core/pb_client.dart';
import 'package:swift_chat/models/user_model.dart';
import 'package:swift_chat/pages/chat_page.dart';
import 'package:swift_chat/providers/user_provider.dart';
import 'package:swift_chat/utils/presence_service.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  Future<ResultList<RecordModel>> getPublicUsers(int page) {
    final pb = PBClient.instance;
    return pb
        .collection("users")
        .getList(page: page, filter: 'publicAccount=true');
  }

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
      body: Padding(
        padding: const EdgeInsets.only(top: 12), //Some margin from the appbar
        child: FutureBuilder<ResultList<RecordModel>>(
          future: getPublicUsers(1),
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
            final items = snapshot.data!.items;
            return ListView.separated(
              separatorBuilder: (context, index) {
                return SizedBox(height: 8);
              },
              itemCount: items.length,
              itemBuilder: (context, index) {
                final user = UserModel.fromRecord(items[index]);
                return ListTile(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ChatPage(receiver: user),
                      ),
                    );
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
          },
        ),
      ),
    );
  }
}
