import 'dart:developer';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:swift_chat/utils/video_thumbnail.dart';

String mapAuthError(ClientException e) {
  try {
    // Safely cast to Map<String, dynamic>
    final data = Map<String, dynamic>.from(e.response['data'] ?? {});

    Map<String, dynamic>? firstError;

    if (data.isNotEmpty) {
      final firstValue = data.values.first;
      if (firstValue is Map) {
        firstError = Map<String, dynamic>.from(firstValue);
      }
    }

    final code = firstError?['code'] ?? e.response['code'] ?? '';
    final message =
        firstError?['message'] ?? e.response['message'] ?? e.toString();

    switch (code) {
      case 'validation_not_unique':
        return 'This value is already taken. Try a different one.';
      case 'validation_invalid_email':
        return 'Please enter a valid email address.';
      case 'validation_required':
        return 'All required fields must be filled.';
      case 'validation_min_length':
        return 'Value is too short.';
      case 'validation_max_length':
        return 'Value is too long.';
      case 'validation_password_mismatch':
        return 'Passwords do not match.';
      case 'validation_out_of_range':
        return 'Value is out of range.';
      case 'invalid_credentials':
        return 'Invalid email or password. Try again.';
      case 'forbidden':
        return 'You do not have permission to perform this action.';
      case 'not_found':
        return 'The requested resource could not be found.';
      default:
        return message;
    }
  } catch (error, stack) {
    // Add developer log here if needed
    log('Error mapping auth error', error: error, stackTrace: stack);
    return 'Unexpected error: ${e.response['message'] ?? e.toString()}';
  }
}

String timeAgo(DateTime date, {bool limit = true}) {
  final now = DateTime.now();
  final difference = now.difference(date);

  if (difference.inSeconds < 60) {
    return '${difference.inSeconds} second${difference.inSeconds == 1 ? '' : 's'} ago';
  } else if (difference.inMinutes < 60) {
    return '${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'} ago';
  } else if (difference.inHours < 24) {
    return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
  } else if (!limit || difference.inDays <= 3) {
    // If limit is false, always return in days no matter how large
    return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
  } else {
    // Otherwise fallback to date format
    return '${date.day}//${date.month}//${date.year % 100}';
  }
}

/// Reusable file thumbnail builder
Widget buildFileThumbnail(String url, double size, bool isNetwork) {
  final ext = url.split('.').last.toLowerCase();

  if (['png', 'jpg', 'jpeg', 'webp', 'gif'].contains(ext)) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child:
          isNetwork
              ? Image.network(url, width: size, height: size, fit: BoxFit.cover)
              : Image.file(
                File(url),
                width: size,
                height: size,
                fit: BoxFit.cover,
              ),
    );
  } else if (['mp4', 'mov', 'avi', 'mkv'].contains(ext)) {
    return SizedBox(
      width: size,
      height: size,
      child: VideoThumbnailWidget(video: url, isNetwork: isNetwork),
    );
  } else if (['mp3', 'wav', 'm4a', 'aac'].contains(ext)) {
    return Container(
      width: size,
      height: size,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.blueGrey.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.music_note, color: Colors.teal),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              url.split('/').last,
              style: const TextStyle(fontSize: 12),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  } else {
    String filename = url.split('/').last;
    if (isNetwork) {
      //Pocketbase adds a random string at the end starting with _
      final names = filename.split("_");
      final removedName = names.removeLast();
      final ext = ".${removedName.split(".").last}";
      names.add(ext);
      filename = names.join();
    }
    return Container(
      width: size,
      height: size,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.insert_drive_file, color: Colors.orange),
          const SizedBox(height: 4),
          Text(
            filename,
            style: const TextStyle(fontSize: 12, color: Colors.black),
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
