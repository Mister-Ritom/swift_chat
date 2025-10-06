import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:open_filex/open_filex.dart';

/// A helper class to handle all file picking logic.
/// Supports documents, images, videos, audio, and direct camera capture.
class FilePickerHelper {
  static final ImagePicker _imagePicker = ImagePicker();

  /// Pick any type of file (documents, media, etc.)
  static Future<List<File>> pickAnyFile({bool allowMultiple = false}) async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: allowMultiple,
      type: FileType.any,
    );

    if (result != null && result.files.isNotEmpty) {
      return result.paths.map((path) => File(path!)).toList();
    }
    return [];
  }

  /// Pick only image files from gallery
  static Future<List<File>> pickImages({bool allowMultiple = false}) async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: allowMultiple,
      type: FileType.image,
    );

    if (result != null && result.files.isNotEmpty) {
      return result.paths.map((path) => File(path!)).toList();
    }
    return [];
  }

  /// Pick only video files
  static Future<List<File>> pickVideos({bool allowMultiple = false}) async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: allowMultiple,
      type: FileType.video,
    );

    if (result != null && result.files.isNotEmpty) {
      return result.paths.map((path) => File(path!)).toList();
    }
    return [];
  }

  /// Pick only audio files (for voice recordings, music, etc.)
  static Future<List<File>> pickAudio({bool allowMultiple = false}) async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: allowMultiple,
      type: FileType.audio,
    );

    if (result != null && result.files.isNotEmpty) {
      return result.paths.map((path) => File(path!)).toList();
    }
    return [];
  }

  /// Capture an image directly from the device camera
  static Future<File?> captureImageFromCamera() async {
    final pickedFile = await _imagePicker.pickImage(source: ImageSource.camera);
    if (pickedFile != null) {
      return File(pickedFile.path);
    }
    return null;
  }

  /// Pick a single file of a specific type (for custom file filters)
  static Future<File?> pickSingleFileOfType(FileType type) async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: false,
      type: type,
    );

    if (result != null && result.files.single.path != null) {
      return File(result.files.single.path!);
    }
    return null;
  }

  /// Open a file using the system's default viewer
  static Future<void> openFile(File file) async {
    await OpenFilex.open(file.path);
  }
}
