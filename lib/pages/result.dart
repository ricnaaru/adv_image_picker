import 'package:adv_image_picker/adv_image_picker.dart';
import 'package:adv_image_picker/models/result_item.dart';
import 'package:flutter/material.dart';
import 'package:pit_components/components/adv_button.dart';
import 'package:pit_components/components/adv_image_preview.dart';
import 'package:pit_components/components/adv_row.dart';

class ResultPage extends StatefulWidget {
  final List<ResultItem> images;

  ResultPage(this.images);

  @override
  State<StatefulWidget> createState() => _ResultPageSate();
}

class _ResultPageSate extends State<ResultPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(
            "${AdvImagePicker.confirmation}",
            style: TextStyle(color: Colors.black87),
          ),
          centerTitle: true,
          elevation: 0.0,
          backgroundColor: Colors.white,
          iconTheme: IconThemeData(color: Colors.black87),
        ),
//        bottomSheet: Container(child: Row,),
        body: Column(children: [
          Expanded(
              child: Container(
                  child: AdvImagePreview(
            imageProviders: widget.images.map((ResultItem item) {
//            return Image.memory(image.buffer.asUint8List(), fit: BoxFit.cover,);
              return MemoryImage(item.data.buffer.asUint8List());
//            return ClipRect(
//              child: PhotoView(
//                imageProvider: MemoryImage(image.buffer.asUint8List()),
//                maxScale: PhotoViewComputedScale.covered * 2.0,
//                minScale: PhotoViewComputedScale.contained * 0.8,
//                initialScale: PhotoViewComputedScale.covered,
//              ),
//            );
            }).toList(),
            currentImage: 0,
          ))),
          Container(
              padding: EdgeInsets.all(8.0),
              color: Colors.white,
              child: AdvRow(
                  divider: RowDivider(8.0),
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: AdvButtonWithIcon(
                        "${AdvImagePicker.cancel}",
                        Icon(Icons.close),
                        Axis.vertical,
                        buttonSize: ButtonSize.small,
                        backgroundColor: Colors.white,
                        textColor: Colors.black87,
                        onPressed: () {
                          Navigator.pop(context);
                        },
                      ),
                    ),
                    Expanded(
                      child: AdvButtonWithIcon(
                        "${AdvImagePicker.confirm}",
                        Icon(Icons.check),
                        Axis.vertical,
                        buttonSize: ButtonSize.small,
                        backgroundColor: Colors.white,
                        textColor: AdvImagePicker.primaryColor,
                        onPressed: () {
                          Navigator.popUntil(
                              context, ModalRoute.withName("AdvImagePickerHome"));
                          if (Navigator.canPop(context))
                            Navigator.pop(context, widget.images);
                        },
                      ),
                    ),
                  ])),
        ]));
  }
}
