import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:adv_image_picker/adv_image_picker.dart';
import 'package:adv_image_picker/plugins/adv_image_picker_plugin.dart';
import 'package:flutter/material.dart';

void main() {
  CustomImageCache();
  runApp(MyApp());
}

class CustomImageCache extends WidgetsFlutterBinding {
  @override
  ImageCache createImageCache() {
    ImageCache imageCache = super.createImageCache();
    // Set your image cache size
    imageCache.maximumSize = 10;
    return imageCache;
  }
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'Image Picker Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({super.key, required this.title});

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  List<File> files = [];
  List<ImageProvider> thumbnails = [];
  bool isPreparing = false;

  @override
  void initState() {
    super.initState();

    AdvImagePicker.cameraFolderName = "Camera Folder";
    AdvImagePicker.cameraFilePrefixName = "CameraTestingPrefixName_";
    AdvImagePicker.cameraSavePath = "/storage/emulated/0/CameraTestingFolder/";
  }

  @override
  void dispose() {
    //flushing every memory that was taken before
    if ((thumbnails.length) > 0) {
      for (ImageProvider each in thumbnails) {
        each.evict();
      }
    }

    super.dispose();
  }

  void _pickImage() async {
    final result = await AdvImagePicker.pickImagesToFile(context, maxSize: 4080) ?? <File>[];
    files.addAll(result);
    print("files => ${files.map((e) => e.path).join("\n")}");
    prepare();
  }

  Future<void> prepare() async {
    List<ImageProvider> thumbnails = [];
    double screenWidth = MediaQuery.of(context).size.width;

    for (int i = 0; i < files.length; i++) {
      String path = files[i].path;
      ByteData data = await AdvImagePickerPlugin.getAlbumThumbnail(
        imagePath: path,
        height: screenWidth ~/ 4,
        width: screenWidth ~/ 4,
      );

      Uint8List imageData = data.buffer.asUint8List();

      thumbnails.add(MemoryImage(imageData));
    }

    this.thumbnails = List<ImageProvider>.from(thumbnails);

    if (this.mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: isPreparing ? CircularProgressIndicator() : GridView.count(
          crossAxisCount: 4,
          children: thumbnails
              .map((ImageProvider image) => Image(
                    image: image,
                    fit: BoxFit.cover,
                  ))
              .toList(),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _pickImage,
        child: Icon(Icons.add),
      ),
    );
  }
}
