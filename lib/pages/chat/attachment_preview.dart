import 'dart:io';

import 'package:flutter/material.dart';
import 'package:swift_chat/utils/mapping.dart';

class AttachmentPreview extends StatelessWidget {
  final List<File> files;
  final void Function(int index) onRemove;

  const AttachmentPreview({
    super.key,
    required this.files,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 80,
      left: 0,
      right: 0,
      child: Container(
        height: 100,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: files.length,
          separatorBuilder: (_, __) => const SizedBox(width: 12),
          itemBuilder: (context, index) {
            final file = files[index];
            return Stack(
              children: [
                buildFileThumbnail(file.path, 80, false),
                Positioned(
                  top: 2,
                  right: 2,
                  child: GestureDetector(
                    onTap: () => onRemove(index),
                    child: const CircleAvatar(
                      radius: 10,
                      backgroundColor: Colors.red,
                      child: Icon(Icons.close, size: 14, color: Colors.white),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
