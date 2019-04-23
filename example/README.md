```
import 'dart:io';

import 'package:adv_image_picker/adv_image_picker.dart';
import 'package:flutter/material.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
 // This widget is the root of your application.
 @override
 Widget build(BuildContext context) {
   return MaterialApp(
     title: 'Flutter Demo',
     theme: ThemeData(
       primarySwatch: Colors.blue,
     ),
     home: MyHomePage(title: 'Image Picker Demo Home Page'),
   );
 }
}

class MyHomePage extends StatefulWidget {
 MyHomePage({Key key, this.title}) : super(key: key);

 final String title;

 @override
 _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
 int _counter = 0;
 List<File> files = [];

 void _pickImage() async {
   files.addAll(await AdvImagePicker.pickImagesToFile(context));

   setState(() {

   });
 }

 @override
 Widget build(BuildContext context) {
   return Scaffold(
     appBar: AppBar(
       title: Text(widget.title),
     ),
     body: Center(
       child: GridView.count(crossAxisCount: 4,
         children: files.map((File f) => Image.file(f, fit: BoxFit.cover,)).toList(),
       ),
     ),
     floatingActionButton: FloatingActionButton(
       onPressed: _pickImage,
       child: Icon(Icons.add),
     ),
   );
 }
}
```