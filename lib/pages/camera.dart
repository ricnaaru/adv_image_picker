import 'dart:async';
import 'dart:io';

import 'package:adv_camera/adv_camera.dart';
import 'package:adv_image_picker/adv_image_picker.dart';
import 'package:adv_image_picker/components/adv_state.dart';
import 'package:adv_image_picker/components/camera_image_holder.dart';
import 'package:adv_image_picker/models/result_item.dart';
import 'package:adv_image_picker/pages/gallery.dart';
import 'package:adv_image_picker/pages/result.dart';
import 'package:adv_image_picker/plugins/adv_image_picker_plugin.dart';
import 'package:basic_components/components/adv_loading_with_barrier.dart';
import 'package:basic_components/utilities/toast.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

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

void logError(String code, String message) => print(
    '${AdvImagePicker.error}: $code\n${AdvImagePicker.errorMessage}: $message');

class _CameraPageState extends AdvState<CameraPage>
    with WidgetsBindingObserver {
  AdvCameraController controller;
  String imagePath;
  List<ResultItem> images = [];
  Completer<String> takePictureCompleter;
  FlashType flashType = FlashType.auto;

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget buildView(BuildContext context) {
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
        padding: EdgeInsets.symmetric(horizontal: 32.0, vertical: 8.0),
        color: Colors.white,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            FloatingActionButton(
              heroTag: 'GoToGallery',
              onPressed: () async {
                if (Platform.isIOS) {
                  bool hasPermission =
                      await AdvImagePickerPlugin.getIosStoragePermission();
                  if (!hasPermission) {
                    Toast.showToast(context, "Permission denied");
                    return null;
                  } else {
                    goToGallery();
                  }
                } else {
                  goToGallery();
                }
              },
              //mini: true,
              child: Icon(Icons.photo_library),
            ),
            InkWell(
              onTap: () async {
                String resultPath = await takePicture();

                if (resultPath == null) return;

                ResultItem result = ResultItem("", resultPath);

                List<ResultItem> _newImages = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (BuildContext context) => ResultPage([result]),
                  ),
                );
                setState(() {
                  images.addAll(_newImages);
                });
              },
              child: Material(
                elevation: 4,
                shape: CircleBorder(),
                clipBehavior: Clip.antiAlias,
                child: CircleAvatar(
                  radius: 35,
                  backgroundColor: AdvImagePicker.primaryColor.withAlpha(100),
                  child: CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.white,
                    child: CircleAvatar(
                        radius: 29,
                        backgroundColor: AdvImagePicker.primaryColor),
                  ),
                ),
              ),
            ),
            FloatingActionButton(
              heroTag: 'Submit',
              onPressed: () {
                Navigator.pop(context, images);
              },
              child: Icon(Icons.check),
              //backgroundColor: Colors.green,
            )
          ],
        ),
      ),
      key: _scaffoldKey,
      body: _buildWidget(context),
      //floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      /*floatingActionButton: FloatingActionButton(
        heroTag: "CaptureButton",
        elevation: 0.0,
        onPressed: () async {
          String resultPath = await takePicture();

          if (resultPath == null) return;

          ResultItem result = ResultItem("", resultPath);

          List<ResultItem> _newImages = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (BuildContext context) => ResultPage([result]),
            ),
          );
          setState(() {
            images.addAll(_newImages);
          });
        },
        backgroundColor: AdvImagePicker.primaryColor.withAlpha(80),
        highlightElevation: 0.0,
        child: Container(
          width: 40.0,
          height: 40.0,
          decoration: BoxDecoration(
              color: AdvImagePicker.primaryColor,
              borderRadius: BorderRadius.all(Radius.circular(30.0))),
        ),
      ),*/
    );
  }

  void goToGallery() async {
    List<ResultItem> _newImages = [];
    _newImages = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (BuildContext context) => GalleryPage(
          allowMultiple: widget.allowMultiple,
          maxSize: widget.maxSize,
        ),
      ),
    );
    setState(() {
      images.addAll(_newImages);
    });
  }

  Widget _buildWidget(BuildContext context) {
    return AdvLoadingWithBarrier(
        content: (BuildContext context) => _cameraPreviewWidget(context),
        isProcessing: controller == null);
  }

  /// Display the preview from the camera (or a message if the preview is not available).
  Widget _cameraPreviewWidget(BuildContext context) {
    return Stack(
      children: [
        AdvCamera(
          onCameraCreated: _onCameraCreated,
          onImageCaptured: (String path) {
            takePictureCompleter.complete(path);
            takePictureCompleter = null;
          },
          cameraPreviewRatio: CameraPreviewRatio.r16_9,
          fileNamePrefix: AdvImagePicker.cameraFilePrefixName,
        ),
        Positioned(
          top: 8.0,
          left: 8.0,
          child: FloatingActionButton(
            heroTag: "FlashButton",
            backgroundColor: AdvImagePicker.primaryColor.withAlpha(80),
            mini: true,
            child: Icon(
              flashType == FlashType.auto
                  ? Icons.flash_auto
                  : flashType == FlashType.on
                      ? Icons.flash_on
                      : Icons.flash_off,
              size: 18.0,
            ),
            onPressed: _toggleFlash,
            elevation: 0.0,
          ),
        ),
        Positioned(
          top: 8.0,
          right: 8.0,
          child: FloatingActionButton(
            heroTag: "SwitchCameras",
            backgroundColor: AdvImagePicker.primaryColor.withAlpha(80),
            mini: true,
            child: Icon(
              Icons.switch_camera,
              size: 18.0,
            ),
            onPressed: () {
              controller.switchCamera();
            },
            elevation: 0.0,
          ),
        ),
        Positioned(
          bottom: 130,
          left: 0.0,
          right: 0.0,
          child: Container(
            //color: Colors.grey,
            height: 70,
            //width: 200,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: 10,
              itemBuilder: (context, index) => GestureDetector(
                onTap: () {},
                child: CameraImageHolder(
                  isCover: false,
                  child: images.length < (index + 1)
                      ? Icon(
                          Icons.add_a_photo,
                          color: Colors.grey,
                        )
                      : Image.asset(
                          images[index].filePath,
                          fit: BoxFit.fill,
                        ),
                ),
              ),
            ),
          ),
        )
      ],
    );
  }

  String timestamp() => DateTime.now().millisecondsSinceEpoch.toString();

  void showInSnackBar(String message) {
    _scaffoldKey.currentState.showSnackBar(SnackBar(content: Text(message)));
  }

  Future<String> takePicture() async {
    if (controller == null || takePictureCompleter != null) {
      return null;
    }

    takePictureCompleter = Completer<String>();

    await controller.captureImage(maxSize: widget.maxSize);

    return await takePictureCompleter.future;
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
    if (AdvImagePicker.cameraSavePath == null) {
      AdvImagePicker.getDefaultDirectoryForCamera().then((dir) async {
        await dir.create(recursive: true);

        await controller
            .setSavePath("${dir.path}/${AdvImagePicker.cameraFolderName}");
      });
    } else {
      controller.setSavePath("${AdvImagePicker.cameraSavePath}");
    }

    setState(() {});
  }

  void _toggleFlash() {
    process(() async {
      if (controller == null) return;

      if (flashType == FlashType.auto) {
        flashType = FlashType.on;
      } else if (flashType == FlashType.on) {
        flashType = FlashType.off;
      } else if (flashType == FlashType.off) {
        flashType = FlashType.auto;
      }
      await controller.setFlashType(flashType);

      refresh();
    });
  }
}
