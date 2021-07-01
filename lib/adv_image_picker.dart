import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:adv_camera/adv_camera.dart';
import 'package:adv_image_picker/models/result_item.dart';
import 'package:adv_image_picker/pages/camera.dart';
import 'package:adv_image_picker/pages/gallery.dart';
import 'package:adv_image_picker/plugins/adv_image_picker_plugin.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

class AdvImagePicker {
  static Color selectedImagePreviewColor = Colors.orange;
  static Color primaryColor = Colors.orange;
  static Color accentColor = Colors.blue;
  static int maxImage = 99;
  static String takePicture = "Take Picture";
  static String rotate = "Rotate";
  static String photo = "Photo";
  static String gallery = "Gallery";
  static String next = "Next";
  static String confirmation = "Confirmation";
  static String confirm = "Confirm";
  static String cancel = "Cancel";
  static String? cameraSavePath;
  static String cameraFolderName =
      "images"; //only used if you dont specify [AdvImagePicker.cameraSavePath]
  static String cameraFilePrefixName = "adv_image_picker";
  static FlashType defaultFlashType = FlashType.auto;

  static Future<List<ResultItem>?> _pickImages(
    BuildContext context, {
    bool usingCamera = true,
    bool usingGallery = true,
    bool allowMultiple = true,
    int? maxSize,
    Function(Exception)? onError,
  }) async {
    assert(usingCamera != false || usingGallery != false);

    if (Platform.isAndroid) {
      bool hasPermission = await AdvImagePickerPlugin.getPermission();

      if (!hasPermission) return null;
    }

    if (Platform.isIOS) {
      bool hasPermission = await AdvImagePickerPlugin.getIosStoragePermission();

      if (!hasPermission) {
        if (onError != null) {
          onError(Exception("Permission denied!"));
        }
        return null;
      }
    }

    Widget advImagePickerHome = usingCamera
        ? CameraPage(
            enableGallery: usingGallery,
            allowMultiple: allowMultiple,
            maxSize: maxSize)
        : GalleryPage(allowMultiple: allowMultiple, maxSize: maxSize);

    List<ResultItem>? images = await Navigator.push(
        context,
        MaterialPageRoute(
            builder: (BuildContext context) => advImagePickerHome,
            settings: RouteSettings(name: "AdvImagePickerHome")));

    return images;
  }

  static Future<List<File>?> pickImagesToFile(
    BuildContext context, {
    bool usingCamera = true,
    bool usingGallery = true,
    bool allowMultiple = true,
    int? maxSize,
  }) async {
    List<ResultItem>? images = await _pickImages(
      context,
      usingCamera: usingCamera,
      usingGallery: usingGallery,
      allowMultiple: allowMultiple,
      maxSize: maxSize,
    );

    if (images == null) return null;

    List<File> files = [];

    for (ResultItem item in images) {
      File file = File.fromUri(Uri.parse(item.filePath));
      bool fileExists = await file.exists();

      if (!fileExists) {
        final data = await _readFileByte(item.filePath);
        final buffer = data.buffer;
        final Directory extDir = await getApplicationDocumentsDirectory();
        final String dirPath = '${extDir.path}/Pictures/flutter_test';
        await Directory(dirPath).create(recursive: true);
        final String filePath = '$dirPath/${_timestamp()}.jpg';
        file = await File(filePath).writeAsBytes(
            buffer.asUint8List(data.offsetInBytes, data.lengthInBytes));
      }

      files.add(file);

      if (item.albumId == null) {
        File cameraImage = File(item.filePath);

        bool fileExists = await cameraImage.exists();

        if (!fileExists) {
          cameraImage.deleteSync();
        }
      }
    }

    return files;
  }

  static Future<List<ByteData>?> pickImagesToByte(BuildContext context,
      {bool usingCamera = true,
      bool usingGallery = true,
      bool allowMultiple = true,
      int? maxSize}) async {
    List<ResultItem>? images = await _pickImages(
      context,
      usingCamera: usingCamera,
      usingGallery: usingGallery,
      allowMultiple: allowMultiple,
      maxSize: maxSize,
    );

    if (images == null) return null;

    List<ByteData> datas = <ByteData>[];

    for (ResultItem item in images) {
      final data = await _readFileByte(item.filePath);
      datas.add(data);

      if (item.albumId == null) {
        File cameraImage = File(item.filePath);

        bool fileExists = await cameraImage.exists();

        if (!fileExists) {
          cameraImage.deleteSync();
        }
      }
    }

    return datas;
  }

  static Future<ByteData> _readFileByte(String filePath) async {
    File imageFile = new File(filePath);
    Uint8List bytes = imageFile.readAsBytesSync();
    return bytes.buffer.asByteData();
  }

  static String _timestamp() =>
      DateTime.now().millisecondsSinceEpoch.toString();

  static Future<Directory?> getDefaultDirectoryForCamera() async {
    Directory? extDir;

    if (Platform.isIOS) {
      extDir = await getApplicationDocumentsDirectory();
    } else if (Platform.isAndroid) {
      extDir = await getExternalStorageDirectory();
    }

    return extDir;
  }
}
