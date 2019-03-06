import 'dart:async';
import 'dart:io';

import 'package:adv_image_picker/adv_image_picker.dart';
import 'package:adv_image_picker/models/result_item.dart';
import 'package:adv_image_picker/pages/gallery.dart';
import 'package:adv_image_picker/pages/result.dart';
import 'package:camera/camera.dart';
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

  CameraPage({bool allowMultiple, bool enableGallery})
      : this.allowMultiple = allowMultiple ?? true,
        this.enableGallery = enableGallery ?? true;

  @override
  _CameraPageState createState() {
    return _CameraPageState();
  }
}

IconData getCameraLensIcon(CameraLensDirection direction) {
  switch (direction) {
    case CameraLensDirection.back:
      return Icons.camera_rear;
    case CameraLensDirection.front:
      return Icons.camera_front;
    case CameraLensDirection.external:
      return Icons.camera;
  }
  throw ArgumentError(AdvImagePicker.unknownLensDirection);
}

void logError(String code, String message) => print(
    '${AdvImagePicker.error}: $code\n${AdvImagePicker.errorMessage}: $message');

class _CameraPageState extends State<CameraPage> {
  CameraController controller;
  String imagePath;
  int _currentCameraIndex = 0;

  List<CameraDescription> cameras;

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        await controller?.dispose();

        return true;
      },
      child: Scaffold(
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
                      if (cameras == null || cameras.length == 0) return;

                      _currentCameraIndex++;
                      if (_currentCameraIndex >= cameras.length)
                        _currentCameraIndex = 0;

                      onNewCameraSelected(cameras[_currentCameraIndex]);
                    },
                  ),
                  Container(
                      margin: EdgeInsets.only(bottom: 8.0),
                      child: Text(
                        AdvImagePicker.photo,
                        style: TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 12.0),
                      )),
                  AdvVisibility(
                    visibility: widget.enableGallery ? VisibilityFlag.visible : VisibilityFlag.invisible,
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
                                    )));
                      },
                    ),
                  ),
                ])),
        key: _scaffoldKey,
        body: AdvFutureBuilder(
            widgetBuilder: _buildWidget, futureExecutor: _loadAll),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
        floatingActionButton: FloatingActionButton(
          elevation: 0.0,
          onPressed: () {
            takePicture().then((resultPath) async {
              if (resultPath == null) return;
              ByteData bytes = await rootBundle.load(resultPath);
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (BuildContext context) => ResultPage(
                          [ResultItem("", resultPath, data: bytes)])));
            });
          },
          backgroundColor: AdvImagePicker.primaryColor,
          highlightElevation: 0.0,
          child: Container(
            width: 30.0,
            height: 30.0,
            decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.all(Radius.circular(30.0))),
          ),
        ),
      ),
    );
  }

  Future<bool> _loadAll(BuildContext context) async {
    if (cameras != null) return false;

    // Fetch the available cameras before initializing the app.
    try {
      cameras = await availableCameras();
    } on CameraException catch (e) {
      print("CameraException => ${e.description}, ${e.code}");
      logError(e.code, e.description);
    }

    if (cameras != null && cameras.length > 0)
      onNewCameraSelected(cameras[_currentCameraIndex]);

    return true;
  }

  Widget _buildWidget(BuildContext context) {
    return AdvLoadingWithBarrier(
        content: Stack(
          children: <Widget>[
            _cameraPreviewWidget(),
          ],
        ),
        isProcessing: cameras == null);
  }

  /// Display the preview from the camera (or a message if the preview is not available).
  Widget _cameraPreviewWidget() {
    if (controller == null || !controller.value.isInitialized) {
      return Container();
    } else {
      final size = MediaQuery.of(context).size;
      controller.removeListener(_listener);
      controller.value = controller.value.copyWith(
          previewSize: Size(
        size.height,
        size.width,
      ));
      controller.addListener(_listener);
      return OverflowBox(
        maxHeight: double.infinity,
        child: AspectRatio(
          aspectRatio: controller.value.aspectRatio,
          child: CameraPreview(controller),
        ),
      );
    }
  }

  String timestamp() => DateTime.now().millisecondsSinceEpoch.toString();

  void showInSnackBar(String message) {
    _scaffoldKey.currentState.showSnackBar(SnackBar(content: Text(message)));
  }

//  Handler (android.os.Handler) {17b2b7ee} sending message to a Handler on a dead thread//
  void onNewCameraSelected(CameraDescription cameraDescription) async {
    if (controller != null) {
      await controller.dispose();
    }

    controller = CameraController(cameraDescription, ResolutionPreset.high);

    controller.addListener(_listener);

    try {
      await controller.initialize();
    } on CameraException catch (e) {
      _showCameraException(e);
    }

    if (mounted) {
      setState(() {});
    }
  }

  Future<String> takePicture() async {
    if (controller == null || !controller.value.isInitialized) {
      return null;
    }

    final Directory extDir = await getApplicationDocumentsDirectory();
    final String dirPath = '${extDir.path}/Pictures/flutter_test';
    await Directory(dirPath).create(recursive: true);
    final String filePath = '$dirPath/${timestamp()}.jpg';

    if (controller.value.isTakingPicture) {
      // A capture is already pending, do nothing.
      return null;
    }

    try {
      await controller.takePicture(filePath);
    } on CameraException catch (e) {
      _showCameraException(e);
      return null;
    }
    return filePath;
  }

  void _showCameraException(CameraException e) {
    logError(e.code, e.description);
    showInSnackBar('${AdvImagePicker.error}: ${e.code}\n${e.description}');
  }

  void _listener() {
    if (mounted) setState(() {});
    if (controller.value.hasError) {
      showInSnackBar(
          '${AdvImagePicker.error} ${controller.value.errorDescription}');
    }
  }
}
