import 'package:pocketbase/pocketbase.dart';

String mapAuthError(ClientException e) {
  try {
    final data = e.response['data'] as Map<String, dynamic>? ?? {};
    final firstError = data.values.first as Map<String, dynamic>?;
    final code = firstError?['code'] ?? '';
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
        return e.response['message'] ??
            'Something went wrong. Please try again.';
    }
  } catch (_) {
    return 'Something went wrong. Please try again.';
  }
}
