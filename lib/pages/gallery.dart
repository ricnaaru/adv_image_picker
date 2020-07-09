import 'dart:async';
import 'dart:io';

import 'package:adv_image_picker/adv_image_picker.dart';
import 'package:adv_image_picker/components/adv_state.dart';
import 'package:adv_image_picker/models/album_item.dart';
import 'package:adv_image_picker/models/result_item.dart';
import 'package:adv_image_picker/pages/result.dart';
import 'package:adv_image_picker/plugins/adv_future_builder.dart';
import 'package:adv_image_picker/plugins/adv_image_picker_plugin.dart';
import 'package:basic_components/components/adv_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:image_list/image_list.dart';

class GalleryPage extends StatefulWidget {
  final bool allowMultiple;
  final int maxSize;
  final List<File> files;
  final int maxImages;

  GalleryPage({bool allowMultiple, this.maxSize, this.maxImages, this.files})
      : assert(maxSize == null || maxSize >= 0),
        this.allowMultiple = allowMultiple ?? true;

  @override
  _GalleryPageState createState() => new _GalleryPageState();
}

class _GalleryPageState extends AdvState<GalleryPage> {
  List<Album> albums;
  List<int> rows = [];
  List<String> needToBeRendered = [];
  Album _selectedAlbum;
  double _marginBottom = 0.0;
  BuildContext contentContext;
  String lastScroll = "";
  int batchCounter = 0;
  ImageListController _controller;
  bool _multipleMode = true;
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
      if (_scaffoldKey.currentState.mounted)
        _scaffoldKey.currentState
            ?.showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  /*toggleMultipleMode() {
    if (_controller == null || albums == null) return;

    if (!_multipleMode) {
      _scaffoldKey.currentState
          .showBottomSheet((BuildContext context) {
            return _SmartButton(buttonController, onPressed: () async {
              await submit();
            });
          })
          .closed
          .then((_) {
            switchMultipleMode();
          });
      switchMultipleMode();
    } else {
      Navigator.pop(context);
    }
  }*/

  submit() {
    process(() async {
      List<ResultItem> images = [];

      List<ImageData> imageData = await _controller.getSelectedImage();

      for (ImageData data in imageData) {
        images.add(ResultItem(data.albumId, data.assetId));
      }

      var page = ResultPage(images, cameFromGallery: true);

      Navigator.push(
          context, MaterialPageRoute(builder: (BuildContext context) => page));
    });
  }

  void showInSnackBar(String message) {
    _scaffoldKey.currentState.showSnackBar(SnackBar(content: Text(message)));
  }

  switchMultipleMode() {
    if (mounted) {
      buttonController.value = 0;

      setState(() {
        _marginBottom = _multipleMode ? 0.0 : 80.0;
        _multipleMode = !_multipleMode;
        _controller.setMaxImage(_multipleMode ? null : 1);
      });
    }
  }

  @override
  Widget buildView(BuildContext context) {
    /*if (mounted) {
      buttonController.value = 0;

      //setState(() {
      //_marginBottom = _multipleMode ? 0.0 : 80.0;
      _multipleMode = true;
      _controller.setMaxImage(_multipleMode ? null : 1);
      //});
    }*/
    return Scaffold(
      key: _scaffoldKey,
      appBar: new AppBar(
        elevation: 0.0,
        centerTitle: false,
        backgroundColor: Colors.white,
        iconTheme: IconThemeData(color: Colors.black87),
        title: DropdownButton(
            isDense: true,
            items: albums == null || albums.length == 0
                ? [DropdownMenuItem(child: Text(""), value: "")]
                : albums.map((Album album) {
                    return DropdownMenuItem(
                        child: Text("${album.name}"), value: album.name);
                  }).toList(),
            value: albums == null || _selectedAlbum == null
                ? ""
                : _selectedAlbum.name,
            onChanged: (albumName) {
              if (albumName == null || albums.length == 0) return;

              setState(() {
                _selectedAlbum =
                    albums.firstWhere((Album album) => album.name == albumName);
              });

              _controller.reloadAlbum(_selectedAlbum.identifier);
            }),
      ),
      body: AdvFutureBuilder(
        futureExecutor: _loadAll,
        widgetBuilder: _buildWidget,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await submit();
        },
        label: Text('Continue (${buttonController.value ?? 0})'),
        icon: Icon(Icons.arrow_forward),
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
        albumId: _selectedAlbum.identifier,
        maxImages: _multipleMode ? null : 1,
        onListCreated: _onListCreated,
        onImageTapped: _onImageTapped,
      ),
    );
  }

  Future<bool> _loadAll(BuildContext context) async {
    if (albums != null) return false;

    await getAlbums();
    _selectedAlbum = albums != null && albums.length > 0 ? albums[0] : null;

    setState(() {});

    return true;
  }

  void _onListCreated(ImageListController controller) {
    _controller = controller;
  }

  void _onImageTapped(int count) {
    if (widget.files.length == 10) {
      showInSnackBar('Maximum images reached!');
    }
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
  final VoidCallback onPressed;

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
      padding: EdgeInsets.all(16.0),
      child: AdvButton.text(
        "${AdvImagePicker.next} (${widget.controller.value ?? 0})",
        width: double.infinity,
        backgroundColor: AdvImagePicker.primaryColor,
        onPressed: widget.onPressed,
      ),
    );
  }
}
