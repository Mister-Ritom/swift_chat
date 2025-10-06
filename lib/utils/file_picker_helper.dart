import 'dart:developer';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:open_filex/open_filex.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:saver_gallery/saver_gallery.dart';

/// A helper class to handle all file picking logic safely with permissions.
/// Supports documents, media, audio, camera capture, saving to gallery, etc.
class FilePickerHelper {
  static final ImagePicker _imagePicker = ImagePicker();

  /// Centralized permission request
  static Future<bool> _requestPermissions({
    bool camera = false,
    bool photosRead = false,
    bool photosAddOnly = false,
    bool microphone = false,
    bool contacts = false,
    bool storage = false,
    bool location = false,
    bool video = false,
    bool audio = false,
  }) async {
    if (Platform.isMacOS) {
      return true; // macOS handles Finder/Dialogs automatically
    }

    final Map<Permission, PermissionStatus> statuses = {};

    if (camera) statuses.addAll(await [Permission.camera].request());
    if (photosRead || photosAddOnly) {
      final result =
          await [
            if (photosRead) Permission.photos,
            if (photosAddOnly) Permission.photosAddOnly,
          ].request();
      statuses.addAll(result);
    }
    if (microphone) statuses.addAll(await [Permission.microphone].request());
    if (contacts) statuses.addAll(await [Permission.contacts].request());
    if (storage) statuses.addAll(await [Permission.storage].request());
    if (location) {
      statuses.addAll(await [Permission.locationWhenInUse].request());
    }
    if (video) statuses.addAll(await [Permission.videos].request());
    if (audio) statuses.addAll(await [Permission.audio].request());

    return statuses.values.every((status) => status.isGranted);
  }

  /// Pick any type of file (documents, media, etc.)
  static Future<List<File>> pickAnyFile({bool allowMultiple = false}) async {
    if (!await _requestPermissions(storage: true)) return [];
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: allowMultiple,
      type: FileType.any,
    );
    if (result != null && result.files.isNotEmpty) {
      return result.paths.map((path) => File(path!)).toList();
    }
    return [];
  }

  /// Pick images using ImagePicker (supports gallery)
  static Future<List<File>> pickImages({bool allowMultiple = false}) async {
    if (!await _requestPermissions(photosRead: true, photosAddOnly: true)) {
      return [];
    }

    if (allowMultiple) {
      final pickedFiles = await _imagePicker.pickMultiImage();
      if (pickedFiles.isNotEmpty) {
        return pickedFiles.map((x) => File(x.path)).toList();
      }
    } else {
      final pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
      );
      if (pickedFile != null) return [File(pickedFile.path)];
    }
    return [];
  }

  /// Pick only video files
  static Future<List<File>> pickVideos({bool allowMultiple = false}) async {
    if (!await _requestPermissions(
      photosRead: true,
      photosAddOnly: true,
      video: Platform.isAndroid,
    )) {
      return [];
    }

    final result = await FilePicker.platform.pickFiles(
      allowMultiple: allowMultiple,
      type: FileType.video,
    );
    if (result != null && result.files.isNotEmpty) {
      return result.paths.map((path) => File(path!)).toList();
    }
    return [];
  }

  /// Pick only audio files
  static Future<List<File>> pickAudio({bool allowMultiple = false}) async {
    if (!await _requestPermissions(audio: true)) return [];

    final result = await FilePicker.platform.pickFiles(
      allowMultiple: allowMultiple,
      type: FileType.audio,
    );
    if (result != null && result.files.isNotEmpty) {
      return result.paths.map((path) => File(path!)).toList();
    }
    return [];
  }

  /// Capture an image directly from the device camera and auto-save to Photos/Gallery
  static Future<File?> captureImageFromCamera({
    bool saveToGallery = true,
  }) async {
    final pickedFile = await _imagePicker.pickImage(source: ImageSource.camera);
    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      String filePath = "my_photo_${DateTime.now().millisecondsSinceEpoch}.jpg";
      final result = await SaverGallery.saveImage(
        bytes,
        fileName: filePath,
        skipIfExists: true,
      );

      if (result.isSuccess) {
        log("Saved at: $filePath");
      } else {
        log("Error trying to save image ${result.errorMessage}");
      }

      return File(pickedFile.path);
    }
    return null;
  }

  /// Pick a single file of a specific type (custom filters)
  static Future<File?> pickSingleFileOfType(FileType type) async {
    if (!await _requestPermissions(storage: true)) return null;

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
