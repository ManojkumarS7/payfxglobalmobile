import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:payfxglobal/utils/session_manager.dart';

class ExternalActivityService {
  ExternalActivityService._();

  static final ImagePicker _imagePicker = ImagePicker();

  /// Pick a PDF, document or other file.
  static Future<FilePickerResult?> pickFiles({
    FileType type = FileType.any,
    List<String>? allowedExtensions,
    bool allowMultiple = false,
    bool withData = false,
    bool withReadStream = false,
    String? dialogTitle,
    String? initialDirectory,
    bool lockParentWindow = false,
  }) {
    return SessionManager().runWithoutSessionLock(
      () => FilePicker.platform.pickFiles(
        type: type,
        allowedExtensions: allowedExtensions,
        allowMultiple: allowMultiple,
        withData: withData,
        withReadStream: withReadStream,
        dialogTitle: dialogTitle,
        initialDirectory: initialDirectory,
        lockParentWindow: lockParentWindow,
      ),
    );
  }

  /// Pick one image from gallery.
  static Future<XFile?> pickImage({
    ImageSource source = ImageSource.gallery,
    double? maxWidth,
    double? maxHeight,
    int? imageQuality,
  }) {
    return SessionManager().runWithoutSessionLock(
      () => _imagePicker.pickImage(
        source: source,
        maxWidth: maxWidth,
        maxHeight: maxHeight,
        imageQuality: imageQuality,
      ),
    );
  }

  /// Pick multiple images.
  static Future<List<XFile>> pickMultiImage({
    double? maxWidth,
    double? maxHeight,
    int? imageQuality,
  }) {
    return SessionManager().runWithoutSessionLock(
      () => _imagePicker.pickMultiImage(
        maxWidth: maxWidth,
        maxHeight: maxHeight,
        imageQuality: imageQuality,
      ),
    );
  }

  /// Capture an image using the camera.
  static Future<XFile?> takePhoto({
    double? maxWidth,
    double? maxHeight,
    int? imageQuality,
  }) {
    return SessionManager().runWithoutSessionLock(
      () => _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: maxWidth,
        maxHeight: maxHeight,
        imageQuality: imageQuality,
      ),
    );
  }
}
