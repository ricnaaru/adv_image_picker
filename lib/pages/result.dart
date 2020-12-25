
import 'package:adv_image_picker/adv_image_picker.dart';
import 'package:adv_image_picker/models/result_item.dart';
import 'package:adv_image_picker/pages/preview.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

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
      body: Column(
        children: [
          Expanded(
            child: Preview(
              imagesPath: widget.images.map((ResultItem item) {
                return item.filePath;
              },).toList(),
              currentImage: 0,
            ),
          ),
          Container(
            padding: EdgeInsets.all(8.0),
            color: Colors.white,
            child: Row(
              // divider: RowDivider(8.0),
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Center(
                    child: FlatButton(
                      child: Padding(
                        padding: EdgeInsets.all(8),
                        child: Column(
                          children: [
                            Text("${AdvImagePicker.cancel}"),
                            SizedBox(height: 4),
                            Icon(Icons.close)
                          ],
                        ),
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                      },
                    ),
                  ),
                ),
                Expanded(
                  child: Center(
                    child: FlatButton(
                      minWidth: 0,
                      child: Padding(
                        padding: EdgeInsets.all(8),
                        child: Column(
                          children: [
                            Text("${AdvImagePicker.confirm}"),
                            SizedBox(height: 4),
                            Icon(Icons.check),
                          ],
                        ),
                      ),
                      onPressed: () {
                        Navigator.popUntil(
                            context, ModalRoute.withName("AdvImagePickerHome"));
                        if (Navigator.canPop(context))
                          Navigator.pop(context, widget.images);
                      },
                    ),
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
