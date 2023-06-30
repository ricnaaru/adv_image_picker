import 'dart:async';
import 'dart:io';

import 'package:adv_camera/adv_camera.dart';
import 'package:adv_image_picker/adv_image_picker.dart';
import 'package:adv_image_picker/models/result_item.dart';
import 'package:adv_image_picker/pages/gallery.dart';
import 'package:adv_image_picker/pages/result.dart';
import 'package:adv_image_picker/plugins/adv_image_picker_plugin.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class CameraPage extends StatefulWidget {
  final bool allowMultiple;
  final bool enableGallery;
  final int? maxSize;

  CameraPage({bool? allowMultiple, bool? enableGallery, this.maxSize})
      : assert(maxSize == null || maxSize >= 0),
        this.allowMultiple = allowMultiple ?? true,
        this.enableGallery = enableGallery ?? true;

  @override
  _CameraPageState createState() {
    return _CameraPageState();
  }
}

class _CameraPageState extends State<CameraPage> with WidgetsBindingObserver {
  AdvCameraController? controller;
  String? imagePath;
  Completer<String>? takePictureCompleter;
  FlashType flashType = FlashType.auto;
  bool initialized = false;
  bool processing = false;

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (AdvImagePicker.cameraSavePath == null) {
      AdvImagePicker.getDefaultDirectoryForCamera().then((dir) async {
        if (dir == null) return;

        await dir.create(recursive: true);

        AdvImagePicker.cameraSavePath = dir.path;

        if (this.mounted)
          setState(() {
            initialized = true;
          });
      });
    } else {
      initialized = true;
    }
  }

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
      bottomSheet: buildBottomActions(context),
      key: _scaffoldKey,
      body: _buildWidget(context),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: FloatingActionButton(
        heroTag: "CaptureButton",
        elevation: 0.0,
        onPressed: () {
          process(
            () async {
              String? resultPath = await takePicture();

              if (resultPath == null) return;

              ResultItem result = ResultItem("", resultPath);

              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (BuildContext context) => ResultPage([result]),
                ),
              );
            },
          );
        },
        backgroundColor: AdvImagePicker.primaryColor,
        highlightElevation: 0.0,
        child: Container(
          width: 30.0,
          height: 30.0,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.all(Radius.circular(30.0)),
          ),
        ),
      ),
    );
  }

  void goToGallery() {
    process(
      () async {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (BuildContext context) => GalleryPage(
              allowMultiple: widget.allowMultiple,
              maxSize: widget.maxSize,
            ),
          ),
        );
      },
    );
  }

  Widget _buildWidget(BuildContext context) {
    if (!initialized) return Center(child: CircularProgressIndicator());

    return Stack(
      children: [
        _cameraPreviewWidget(context),
        if (controller == null) Center(child: CircularProgressIndicator()),
      ],
    );
  }

  /// Display the preview from the camera (or a message if the preview is not available).
  Widget _cameraPreviewWidget(BuildContext context) {
    return Stack(
      children: [
        AdvCamera(
          savePath: AdvImagePicker.cameraSavePath,
          onCameraCreated: _onCameraCreated,
          onImageCaptured: (String path) {
            if (takePictureCompleter == null) return;
            takePictureCompleter!.complete(path);
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

  Future<String?> takePicture() async {
    if (controller == null || takePictureCompleter != null) {
      return null;
    }

    takePictureCompleter = Completer<String>();

    await controller!.captureImage(maxSize: widget.maxSize);

    return await takePictureCompleter!.future;
  }

  void _onCameraCreated(AdvCameraController controller) {
    this.controller = controller;

    setState(() {});
  }

  void _toggleFlash() {
    process(
      () async {
        if (controller == null) return;

        if (flashType == FlashType.auto) {
          flashType = FlashType.on;
        } else if (flashType == FlashType.on) {
          flashType = FlashType.off;
        } else if (flashType == FlashType.off) {
          flashType = FlashType.auto;
        }

        await controller!.setFlashType(flashType);

        if (this.mounted) setState(() {});
      },
    );
  }

  Widget buildBottomActions(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 32.0, vertical: 8.0),
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          ActionButton(
            text: AdvImagePicker.rotate,
            icon: Icons.switch_camera,
            onPressed: () {
              if (controller == null) return;

              process(() async {
                await controller!.switchCamera();
              });
            },
          ),
          Container(
            margin: EdgeInsets.only(top: 8.0),
            child: Text(
              AdvImagePicker.photo,
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12.0),
            ),
          ),
          Opacity(
            opacity: widget.enableGallery ? 1 : 0,
            child: IgnorePointer(
              ignoring: !widget.enableGallery,
              child: ActionButton(
                text: AdvImagePicker.gallery,
                icon: Icons.photo_album,
                onPressed: () async {
                  if (Platform.isIOS) {
                    bool hasPermission =
                        await AdvImagePickerPlugin.getIosStoragePermission();
                    if (!hasPermission) {
                      // Toast.showToast(context, "Permission denied");
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
          ),
        ],
      ),
    );
  }

  Future<void> process(AsyncCallback func) async {
    if (processing) return;

    processing = true;

    await func();

    processing = false;
  }
}

class ActionButton extends StatelessWidget {
  final String text;
  final IconData icon;
  final VoidCallback? onPressed;

  const ActionButton({
    Key? key,
    required this.text,
    required this.icon,
    this.onPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialButton(
      child: Padding(
        padding: EdgeInsets.all(8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(text),
            SizedBox(height: 4),
            Icon(icon),
          ],
        ),
      ),
      onPressed: onPressed,
    );
  }
}
