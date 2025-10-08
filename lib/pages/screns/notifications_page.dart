import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:swift_chat/core/pb_client.dart';
import 'package:swift_chat/models/notification_model.dart';
import 'package:swift_chat/providers/notification_tile.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  Future<ResultList<RecordModel>> getChatsForUser(int page) async {
    final pb = PBClient.instance;
    final currentUserId = pb.authStore.record!.id;
    final list = await pb
        .collection('notifications')
        .getList(filter: 'receiver="$currentUserId"', expand: "sender");
    return list;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: null,
        title: Text("Notifications"),
      ),
      body: FutureBuilder(
        future: getChatsForUser(1),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            log(
              "Something went wrong trying to get Notifications",
              error: snapshot.error,
              stackTrace: snapshot.stackTrace,
            );
            return Text("Something went wrong");
          }
          if (!snapshot.hasData) {
            log("nop data");
            return SizedBox.shrink();
          }
          final items = snapshot.data!.items;
          log("Reuttng");
          return ListView.separated(
            itemBuilder: (context, index) {
              final notification = NotificationModel.fromRecord(items[index]);
              return NotificationTile(notification: notification);
            },
            separatorBuilder: (context, index) {
              return Divider();
            },
            itemCount: items.length,
          );
        },
      ),
    );
  }
}
