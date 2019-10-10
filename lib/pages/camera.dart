import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:adv_camera/adv_camera.dart';
import 'package:adv_image_picker/adv_image_picker.dart';
import 'package:adv_image_picker/models/result_item.dart';
import 'package:adv_image_picker/pages/gallery.dart';
import 'package:adv_image_picker/pages/result.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pit_components/components/adv_button.dart';
import 'package:pit_components/components/adv_future_builder.dart';
import 'package:pit_components/components/adv_loading_with_barrier.dart';
import 'package:pit_components/components/adv_visibility.dart';

class CameraPage extends StatefulWidget {
  final bool allowMultiple;
  final bool enableGallery;
  final int maxSize;

  CameraPage({bool allowMultiple, bool enableGallery, this.maxSize})
      : assert(maxSize == null || maxSize >= 0),
        this.allowMultiple = allowMultiple ?? true,
        this.enableGallery = enableGallery ?? true;

  @override
  _CameraPageState createState() {
    return _CameraPageState();
  }
}

void logError(String code, String message) =>
    print('${AdvImagePicker.error}: $code\n${AdvImagePicker.errorMessage}: $message');

class _CameraPageState extends State<CameraPage> with WidgetsBindingObserver {
  AdvCameraController controller;
  String imagePath;
  int _currentCameraIndex = 0;
  Completer<String> takePictureCompleter;

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          AdvImagePicker.takePicture,
          style: TextStyle(color: Colors.black87),
        ),
        centerTitle: true,
        elevation: 0.0,
        backgroundColor: Colors.white,
        iconTheme: IconThemeData(color: Colors.black87),
      ),
      bottomSheet: Container(
          height: 80.0,
          padding: EdgeInsets.symmetric(horizontal: 32.0, vertical: 8.0),
          color: Colors.white,
          child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                AdvButtonWithIcon(
                  AdvImagePicker.rotate,
                  Icon(Icons.switch_camera),
                  Axis.vertical,
                  buttonSize: ButtonSize.small,
                  backgroundColor: Colors.white,
                  textColor: Colors.black87,
                  onPressed: () {
                    controller.switchCamera();
                  },
                ),
                Container(
                    margin: EdgeInsets.only(bottom: 8.0),
                    child: Text(
                      AdvImagePicker.photo,
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12.0),
                    )),
                AdvVisibility(
                  visibility:
                      widget.enableGallery ? VisibilityFlag.visible : VisibilityFlag.invisible,
                  child: AdvButtonWithIcon(
                    AdvImagePicker.gallery,
                    Icon(Icons.photo_album),
                    Axis.vertical,
                    buttonSize: ButtonSize.small,
                    backgroundColor: Colors.white,
                    textColor: Colors.black87,
                    onPressed: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (BuildContext context) => GalleryPage(
                                    allowMultiple: widget.allowMultiple,
                                    maxSize: widget.maxSize,
                                  )));
                    },
                  ),
                ),
              ])),
      key: _scaffoldKey,
      body: _buildWidget(context),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: FloatingActionButton(
        elevation: 0.0,
        onPressed: () {
          takePicture().then((resultPath) async {
            print("resultPath => $resultPath");
            if (resultPath == null) return;
            ByteData bytes = await _readFileByte(resultPath);
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (BuildContext context) =>
                        ResultPage([ResultItem("", resultPath, data: bytes)])));
          });
        },
        backgroundColor: AdvImagePicker.primaryColor,
        highlightElevation: 0.0,
        child: Container(
          width: 30.0,
          height: 30.0,
          decoration: BoxDecoration(
              color: Colors.white, borderRadius: BorderRadius.all(Radius.circular(30.0))),
        ),
      ),
    );
  }

  Future<ByteData> _readFileByte(String filePath) async {
    Uri myUri = Uri.parse(filePath);
    File audioFile = new File.fromUri(myUri);
    Uint8List bytes;
    await audioFile.readAsBytes().then((value) {
      bytes = Uint8List.fromList(value);
      print('reading of bytes is completed');
    }).catchError((onError) {
      print('Exception Error while reading audio from path:' +
          onError.toString());
    });
    return bytes.buffer.asByteData();
  }

  Widget _buildWidget(BuildContext context) {
    return AdvLoadingWithBarrier(
        content: (BuildContext context) => _cameraPreviewWidget(),
        isProcessing: controller == null);
  }

  /// Display the preview from the camera (or a message if the preview is not available).
  Widget _cameraPreviewWidget() {
    return AdvCamera(
      onCameraCreated: _onCameraCreated,
      onImageCaptured: (String path) {
        print("onImageCaptured => $path");
        takePictureCompleter.complete(path);
        print("after onImageCaptured");
      },
      cameraPreviewRatio: CameraPreviewRatio.r16_9,
    );
  }

  String timestamp() => DateTime.now().millisecondsSinceEpoch.toString();

  void showInSnackBar(String message) {
    _scaffoldKey.currentState.showSnackBar(SnackBar(content: Text(message)));
  }

  Future<String> takePicture() async {
    if (controller == null) {
      return null;
    }

    takePictureCompleter = Completer<String>();

    await controller.captureImage();
    print("before takePicture");
String s = await takePictureCompleter.future;
    print("after takePicture $s");
    return s;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _onCameraCreated(AdvCameraController controller) {
    this.controller = controller;

    getApplicationDocumentsDirectory().then((Directory extDir) async {
      final String dirPath = '${extDir.path}/Pictures';
      await Directory(dirPath).create(recursive: true);

      await controller.setSavePath(dirPath);
    });

    setState(() {

    });
  }
}
