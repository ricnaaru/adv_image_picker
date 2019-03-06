import 'dart:async';

import 'package:adv_image_picker/adv_image_picker.dart';
import 'package:adv_image_picker/models/album_item.dart';
import 'package:adv_image_picker/models/result_item.dart';
import 'package:adv_image_picker/pages/result.dart';
import 'package:adv_image_picker/plugins/adv_image_picker_plugin.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pit_components/components/adv_button.dart';
import 'package:pit_components/components/adv_future_builder.dart';

class GalleryPage extends StatefulWidget {
  final bool allowMultiple;

  GalleryPage({bool allowMultiple})
      : this.allowMultiple = allowMultiple ?? true;

  @override
  _GalleryPageState createState() => new _GalleryPageState();
}

class _GalleryPageState extends State<GalleryPage> {
  List<Album> albums;
  List<SelectedAlbumItem> _selectedImages = [];
  List<int> rows = [];
  List<String> needToBeRendered = [];
  Album _selectedAlbum;
  ScrollController _scrollController = ScrollController();
  int _gridCrossAxisCount = 3;
  double _gridPadding = 2.0;
  double _itemWidth = 0.0;
  double _itemHeight = 0.0;
  double _marginBottom = 0.0;
  BuildContext contentContext;
  String lastScroll = "";
  int batchCounter = 0;
  TaskManager taskManager;
  bool _multipleMode = false;
  GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  ValueNotifier<int> buttonController = ValueNotifier<int>(0);

  @override
  void dispose() {
    super.dispose();
    taskManager?.dispose();
  }

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      if (!_scrollController.hasClients) return;

      int visibleRowFrom =
          (_scrollController.position.pixels / _itemHeight).ceil();
      int visibleRowTo =
          ((contentContext.size.height + _scrollController.position.pixels) /
                  _itemHeight)
              .ceil();

      if (lastScroll != "$visibleRowFrom - $visibleRowTo") {
        batchCounter++;
        lastScroll = "$visibleRowFrom - $visibleRowTo";
        double batchNo =
            batchCounter.toDouble(); //_scrollController.position.pixels;
        List<LoadItem> batch = [];
        for (int i = visibleRowFrom; i <= visibleRowTo; i++) {
          for (int j = 0; j < _gridCrossAxisCount; j++) {
            int index = ((i - 1) * _gridCrossAxisCount) + j;
            if (_selectedAlbum.items.length > index &&
                index >= 0 &&
                _selectedAlbum.items[index].thumbnail == null) {
              batch.insert(
                  0,
                  LoadItem(
                      batchNo,
                      index,
                      _selectedAlbum.identifier,
                      _selectedAlbum.items[((i - 1) * _gridCrossAxisCount) + j]
                          .identifier));
            }
          }
        }
        taskManager.add(batch);
      }
    });
  }

  _thumbnailListener(String albumId, String assetId, ByteData data) {
    if (data == null) return;

    if (this.mounted) {
      setState(() {
        albums
            .firstWhere((Album loopAlbum) => loopAlbum.identifier == albumId)
            .items
            .firstWhere((AlbumItem item) => item.identifier == assetId)
            .thumbnail = data;
      });
    }
  }

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

  toggleMultipleMode() {
    if (!_multipleMode) {
      _scaffoldKey.currentState
          .showBottomSheet((BuildContext context) {
            return _SmartButton(buttonController, onPressed: () {
              List<ResultItem> images = [];

//          for (int i = _selectedImages.length - 1; i >= 0; i--) {
//            SelectedAlbumItem item = _selectedImages[i];
              for (SelectedAlbumItem item in _selectedImages) {
                images.add(ResultItem(item.albumId, item.assetId));
                AdvImagePickerPlugin.getAlbumOriginal(
                    item.albumId, item.assetId, 100, (albumId, assetId, data) {
                  images
                      .firstWhere((ResultItem loopItem) =>
                          loopItem.albumId == albumId &&
                          loopItem.filePath == assetId)
                      .data = data;

                  if (images
                          .where((ResultItem loopItem) => loopItem.data != null)
                          .length ==
                      _selectedImages.length) {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (BuildContext context) =>
                                ResultPage(images)));
                  }
                });
              }
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

  switchMultipleMode() {
    if (mounted) {
      _selectedImages.clear();
      buttonController.value = 0;

      setState(() {
        _marginBottom = _multipleMode ? 0.0 : 80.0;
        _multipleMode = !_multipleMode;
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
                    int selectedCount = _selectedImages
                        .where((item) => item.albumId == album.name)
                        .length;
                    return DropdownMenuItem(
                        child: Text(
                            "${album.name}${_multipleMode && selectedCount > 0 ? " ($selectedCount)" : ""}"),
                        value: album.name);
                  }).toList(),
            value: albums == null ? "" : _selectedAlbum.name,
            onChanged: (albumName) {
              if (albumName == null || albums.length == 0) return;

              setState(() {
                _selectedAlbum =
                    albums.firstWhere((Album album) => album.name == albumName);

                _loadAllItems();
              });
            }),
      ),
      body: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
        double mainMaxWidth = constraints.maxWidth;

        _itemWidth =
            (mainMaxWidth - ((_gridCrossAxisCount + 1) * _gridPadding)) /
                _gridCrossAxisCount;
        _itemHeight = (_itemWidth / 0.85) + _gridPadding;

        if (taskManager == null) {
          taskManager = TaskManager(
              _itemWidth.toInt() * 2, _itemWidth.toInt() * 2, 100,
              thumbnailListener: _thumbnailListener);
        }

        return AdvFutureBuilder(
          futureExecutor: _loadAll,
          widgetBuilder: _buildWidget,
        );
      }),
    );
  }

  Widget _buildWidget(BuildContext context) {
    if (albums == null) {
      return Center(child: CircularProgressIndicator());
    }

    if (_selectedAlbum == null) return Container();

    return Builder(builder: (BuildContext context) {
      contentContext = context;

      return GridView.builder(
        itemCount: _selectedAlbum.assetCount,
        controller: _scrollController,
        padding: EdgeInsets.all(_gridPadding).copyWith(bottom: _marginBottom),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: _gridCrossAxisCount,
          mainAxisSpacing: _gridPadding,
          crossAxisSpacing: _gridPadding,
          childAspectRatio: 1.0,
        ),
        itemBuilder: (BuildContext context, int index) {
          if (_selectedAlbum.items[index].thumbnail == null)
            return Container(color: AdvImagePicker.lightGrey);

          SelectedAlbumItem selectedItem = _selectedImages.length == 0
              ? null
              : _selectedImages.firstWhere(
                  (SelectedAlbumItem item) =>
                      item.albumId == _selectedAlbum.name &&
                      item.assetId == _selectedAlbum.items[index].identifier,
                  orElse: () => null);

          bool selected = selectedItem != null;

          int selectionIndex = _selectedImages.length == 0
              ? 0
              : _selectedImages.indexWhere((SelectedAlbumItem item) =>
                      item.albumId == _selectedAlbum.name &&
                      item.assetId == _selectedAlbum.items[index].identifier) +
                  1;

          return GestureDetector(
            child: Container(
              color: AdvImagePicker.lightGrey,
              child: Container(
                height: _itemWidth,
                width: _itemWidth,
                child: Stack(children: [
                  Image(
                    image: MemoryImage(_selectedAlbum
                        .items[index].thumbnail.buffer
                        .asUint8List()),
                    fit: BoxFit.cover,
                    gaplessPlayback: true,
                  ),
                  _multipleMode
                      ? Positioned(
                          child: Container(
                            margin: EdgeInsets.all(4.0),
                            alignment: Alignment.center,
                            width: 24.0,
                            height: 24.0,
                            decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                    width: 1.0,
                                    color: AdvImagePicker.accentColor),
                                color: selected
                                    ? AdvImagePicker.accentColor
                                    : Colors.white),
                            child: selected
                                ? Text(
                                    "$selectionIndex",
                                    style: TextStyle(
                                        fontSize: 14.0,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white),
                                  )
                                : null,
                          ),
                          top: 0.0,
                          right: 0.0,
                        )
                      : Container()
                ]),
              ),
            ),
            onLongPress: (widget.allowMultiple)
                ? () {
                    toggleMultipleMode();
                    if (_selectedImages.length >= AdvImagePicker.maxImage)
                      return;
                    _selectedImages.add(SelectedAlbumItem(
                        _selectedAlbum.name,
                        _selectedAlbum.items[index].identifier,
                        _selectedAlbum.items[index].thumbnail));
                    buttonController.value += 1;
                  }
                : null,
            onTap: () {
              if (_multipleMode) {
                if (selected) {
                  _selectedImages.remove(selectedItem);
                  buttonController.value -= 1;
                } else if (!selected) {
                  if (_selectedImages.length >= AdvImagePicker.maxImage) return;
                  _selectedImages.add(SelectedAlbumItem(
                      _selectedAlbum.name,
                      _selectedAlbum.items[index].identifier,
                      _selectedAlbum.items[index].thumbnail));
                  buttonController.value += 1;
                }
              } else {
                AdvImagePickerPlugin.getAlbumOriginal(
                    _selectedAlbum.identifier,
                    _selectedAlbum.items[index].identifier,
                    100, (albumId, assetId, message) {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            ResultPage([ResultItem(albumId, assetId, data: message)]),
                      ));
                });
              }
              setState(() {});
            },
          );
        },
      );
    });
  }

  _loadAllItems() {
    List<LoadItem> temp = [];
    for (int i = _selectedAlbum.items.length - 1; i >= 0; i--) {
      if (_selectedAlbum.items[i].thumbnail == null) {
        temp.add(LoadItem(0, i, _selectedAlbum.identifier,
            _selectedAlbum.items[i].identifier));
      }
    }

    taskManager.add(temp);
    temp.clear();
  }

  Future<bool> _loadAll(BuildContext context) async {
    if (albums != null) return false;

    await getAlbums();
    _selectedAlbum = albums != null && albums.length > 0 ? albums[0] : null;

    if (_selectedAlbum != null) _loadAllItems();

    return true;
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
    items.removeWhere((loopItem) =>
        loopItem.albumId == item.albumId && loopItem.assetId == item.assetId);
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
        child: AdvButton(
          "${AdvImagePicker.next} (${widget.controller.value ?? 0})",
          width: double.infinity,
          backgroundColor: AdvImagePicker.primaryColor,
          onPressed: widget.onPressed,
        ));
  }
}
