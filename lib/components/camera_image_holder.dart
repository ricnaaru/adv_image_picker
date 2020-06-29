import 'package:flutter/material.dart';

class CameraImageHolder extends StatefulWidget {
  final bool isCover;
  final Widget child;
  CameraImageHolder({Key key, this.isCover, @required this.child})
      : super(key: key);

  @override
  _CameraImageHolderState createState() => _CameraImageHolderState();
}

class _CameraImageHolderState extends State<CameraImageHolder> {
  Widget get child => widget.child;

  @override
  Widget build(BuildContext context) {
    double _imageHolderHW = MediaQuery.of(context).size.width / 7;

    return Padding(
      padding: const EdgeInsets.all(1),
      child: Card(
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        child: Container(
          height: _imageHolderHW,
          width: _imageHolderHW,
          //color: Colors.white,
          /* decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              color: Colors.black.withAlpha(50),
            ),
          ),*/
          child: child,
        ),
      ),
    );
  }
}
