import 'dart:async';
import 'dart:io';

import 'package:adv_image_picker/models/result_item.dart';
import 'package:adv_image_picker/pages/camera.dart';
import 'package:adv_image_picker/pages/result.dart';
import 'package:adv_image_picker/plugins/adv_image_picker_plugin.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

class AdvImagePicker {
  static Color lightGrey = Color(0xffc6c6c6);
  static Color primaryColor = Colors.green;
  static Color accentColor = Colors.blue;
  static int maxImage = 99;
  static String takePicture = "Take Picture";
  static String rotate = "Rotate";
  static String photo = "Photo";
  static String gallery = "Gallery";
  static String unknownLensDirection = 'Unknown lens direction';
  static String error = "Error";
  static String errorMessage = "Error Message";
  static String next = "Next";
  static String confirmation = "Confirmation";
  static String confirm = "Confirm";
  static String cancel = "Cancel";

  static Future<List<File>> pickImagesToFile(BuildContext context) async {
    if (Platform.isAndroid) {
      bool hasPermission = await AdvImagePickerPlugin.getPermission();

      if (!hasPermission) return null;
    }

    List<File> files = [];
    List<ResultItem> images = await Navigator.push(
        context,
        MaterialPageRoute(
            builder: (BuildContext context) => CameraPage(),
            settings: RouteSettings(name: "CameraPage")));

    for (ResultItem item in images) {
      File file = File.fromUri(Uri.parse(item.filePath));
      bool fileExists = await file.exists();

      if (!fileExists) {
        final buffer = item.data.buffer;
        final Directory extDir = await getApplicationDocumentsDirectory();
        final String dirPath = '${extDir.path}/Pictures/flutter_test';
        await Directory(dirPath).create(recursive: true);
        final String filePath = '$dirPath/${_timestamp()}.jpg';
        file = await File(filePath).writeAsBytes(buffer.asUint8List(
            item.data.offsetInBytes, item.data.lengthInBytes));
      }
      files.add(file);
    }

    return files;
  }

  static Future<List<ByteData>> pickImagesToByte(BuildContext context) async {
    if (Platform.isAndroid) {
      bool hasPermission = await AdvImagePickerPlugin.getPermission();

      if (!hasPermission) return null;
    }

    List<ByteData> datas = [];
    List<ResultItem> images = await Navigator.push(
        context,
        MaterialPageRoute(
            builder: (BuildContext context) => CameraPage(),
            settings: RouteSettings(name: "CameraPage")));

    for (ResultItem item in images) {
      datas.add(item.data);
    }

    return datas;
  }

  static String _timestamp() =>
      DateTime.now().millisecondsSinceEpoch.toString();
}
