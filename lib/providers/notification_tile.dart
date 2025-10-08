import 'package:flutter/material.dart';
import 'package:flutter_profile_picture/flutter_profile_picture.dart';
import 'package:swift_chat/utils/mapping.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'package:swift_chat/models/notification_model.dart';
import 'package:swift_chat/models/user_model.dart';
import 'package:swift_chat/core/pb_client.dart';

class NotificationTile extends StatefulWidget {
  final NotificationModel notification;

  const NotificationTile({super.key, required this.notification});

  @override
  State<NotificationTile> createState() => _NotificationTileState();
}

class _NotificationTileState extends State<NotificationTile> {
  bool _isRead = false;

  @override
  void initState() {
    super.initState();
    _isRead = widget.notification.isRead;
  }

  void _markAsRead() async {
    if (!_isRead) {
      setState(() => _isRead = true);

      try {
        final pb = PBClient.instance;
        await pb
            .collection('notifications')
            .update(widget.notification.id, body: {'isRead': true});
      } catch (e) {
        debugPrint("Failed to mark notification as read: $e");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final sender = UserModel.fromRecord(widget.notification.sender);

    return VisibilityDetector(
      key: Key(widget.notification.id),
      onVisibilityChanged: (info) {
        if (info.visibleFraction > 0.5) {
          _markAsRead();
        }
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color:
              _isRead ? Theme.of(context).scaffoldBackgroundColor : Colors.grey,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 2,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ProfilePicture(
              name: sender.username,
              radius: 28,
              fontsize: 24,
              img: sender.avatarUrl,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    sender.username,
                    style: TextStyle(
                      fontWeight: _isRead ? FontWeight.normal : FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.notification.text.isEmpty
                        ? "Sent you a message"
                        : widget.notification.text,
                    style: const TextStyle(fontSize: 14),
                  ),
                  if (widget.notification.files > 0)
                    Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Text(
                        "${widget.notification.files} file${widget.notification.files > 1 ? 's' : ''} attached",
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  if (widget.notification.created != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Text(
                        timeAgo(widget.notification.created!),
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
