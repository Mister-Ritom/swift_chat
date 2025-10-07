import 'package:flutter/material.dart';
import 'package:flutter_profile_picture/flutter_profile_picture.dart';
import 'package:swift_chat/core/pb_client.dart';
import 'package:swift_chat/models/user_model.dart';
import 'package:swift_chat/pages/chat/chat_page.dart';
import 'package:swift_chat/utils/presence_service.dart';

class DiscoverPage extends StatelessWidget {
  const DiscoverPage({super.key});

  Future<List<UserModel>> getPublicUsers() async {
    final pb = PBClient.instance;
    final recordList = await pb
        .collection("users")
        .getList(filter: 'publicAccount=true');
    if (recordList.items.isEmpty) return [];
    return recordList.items
        .where((e) {
          return e.id != pb.authStore.record!.id;
        })
        .map((e) {
          return UserModel.fromRecord(e);
        })
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder(
        future: getPublicUsers(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            final users = snapshot.data!;
            return ListView.separated(
              separatorBuilder: (context, index) => SizedBox(height: 12),
              itemCount: users.length,
              itemBuilder: (context, index) {
                final user = users[index];
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
          }
          return SizedBox();
        },
      ),
    );
  }
}
