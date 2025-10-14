import 'package:flutter/material.dart';
import 'package:swift_chat/utils/file_picker_helper.dart';
import 'package:swift_chat/utils/mapping.dart';

class AttachmentPreview extends StatelessWidget {
  final List<PickedFileData> files;
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
                // Build thumbnail based on platform
                buildFileThumbnailWidget(file),
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

  Widget buildFileThumbnailWidget(PickedFileData file) {
    // Use bytes for web, path for mobile
    if (file.bytes != null) {
      // Web: display image if possible, else generic icon
      return Image.memory(
        file.bytes!,
        width: 80,
        height: 80,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _genericFileThumbnail(file.name),
      );
    } else if (file.path != null) {
      // Mobile: display image thumbnail or generic
      return buildFileThumbnail(file.path!, 80, false);
    } else {
      return _genericFileThumbnail(file.name);
    }
  }

  Widget _genericFileThumbnail(String fileName) {
    // Fallback widget for non-image files
    return Container(
      width: 80,
      height: 80,
      color: Colors.grey[300],
      child: Center(
        child: Text(
          fileName.split('.').last.toUpperCase(),
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
