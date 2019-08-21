import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:pit_components/components/adv_row.dart';
import 'package:pit_components/components/adv_visibility.dart';
import 'package:pit_components/pit_components.dart';

class Preview extends StatefulWidget {
  final PreviewController controller;
  final double height;

  Preview(
      {double height,
        int currentImage,
        List<ImageProvider> imageProviders,
        PreviewController controller})
      : assert(controller == null ||
      (currentImage == null && imageProviders == null)),
        this.height = height ?? 250.0,
        this.controller = controller ??
            PreviewController(
                currentImage: currentImage ?? 0,
                imageProviders: imageProviders ?? const []);

  @override
  _PreviewState createState() => new _PreviewState();
}

class _PreviewState extends State<Preview> {
  @override
  void initState() {
    super.initState();

    widget.controller.addListener(() {
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> children = [];
    final PreviewController controller = widget.controller;

    children.add(Expanded(
        child: ClipRect(
          child: PhotoView(
            backgroundDecoration: BoxDecoration(
                color: Colors.black.withBlue(60).withGreen(60).withRed(60)),
            imageProvider:
            widget.controller.imageProviders[widget.controller.currentImage],
            maxScale: PhotoViewComputedScale.covered * 2.0,
            minScale: PhotoViewComputedScale.contained * 0.8,
            initialScale: PhotoViewComputedScale.covered,
          ),
        )));

    if (controller.imageProviders.length > 1) {
      List<Widget> thumbnails = [];

      for (int i = 0; i < controller.imageProviders.length; i++) {
        Widget image = Container(
          child: Image(
            image: controller.imageProviders[i],
            fit: BoxFit.cover,
          ),
          color: Colors.black,
          height: widget.height / 5,
          width: widget.height / 5,
        );

        thumbnails.add(InkWell(
            onTap: () {
              print("i => $i");
              setState(() {
                controller.currentImage = i;
              });
            },
            child: Stack(children: [
              image,
              AdvVisibility(
                child: Positioned(
                  bottom: 0.0,
                  left: 0.0,
                  right: 0.0,
                  height: widget.height / 100,
                  child:
                  Container(color: PitComponents.selectedImagePreviewColor),
                ),
                visibility: i == controller.currentImage
                    ? VisibilityFlag.visible
                    : VisibilityFlag.gone,
              )
            ])));
      }

      Widget rowOfThumbnails = SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: AdvRow(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.start,
              padding: EdgeInsets.symmetric(vertical: 4.0),
              divider: RowDivider(4.0),
              children: thumbnails));

      children.add(rowOfThumbnails);
    }

    return Container(
        width: double.infinity,
        height: widget.height,
        child: Column(
          children: children,
          mainAxisSize: MainAxisSize.max,
        ),
        color: Colors.black.withBlue(30).withGreen(30).withRed(30));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    print("ImageWithThumbnail didChangeDependencies");
  }
}

class PreviewController
    extends ValueNotifier<PreviewEditingValue> {
  int get currentImage => value.currentImage;

  set currentImage(int newCurrentImage) {
    value = value.copyWith(
        currentImage: newCurrentImage, imageProviders: this.imageProviders);
  }

  List<ImageProvider> get imageProviders => value.imageProviders;

  set imageProviders(List<ImageProvider> newImageProviders) {
    value = value.copyWith(
        currentImage: this.currentImage, imageProviders: newImageProviders);
  }

  PreviewController(
      {int currentImage, List<ImageProvider> imageProviders})
      : super(currentImage == null && imageProviders == null
      ? PreviewEditingValue.empty
      : new PreviewEditingValue(
      currentImage: currentImage, imageProviders: imageProviders));

  PreviewController.fromValue(PreviewEditingValue value)
      : super(value ?? PreviewEditingValue.empty);

  void clear() {
    value = PreviewEditingValue.empty;
  }
}

@immutable
class PreviewEditingValue {
  const PreviewEditingValue(
      {int currentImage, List<ImageProvider> imageProviders = const []})
      : this.currentImage = currentImage ?? 0,
        this.imageProviders = imageProviders ?? const [];

  final int currentImage;
  final List<ImageProvider> imageProviders;

  static const PreviewEditingValue empty =
  const PreviewEditingValue();

  PreviewEditingValue copyWith(
      {int currentImage, List<ImageProvider> imageProviders}) {
    return new PreviewEditingValue(
        currentImage: currentImage ?? this.currentImage,
        imageProviders: imageProviders ?? this.imageProviders);
  }

  PreviewEditingValue.fromValue(PreviewEditingValue copy)
      : this.currentImage = copy.currentImage,
        this.imageProviders = copy.imageProviders;

  @override
  String toString() => '$runtimeType(currentImage: \u2524$currentImage\u251C, '
      'imageProviders: \u2524$imageProviders\u251C)';

  @override
  bool operator ==(dynamic other) {
    if (identical(this, other)) return true;
    if (other is! PreviewEditingValue) return false;
    final PreviewEditingValue typedOther = other;
    return typedOther.currentImage == currentImage &&
        typedOther.imageProviders == imageProviders;
  }

  @override
  int get hashCode =>
      hashValues(currentImage.hashCode, imageProviders.hashCode);
}
