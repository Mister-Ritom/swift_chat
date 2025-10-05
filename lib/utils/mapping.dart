import 'dart:developer';

import 'package:pocketbase/pocketbase.dart';

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

String timeAgo(DateTime date) {
  final now = DateTime.now();
  final difference = now.difference(date);

  if (difference.inSeconds < 60) {
    return '${difference.inSeconds} second${difference.inSeconds == 1 ? '' : 's'} ago';
  } else if (difference.inMinutes < 60) {
    return '${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'} ago';
  } else if (difference.inHours < 24) {
    return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
  } else if (difference.inDays <= 3) {
    return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
  } else {
    //percentage 100 in year is used to convert eg. 2025 to 25
    return '${date.day}//${date.month}//${date.year % 100}';
  }
}
