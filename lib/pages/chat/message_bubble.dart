import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:swift_chat/models/message_model.dart';
import 'package:swift_chat/pages/chat/files_modal.dart';
import 'package:swift_chat/utils/mapping.dart';

class MessageBubble extends StatelessWidget {
  final MessageModel msg;
  final bool isMe;
  const MessageBubble({super.key, required this.msg, required this.isMe});

  @override
  Widget build(BuildContext context) {
    const maxFilesToShow = 4;
    final totalFiles = msg.documentLinks.length;
    final filesToShow = msg.documentLinks.take(maxFilesToShow).toList();
    final remainingFiles = totalFiles - maxFilesToShow;

    List<Widget> fileWidgets = [];

    for (int i = 0; i < filesToShow.length; i++) {
      final url = filesToShow[i];

      Widget thumb = buildFileThumbnail(url, 120, true);

      // If last visible file and there are more, overlay blur + text
      if (i == maxFilesToShow - 1 && remainingFiles > 0) {
        thumb = Stack(
          children: [
            SizedBox(width: 120, height: 120, child: thumb),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                child: Container(
                  width: 120,
                  height: 120,
                  color: Colors.black.withValues(alpha: 0.5),
                  alignment: Alignment.center,
                  child: Text(
                    '+$remainingFiles more',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      barrierColor: Colors.black.withValues(alpha: 0.5),
                      builder: (context) {
                        return GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => Navigator.of(context).pop(),
                          child: FilesModal(msg: msg),
                        );
                      },
                    );
                  },
                ),
              ),
            ),
          ],
        );
      }

      fileWidgets.add(thumb);
    }

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.all(14),
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
        decoration: BoxDecoration(
          gradient:
              isMe
                  ? LinearGradient(
                    colors: [
                      Theme.of(context).primaryColor.withValues(alpha: 1),
                      Theme.of(context).primaryColor.withValues(alpha: 0.5),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                  : LinearGradient(
                    colors: [
                      Theme.of(context).cardColor,
                      Theme.of(context).cardColor.withValues(alpha: 0.7),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 4,
              offset: const Offset(2, 2),
            ),
          ],
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft:
                isMe ? const Radius.circular(16) : const Radius.circular(4),
            bottomRight:
                isMe ? const Radius.circular(4) : const Radius.circular(16),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (msg.message.isNotEmpty)
              Text(
                msg.message,
                style: TextStyle(
                  color:
                      isMe
                          ? Colors.white
                          : Theme.of(context).textTheme.bodyMedium?.color,
                ),
              ),
            if (fileWidgets.isNotEmpty) ...[
              const SizedBox(height: 10),
              Wrap(spacing: 8, runSpacing: 8, children: fileWidgets),
            ],
          ],
        ),
      ),
    );
  }
}
