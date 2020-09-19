import 'dart:async';
import 'dart:io';

import 'package:adv_camera/adv_camera.dart';
import 'package:adv_image_picker/adv_image_picker.dart';
import 'package:adv_image_picker/components/adv_state.dart';
import 'package:adv_image_picker/models/result_item.dart';
import 'package:adv_image_picker/pages/gallery.dart';
import 'package:adv_image_picker/pages/result.dart';
import 'package:adv_image_picker/plugins/adv_image_picker_plugin.dart';
import 'package:basic_components/components/adv_button.dart';
import 'package:basic_components/components/adv_column.dart';
import 'package:basic_components/components/adv_loading_with_barrier.dart';
import 'package:basic_components/components/adv_visibility.dart';
import 'package:basic_components/utilities/toast.dart';
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
  Completer<String> takePictureCompleter;
  FlashType flashType = FlashType.auto;
  List<FlashType> _flashTypes;

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget buildView(BuildContext context) {
    print("build");
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
          children: [
            AdvButton.custom(
              child: AdvColumn(
                  mainAxisSize: MainAxisSize.min,
                  divider: ColumnDivider(4.0),
                  children: [
                    Text(AdvImagePicker.rotate),
                    Icon(Icons.switch_camera),
                  ]),
              buttonSize: ButtonSize.small,
              primaryColor: Colors.white,
              accentColor: Colors.black87,
              onPressed: switchCamera,
            ),
            Container(
              margin: EdgeInsets.only(top: 8.0),
              child: Text(
                AdvImagePicker.photo,
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12.0),
              ),
            ),
            AdvVisibility(
              visibility: widget.enableGallery
                  ? VisibilityFlag.visible
                  : VisibilityFlag.invisible,
              child: AdvButton.custom(
                child: AdvColumn(
                    mainAxisSize: MainAxisSize.min,
                    divider: ColumnDivider(4.0),
                    children: [
                      Text(AdvImagePicker.gallery),
                      Icon(Icons.photo_album),
                    ]),
                buttonSize: ButtonSize.small,
                primaryColor: Colors.white,
                accentColor: Colors.black87,
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
              ),
            ),
          ],
        ),
      ),
      key: _scaffoldKey,
      body: _buildWidget(context),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: FloatingActionButton(
        heroTag: "CaptureButton",
        elevation: 0.0,
        onPressed: () async {
          String resultPath = await takePicture();

          if (resultPath == null) return;

          ResultItem result = ResultItem("", resultPath);

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (BuildContext context) => ResultPage([result]),
            ),
          );
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
    );
  }

  void goToGallery() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (BuildContext context) => GalleryPage(
          allowMultiple: widget.allowMultiple,
          maxSize: widget.maxSize,
        ),
      ),
    );
  }

  Widget _buildWidget(BuildContext context) {
    return Container(
      color: Colors.green,
      child: AdvLoadingWithBarrier(
        content: (BuildContext context) => _cameraPreviewWidget(context),
        isProcessing: controller == null || _flashTypes == null,
      ),
    );
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
        if (_flashTypes != null && _flashTypes.length > 1)
          Positioned(
            top: 8.0,
            left: 8.0,
            child: FloatingActionButton(
              heroTag: "FlashButton",
              backgroundColor: AdvImagePicker.primaryColor,
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

    controller.getFlashType().then((value) {
      _flashTypes = value;
      if (_flashTypes.isEmpty)
        flashType = null;
      else
        flashType = _flashTypes.first;
      setState(() {});
    });
  }

  void _toggleFlash() {
    process(() async {
      if (controller == null) return;

      if (_flashTypes.length <= 1) return;

      if (flashType == FlashType.auto) {
        if (_flashTypes.contains(FlashType.on)) flashType = FlashType.on;
        if (_flashTypes.contains(FlashType.off)) flashType = FlashType.off;
      } else if (flashType == FlashType.on) {
        if (_flashTypes.contains(FlashType.off)) flashType = FlashType.off;
        if (_flashTypes.contains(FlashType.auto)) flashType = FlashType.auto;
      } else if (flashType == FlashType.off) {
        if (_flashTypes.contains(FlashType.auto)) flashType = FlashType.auto;
        if (_flashTypes.contains(FlashType.on)) flashType = FlashType.on;
      }

      await controller.setFlashType(flashType);

      refresh();
    });
  }

  Future<void> switchCamera() async {
    await controller.switchCamera();
    _flashTypes = await controller.getFlashType();
    if (_flashTypes.isEmpty)
      flashType = null;
    else
      flashType = _flashTypes.first;

    setState(() {});
  }
}
