import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class InspectionPhotoService {
  InspectionPhotoService({ImagePicker? picker})
    : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;

  Future<String?> capturePhoto({
    ImageSource source = ImageSource.camera,
    required String storageKey,
  }) async {
    final XFile? file = await _picker.pickImage(
      source: source,
      imageQuality: 75,
      maxWidth: 1920,
      maxHeight: 1080,
    );
    if (file == null) {
      return null;
    }

    return _persistFile(File(file.path), storageKey);
  }

  Future<String?> _persistFile(File file, String storageKey) async {
    final Directory baseDir = await getApplicationDocumentsDirectory();
    final Directory photosDir = Directory(
      p.join(baseDir.path, 'inspection_photos', storageKey),
    );
    if (!await photosDir.exists()) {
      await photosDir.create(recursive: true);
    }

    final String fileName =
        '${DateTime.now().millisecondsSinceEpoch}_${p.basename(file.path)}';
    final String targetPath = p.join(photosDir.path, fileName);
    final File saved = await file.copy(targetPath);
    return saved.path;
  }

  Future<void> deletePhoto(String path) async {
    final File file = File(path);
    if (await file.exists()) {
      await file.delete();
    }
  }
}
