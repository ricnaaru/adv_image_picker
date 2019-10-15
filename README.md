# Advanced Image Picker

This is our custom Image Picker that enabling you to multi pick image with our Custom UI

*Note*: This plugin is still under development, and some Components might not be available yet or still has so many bugs.
- Known bug, Flutter Native View will error when orientation changes

## Installation

First, add `adv_image_picker` as a [dependency in your pubspec.yaml file](https://flutter.io/platform-plugins/).

```
adv_image_picker: ^0.2.1
```

## Example
```
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
