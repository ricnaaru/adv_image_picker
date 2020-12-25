import 'dart:io';
import 'dart:typed_data';

import 'package:adv_image_picker/adv_image_picker.dart';
import 'package:adv_image_picker/plugins/adv_image_picker_plugin.dart';
import 'package:flutter/material.dart';

class Preview extends StatefulWidget {
  final PreviewController controller;
  final double height;

  Preview(
      {double height,
      int currentImage,
      List<String> imagesPath,
      PreviewController controller})
      : assert(
            controller == null || (currentImage == null && imagesPath == null)),
        this.height = height ?? 250.0,
        this.controller = controller ??
            PreviewController(
              currentImage: currentImage ?? 0,
              filesPath: imagesPath ?? const [],
            );

  @override
  _PreviewState createState() => new _PreviewState();
}

class _PreviewState extends State<Preview> {
  List<ImageProvider> thumbnails;
  List<String> lastFilesPath;
  ImageProvider lastPhoto;

  @override
  void initState() {
    super.initState();

    lastFilesPath = widget.controller.filesPath;
    prepare();

    widget.controller.addListener(() {
      if (lastFilesPath != widget.controller.filesPath) prepare();

      lastFilesPath = widget.controller.filesPath;
    });
  }

  @override
  void dispose() {
    if ((thumbnails?.length ?? 0) > 0) {
      for (ImageProvider each in thumbnails) {
        each.evict();
      }
    }

    if (lastPhoto != null) lastPhoto.evict();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> children = [];

    if (thumbnails == null) {
      return Center(child: CircularProgressIndicator());
    }

    final PreviewController controller = widget.controller;
    String selectedPath =
        widget.controller.filesPath[widget.controller.currentImage];
    File selectedFile = File(selectedPath);
    Uint8List selectedImage = selectedFile.readAsBytesSync();
    lastPhoto = MemoryImage(selectedImage);

    children.add(
      Expanded(
        child: InteractiveViewer(
          child: Image(image: lastPhoto),
          // backgroundDecoration: BoxDecoration(
          //     color: Colors.black.withBlue(60).withGreen(60).withRed(60)),
          // imageProvider: ,
          // maxScale: PhotoViewComputedScale.covered * 2.0,
          // minScale: PhotoViewComputedScale.contained * 0.8,
          // initialScale: PhotoViewComputedScale.covered,
        ),
      ),
    );

    if (controller.filesPath.length > 1) {
      List<Widget> thumbnailWidgets = [];

      for (int i = 0; i < thumbnails.length; i++) {
        Widget image = Container(
          child: Image(
            image: thumbnails[i],
            fit: BoxFit.cover,
          ),
          color: Colors.black,
          height: widget.height / 5,
          width: widget.height / 5,
        );

        thumbnailWidgets.add(
          InkWell(
            onTap: () {
              setState(() {
                controller.currentImage = i;
              });
            },
            child: Stack(
              children: [
                image,
                Positioned(
                  bottom: 0.0,
                  left: 0.0,
                  right: 0.0,
                  height: widget.height / 100,
                  child: Opacity(
                    opacity: i == controller.currentImage ? 1 : 0,
                    child: Container(
                      color: AdvImagePicker.selectedImagePreviewColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }

      Widget rowOfThumbnails = SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.start,
          children: thumbnailWidgets,
        ),
      );

      children.add(rowOfThumbnails);
    }

    return Container(
      width: double.infinity,
      height: widget.height,
      child: Column(
        children: children,
        mainAxisSize: MainAxisSize.max,
      ),
      color: Colors.black.withBlue(30).withGreen(30).withRed(30),
    );
  }

  Future<void> prepare() async {
    List<ImageProvider> thumbnails = [];

    final PreviewController controller = widget.controller;

    if (controller.filesPath.length > 1) {
      for (int i = 0; i < controller.filesPath.length; i++) {
        String path = widget.controller.filesPath[i];
        ByteData data = await AdvImagePickerPlugin.getAlbumThumbnail(
          imagePath: path,
          height: widget.height ~/ 5,
          width: widget.height ~/ 5,
        );

        Uint8List imageData = data.buffer.asUint8List();

        thumbnails.add(MemoryImage(imageData));
      }
    }

    this.thumbnails = thumbnails;

    if (this.mounted) setState(() {});
  }
}

class PreviewController extends ValueNotifier<PreviewEditingValue> {
  int get currentImage => value.currentImage;

  set currentImage(int newCurrentImage) {
    value = value.copyWith(
        currentImage: newCurrentImage, filesPath: this.filesPath);
  }

  List<String> get filesPath => value.filesPath;

  set filesPath(List<String> newFilesPath) {
    value = value.copyWith(
        currentImage: this.currentImage, filesPath: newFilesPath);
  }

  PreviewController({int currentImage, List<String> filesPath})
      : super(currentImage == null && filesPath == null
            ? PreviewEditingValue.empty
            : new PreviewEditingValue(
                currentImage: currentImage, filesPath: filesPath));

  PreviewController.fromValue(PreviewEditingValue value)
      : super(value ?? PreviewEditingValue.empty);

  void clear() {
    value = PreviewEditingValue.empty;
  }
}

@immutable
class PreviewEditingValue {
  const PreviewEditingValue(
      {int currentImage, List<String> filesPath = const []})
      : this.currentImage = currentImage ?? 0,
        this.filesPath = filesPath ?? const [];

  final int currentImage;
  final List<String> filesPath;

  static const PreviewEditingValue empty = const PreviewEditingValue();

  PreviewEditingValue copyWith({int currentImage, List<String> filesPath}) {
    return new PreviewEditingValue(
        currentImage: currentImage ?? this.currentImage,
        filesPath: filesPath ?? this.filesPath);
  }

  PreviewEditingValue.fromValue(PreviewEditingValue copy)
      : this.currentImage = copy.currentImage,
        this.filesPath = copy.filesPath;

  @override
  String toString() => '$runtimeType(currentImage: \u2524$currentImage\u251C, '
      'filesPath: \u2524$filesPath\u251C)';

  @override
  bool operator ==(dynamic other) {
    if (identical(this, other)) return true;
    if (other is! PreviewEditingValue) return false;
    final PreviewEditingValue typedOther = other;
    return typedOther.currentImage == currentImage &&
        typedOther.filesPath == filesPath;
  }

  @override
  int get hashCode => hashValues(currentImage.hashCode, filesPath.hashCode);
}
