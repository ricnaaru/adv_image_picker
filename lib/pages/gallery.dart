import 'dart:async';

import 'package:adv_image_picker/adv_image_picker.dart';
import 'package:adv_image_picker/models/album_item.dart';
import 'package:adv_image_picker/models/result_item.dart';
import 'package:adv_image_picker/pages/result.dart';
import 'package:adv_image_picker/plugins/adv_future_builder.dart';
import 'package:adv_image_picker/plugins/adv_image_picker_plugin.dart';
import 'package:basic_components/components/adv_button.dart';
import 'package:basic_components/components/adv_loading_with_barrier.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:image_list/image_list.dart';

class GalleryPage extends StatefulWidget {
  final bool allowMultiple;
  final int maxSize;

  GalleryPage({bool allowMultiple, this.maxSize})
      : assert(maxSize == null || maxSize >= 0),
        this.allowMultiple = allowMultiple ?? true;

  @override
  _GalleryPageState createState() => new _GalleryPageState();
}

class _GalleryPageState extends State<GalleryPage> {
  List<Album> albums;
  int _selectedImageCount = 0;
  List<int> rows = [];
  List<String> needToBeRendered = [];
  Album _selectedAlbum;
  double _marginBottom = 0.0;
  BuildContext contentContext;
  String lastScroll = "";
  int batchCounter = 0;
  ImageListController _controller;
  bool _multipleMode = false;
  bool _processing = false;
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
        _scaffoldKey.currentState?.showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  toggleMultipleMode() {
    if (!_multipleMode) {
      _scaffoldKey.currentState
          .showBottomSheet((BuildContext context) {
            return _SmartButton(buttonController, onPressed: () async {
              if (_processing) return;

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
  }

  submit() async {
    setState(() {
      _processing = true;
    });

    List<ResultItem> images = [];

    List<ImageData> imageData = await _controller.getSelectedImage();

    for (ImageData data in imageData) {
      images.add(ResultItem(data.albumId, data.assetId));

      AdvImagePickerPlugin.getAlbumOriginal(data.albumId, data.assetId, 100,
          (albumId, assetId, data) {
        images
            .firstWhere((ResultItem loopItem) =>
                loopItem.albumId == albumId && loopItem.filePath == assetId)
            .data = data;

        if (images.where((ResultItem loopItem) => loopItem.data != null).length ==
            _selectedImageCount) {
          setState(() {
            _processing = false;
          });

          var page = ResultPage(images);
          Navigator.push(context, MaterialPageRoute(builder: (BuildContext context) => page));
        }
      }, maxSize: widget.maxSize);
    }
  }

  switchMultipleMode() {
    if (mounted) {
      _selectedImageCount = 0;
      buttonController.value = 0;

      setState(() {
        _marginBottom = _multipleMode ? 0.0 : 80.0;
        _multipleMode = !_multipleMode;
        _controller.setMaxImage(_multipleMode ? null : 1);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: new AppBar(
        elevation: 0.0,
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
        title: DropdownButton(
            isDense: true,
            items: albums == null || albums.length == 0
                ? [DropdownMenuItem(child: Text(""), value: "")]
                : albums.map((Album album) {
                    return DropdownMenuItem(child: Text("${album.name}"), value: album.name);
                  }).toList(),
            value: albums == null || _selectedAlbum == null ? "" : _selectedAlbum.name,
            onChanged: (albumName) {
              if (albumName == null || albums.length == 0) return;

              setState(() {
                _selectedAlbum = albums.firstWhere((Album album) => album.name == albumName);
              });

              _controller.reloadAlbum(_selectedAlbum.identifier);
            }),
      ),
      body: AdvLoadingWithBarrier(
        isProcessing: _processing,
        content: (BuildContext context) => AdvFutureBuilder(
              futureExecutor: _loadAll,
              widgetBuilder: _buildWidget,
            ),
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
    _selectedImageCount = count;

    if (!_multipleMode) {
      submit();
      return;
    }

    setState(() {
      buttonController.value = count;
    });
  }
}

class LoadItem {
  final double batchId;
  final int index;
  final String albumId;
  final String assetId;

  LoadItem(this.batchId, this.index, this.albumId, this.assetId);
}

class TaskManager {
  List<LoadItem> items = [];
  int counter = 0;
  int maxCounter = 1;
  final int width;
  final int height;
  final int quality;
  final Function thumbnailListener;
  String renderingItems = "";

  TaskManager(this.width, this.height, this.quality, {this.thumbnailListener});

  void add(List<LoadItem> loadItems) {
    for (LoadItem i in loadItems) remove(LoadItem(0, 0, i.albumId, i.assetId));

    items.addAll(loadItems);
    LoadItem idleBatch = items.lastWhere(
        (loopItem) => renderingItems.indexOf("[${loopItem.assetId}]") == -1,
        orElse: () => null);

    if (counter < maxCounter && idleBatch != null) {
      counter++;
      renderingItems += "[${idleBatch.assetId}]";
      _tryRender(idleBatch);
    }
  }

  void remove(LoadItem item) {
    items.removeWhere(
        (loopItem) => loopItem.albumId == item.albumId && loopItem.assetId == item.assetId);
  }

  _tryRender(LoadItem item) {
    AdvImagePickerPlugin.getAlbumThumbnail(
        item.albumId, item.assetId, this.width, this.height, this.quality,
        (albumId, assetId, data) {
      if (thumbnailListener != null) thumbnailListener(albumId, assetId, data);

      remove(LoadItem(0, 0, albumId, assetId));
      renderingItems = renderingItems.replaceAll("[$assetId]", "");
      counter--;

      LoadItem idleBatch = items.lastWhere(
          (loopItem) => renderingItems.indexOf("[${loopItem.assetId}]") == -1,
          orElse: () => null);

      if (counter < maxCounter && idleBatch != null) {
        counter++;
        renderingItems += "[${idleBatch.assetId}]";
        _tryRender(idleBatch);
      }
    });
  }

  void dispose() {
    items.clear();
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
        ));
  }
}
