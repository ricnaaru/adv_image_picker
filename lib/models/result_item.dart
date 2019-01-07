import 'package:flutter/services.dart';

class ResultItem {
  final String filePath;
  final ByteData data;

  ResultItem(this.filePath, this.data);
}
