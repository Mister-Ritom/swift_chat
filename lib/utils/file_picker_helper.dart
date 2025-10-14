import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:open_filex/open_filex.dart';
import 'package:saver_gallery/saver_gallery.dart';

/// A helper class to handle file picking for both mobile and web.
class FilePickerHelper {
  static final ImagePicker _imagePicker = ImagePicker();

  /// ------------------------
  /// GENERAL FILE PICKING
  /// ------------------------
  /// Pick any type of file (documents, media, etc.)
  /// On web: returns bytes and filename instead of File
  static Future<List<PickedFileData>> pickAnyFile({
    bool allowMultiple = false,
  }) async {
    if (kIsWeb) {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: allowMultiple,
        type: FileType.any,
        withData: true, // IMPORTANT for web
      );

      if (result != null && result.files.isNotEmpty) {
        return result.files
            .map(
              (f) => PickedFileData(
                name: f.name,
                bytes: f.bytes,
                path: f.path, // null on web
              ),
            )
            .toList();
      }
    } else {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: allowMultiple,
        type: FileType.any,
      );
      if (result != null && result.files.isNotEmpty) {
        return result.files
            .map((f) => PickedFileData(name: f.name, path: f.path!))
            .toList();
      }
    }
    return [];
  }

  /// ------------------------
  /// IMAGE PICKING
  /// ------------------------
  static Future<List<PickedFileData>> pickImages({
    bool allowMultiple = false,
  }) async {
    if (kIsWeb) {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: allowMultiple,
        type: FileType.image,
        withData: true,
      );
      if (result != null && result.files.isNotEmpty) {
        return result.files
            .map((f) => PickedFileData(name: f.name, bytes: f.bytes))
            .toList();
      }
    } else {
      if (allowMultiple) {
        final pickedFiles = await _imagePicker.pickMultiImage();
        if (pickedFiles.isNotEmpty) {
          return pickedFiles
              .map((x) => PickedFileData(name: x.name, path: x.path))
              .toList();
        }
      } else {
        final pickedFile = await _imagePicker.pickImage(
          source: ImageSource.gallery,
        );
        if (pickedFile != null) {
          return [PickedFileData(name: pickedFile.name, path: pickedFile.path)];
        }
      }
    }
    return [];
  }

  /// ------------------------
  /// VIDEO PICKING
  /// ------------------------
  static Future<List<PickedFileData>> pickVideos({
    bool allowMultiple = false,
  }) async {
    if (kIsWeb) {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: allowMultiple,
        type: FileType.video,
        withData: true,
      );
      if (result != null && result.files.isNotEmpty) {
        return result.files
            .map((f) => PickedFileData(name: f.name, bytes: f.bytes))
            .toList();
      }
    } else {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: allowMultiple,
        type: FileType.video,
      );
      if (result != null && result.files.isNotEmpty) {
        return result.files
            .map((f) => PickedFileData(name: f.name, path: f.path!))
            .toList();
      }
    }
    return [];
  }

  /// ------------------------
  /// AUDIO PICKING
  /// ------------------------
  static Future<List<PickedFileData>> pickAudio({
    bool allowMultiple = false,
  }) async {
    if (kIsWeb) {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: allowMultiple,
        type: FileType.audio,
        withData: true,
      );
      if (result != null && result.files.isNotEmpty) {
        return result.files
            .map((f) => PickedFileData(name: f.name, bytes: f.bytes))
            .toList();
      }
    } else {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: allowMultiple,
        type: FileType.audio,
      );
      if (result != null && result.files.isNotEmpty) {
        return result.files
            .map((f) => PickedFileData(name: f.name, path: f.path!))
            .toList();
      }
    }
    return [];
  }

  /// ------------------------
  /// CAMERA CAPTURE
  /// ------------------------
  static Future<PickedFileData?> captureImageFromCamera({
    bool saveToGallery = true,
  }) async {
    if (kIsWeb) {
      // No camera support via ImagePicker on web
      return null;
    } else {
      final pickedFile = await _imagePicker.pickImage(
        source: ImageSource.camera,
      );
      if (pickedFile != null) {
        final bytes = await pickedFile.readAsBytes();
        if (saveToGallery) {
          await SaverGallery.saveImage(
            bytes,
            skipIfExists: false,
            fileName: pickedFile.name,
          );
        }
        return PickedFileData(name: pickedFile.name, path: pickedFile.path);
      }
    }
    return null;
  }

  /// ------------------------
  /// OPEN FILE
  /// ------------------------
  static Future<void> openFile(PickedFileData file) async {
    if (kIsWeb) return; // Not supported
    if (file.path != null) await OpenFilex.open(file.path!);
  }
}

/// Wrapper class to store file info for both web (bytes) and mobile (File)
class PickedFileData {
  final String name;
  final String? path; // null on web
  final Uint8List? bytes; // only used on web or direct upload

  PickedFileData({required this.name, this.path, this.bytes});
}
