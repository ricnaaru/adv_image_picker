import 'package:adv_image_picker/adv_image_picker.dart';
import 'package:adv_image_picker/models/result_item.dart';
import 'package:adv_image_picker/pages/preview.dart';
import 'package:basic_components/components/adv_button.dart';
import 'package:basic_components/components/adv_column.dart';
import 'package:basic_components/components/adv_row.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class ResultPage extends StatefulWidget {
  final List<ResultItem> images;
  final bool cameFromGallery;

  ResultPage(this.images, {this.cameFromGallery = false});

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
      body: Column(
        children: [
          Expanded(
            child: Preview(
              imagesPath: widget.images.map((ResultItem item) {
                return item.filePath;
              }).toList(),
//              imageProviders: widget.images.map((ResultItem item) {
//                File f = File(item.filePath);
//
//                Uint8List image = f.readAsBytesSync();
//
//                return MemoryImage(image);
//              }).toList(),
              currentImage: 0,
            ),
          ),
          Container(
            padding: EdgeInsets.all(8.0),
            color: Colors.white,
            child: AdvRow(
              divider: RowDivider(8.0),
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: AdvButton.custom(
                    child: AdvColumn(divider: ColumnDivider(4.0), children: [
                      Text("${AdvImagePicker.cancel}"),
                      Icon(Icons.close)
                    ]),
                    buttonSize: ButtonSize.small,
                    primaryColor: Colors.white,
                    accentColor: Colors.black87,
                    onPressed: () {
                      Navigator.pop(context);
                    },
                  ),
                ),
                Expanded(
                  child: AdvButton.custom(
                    child: AdvColumn(divider: ColumnDivider(4.0), children: [
                      Text("${AdvImagePicker.confirm}"),
                      Icon(Icons.check),
                    ]),
                    buttonSize: ButtonSize.small,
                    primaryColor: Colors.white,
                    accentColor: AdvImagePicker.primaryColor,
                    onPressed: () {
                      /*Navigator.popUntil(
                          context, ModalRoute.withName("AdvImagePickerHome"));*/
                      if (widget.cameFromGallery) {
                        // pop out of gallery
                        print('Came from gallery!, pop it off');
                        Navigator.pop(context);
                        Navigator.pop(context);
                      }
                      if (Navigator.canPop(context))
                        print('Yes, I can still pop');
                      print(
                          widget.images.length.toString() + ' images carried!');
                      Navigator.pop(context, widget.images);
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
