import 'dart:io';

import 'package:image_picker/image_picker.dart';

class ImagePickerHelper {
  final ImagePicker _imagePicker = ImagePicker();

  Future<File?> getImageFromGallery() async {
    final file = await _imagePicker.pickImage(source: ImageSource.gallery);
    if (file != null) {
      return File(file.path);
    }
    return null;
  }

  Future<File?> getImageFromCamera() async {
    final file = await _imagePicker.pickImage(source: ImageSource.camera);
    if (file != null) {
      return File(file.path);
    }
    return null;
  }
}
