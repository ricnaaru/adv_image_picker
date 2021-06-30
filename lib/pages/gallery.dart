import 'dart:async';

import 'package:adv_image_picker/adv_image_picker.dart';
import 'package:adv_image_picker/models/album_item.dart';
import 'package:adv_image_picker/models/result_item.dart';
import 'package:adv_image_picker/pages/result.dart';
import 'package:adv_image_picker/plugins/adv_image_picker_plugin.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:image_list/data/media.dart';
import 'package:image_list/image_list.dart';

class GalleryPage extends StatefulWidget {
  final bool allowMultiple;
  final int? maxSize;

  GalleryPage({bool? allowMultiple, this.maxSize})
      : assert(maxSize == null || maxSize >= 0),
        this.allowMultiple = allowMultiple ?? true;

  @override
  _GalleryPageState createState() => new _GalleryPageState();
}

class _GalleryPageState extends State<GalleryPage> {
  List<Album>? albums;
  List<int> rows = [];
  List<String> needToBeRendered = [];
  Album? _selectedAlbum;
  double _marginBottom = 0.0;
  String lastScroll = "";
  int batchCounter = 0;
  ImageListController? _controller;
  bool _multipleMode = false;
  GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  ValueNotifier<int> buttonController = ValueNotifier<int>(0);

  Future<void> getAlbums() async {
    try {
      List<Album> _albums = [];

      _albums = await AdvImagePickerPlugin.getAlbums();

      for (Album album in _albums) {
        var res = await AdvImagePickerPlugin.getAlbumAssetsId(album);

        album.items.addAll(res.map<AlbumItem>((id) {
          return AlbumItem(id);
        }));
      }

      this.albums = _albums.map((Album album) {
        return album.copyWith(assetCount: album.items.length);
      }).toList();
    } on PlatformException catch (e) {
      ScaffoldMessengerState scaffoldMessenger = ScaffoldMessenger.of(context);
      if (scaffoldMessenger.mounted)
        scaffoldMessenger
            .showSnackBar(SnackBar(content: Text(e.message ?? '')));
    }
  }

  void toggleMultipleMode() {
    if (_controller == null || albums == null) return;

    if (!_multipleMode) {
      _scaffoldKey.currentState!
          .showBottomSheet((BuildContext context) {
            return _SmartButton(
              buttonController,
              onPressed: () async {
                await submit();
              },
            );
          })
          .closed
          .then((_) {
            if (this.mounted)
              setState(() {
                switchMultipleMode();
              });
          });

      switchMultipleMode();
    } else {
      Navigator.pop(context);
    }
  }

  submit() async {
    List<ResultItem> images = [];

    List<MediaData>? imageData = await _controller!.getSelectedMedia();

    if (imageData != null) {
      for (MediaData data in imageData) {
        images.add(ResultItem(data.albumId, data.assetId));
      }
    }

    Widget page = ResultPage(images);

    Navigator.push(
        context, MaterialPageRoute(builder: (BuildContext context) => page));
  }

  void switchMultipleMode() {
    buttonController.value = 0;

    _marginBottom = _multipleMode ? 0.0 : 80.0;
    _multipleMode = !_multipleMode;
    _controller!.setMaxImage(_multipleMode ? null : 1);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: new AppBar(
        elevation: 0,
        centerTitle: false,
        backgroundColor: Colors.white,
        iconTheme: IconThemeData(color: Colors.black87),
        actions: (widget.allowMultiple)
            ? [
                IconButton(
                  onPressed: () {
                    toggleMultipleMode();
                  },
                  icon: Icon(
                    _multipleMode ? Icons.photo : Icons.photo_library,
                    color: Colors.black87,
                  ),
                )
              ]
            : [],
        title: Center(
          child: DropdownButton(
            underline: Container(),
            isDense: true,
            isExpanded: true,
            items: albums == null || albums!.length == 0
                ? [DropdownMenuItem(child: Text(""), value: "")]
                : albums!.map((Album album) {
                    return DropdownMenuItem(
                        child: Text("${album.name}"), value: album.name);
                  }).toList(),
            value: albums == null || _selectedAlbum == null
                ? ""
                : _selectedAlbum!.name,
            onChanged: (albumName) {
              if (albumName == null || albums!.length == 0) return;

              setState(() {
                _selectedAlbum = albums!
                    .firstWhere((Album album) => album.name == albumName);
                _controller!.reloadAlbum(_selectedAlbum!.identifier);
              });
            },
          ),
        ),
      ),
      body: FutureBuilder(
        future: _loadAll(context),
        builder: (BuildContext context, _) => _buildWidget(context),
      ),
    );
  }

  Widget _buildWidget(BuildContext context) {
    if (albums == null) {
      return Center(child: CircularProgressIndicator());
    }

    if (_selectedAlbum == null) return Container();

    return Container(
      margin: EdgeInsets.only(bottom: _marginBottom),
      child: ImageList(
        fileNamePrefix: "asdfasdfasdf",
        albumId: _selectedAlbum!.identifier,
        maxImages: _multipleMode ? null : 1,
        onListCreated: _onListCreated,
        onImageTapped: _onImageTapped,
        types: [MediaType.image],
      ),
    );
  }

  Future<bool> _loadAll(BuildContext context) async {
    if (albums != null) return false;

    await getAlbums();
    _selectedAlbum = albums != null && albums!.length > 0 ? albums![0] : null;

    setState(() {});

    return true;
  }

  void _onListCreated(ImageListController controller) {
    _controller = controller;
  }

  void _onImageTapped(int count, List<MediaData> selectedMedias) {
    if (!_multipleMode) {
      submit();
      return;
    }

    setState(() {
      buttonController.value = count;
    });
  }
}

class _SmartButton extends StatefulWidget {
  final ValueNotifier<int> controller;
  final VoidCallback? onPressed;

  _SmartButton(this.controller, {this.onPressed});

  @override
  State<StatefulWidget> createState() => _SmartButtonState();
}

class _SmartButtonState extends State<_SmartButton> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(() {
      if (this.mounted) setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.0),
      child: FlatButton(
        child: Text(
          "${AdvImagePicker.next} (${widget.controller.value})",
          style: TextStyle(fontWeight: FontWeight.w500, color: Colors.white),
        ),
        color: AdvImagePicker.primaryColor,
        onPressed: widget.onPressed,
      ),
    );
  }
}
