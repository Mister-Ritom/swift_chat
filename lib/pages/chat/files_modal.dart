import 'package:flutter/material.dart';
import 'package:swift_chat/models/message_model.dart';
import 'package:swift_chat/utils/mapping.dart';

class FilesModal extends StatelessWidget {
  final MessageModel msg;
  const FilesModal({super.key, required this.msg});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      builder:
          (_, controller) => GestureDetector(
            onTap: () {}, // block tap inside sheet
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
              ),
              padding: const EdgeInsets.all(16),
              child: GridView.builder(
                controller: controller,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  childAspectRatio: 1,
                ),
                itemCount: msg.documentLinks.length,
                itemBuilder: (_, index) {
                  return buildFileThumbnail(
                    msg.documentLinks[index],
                    120,
                    true,
                  );
                },
              ),
            ),
          ),
    );
  }
}
