import 'package:flutter/services.dart';

class ResultItem {
  final String albumId;
  final String filePath;
  ByteData data;

  ResultItem(this.albumId, this.filePath, {this.data});
}
