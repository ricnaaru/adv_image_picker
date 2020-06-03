import 'dart:async';
import 'dart:typed_data';

import 'package:adv_image_picker/models/album_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AdvImagePickerPlugin {
  static const MethodChannel _channel = const MethodChannel('adv_image_picker');

  static Future<bool> getIosStoragePermission() async {
    bool result = await _channel.invokeMethod("getIosStoragePermission");
    return result;
  }

  static Future<bool> getPermission() async {
    return await _channel.invokeMethod('getPermission');
  }

  static Future<dynamic> getAlbums() async {
    final List<dynamic> images = await _channel.invokeMethod('getAlbums');
    List<Album> albums = List<Album>();
    for (var element in images) {
      albums.add(Album.fromJson(element));
    }
    return albums;
  }

  static Future<ByteData> getAlbumThumbnail({
    @required String imagePath,
    @required int width,
    @required int height,
    int quality = 100,
  }) async {
    assert(imagePath != null);
    assert(width != null);
    assert(height != null);

    Completer<ByteData> completer = Completer<ByteData>();

    if (width != null && width < 0) {
      throw new ArgumentError.value(width, 'width cannot be negative');
    }

    if (height != null && height < 0) {
      throw new ArgumentError.value(height, 'height cannot be negative');
    }

    if (quality < 0 || quality > 100) {
      throw new ArgumentError.value(
          quality, 'quality should be in range 0-100');
    }

    ServicesBinding.instance.defaultBinaryMessenger.setMessageHandler(
      'adv_image_picker/image/fetch/thumbnails/$imagePath',
      (ByteData message) {
        ServicesBinding.instance.defaultBinaryMessenger.setMessageHandler(
            'adv_image_picker/image/fetch/thumbnails/$imagePath', null);
        completer.complete(message);
        return null;
      },
    );

    await _channel.invokeMethod(
      "getAlbumThumbnail",
      <String, dynamic>{
        "imagePath": imagePath,
        "width": width,
        "height": height,
        "quality": quality
      },
    );

    return completer.future;
  }

  static Future<dynamic> getAlbumOriginal(
    String imagePath,
    int quality,
    Function callback, {
    int maxSize,
  }) async {
    assert(imagePath != null);

    if (quality < 0 || quality > 100) {
      throw new ArgumentError.value(
          quality, 'quality should be in range 0-100');
    }

    ServicesBinding.instance.defaultBinaryMessenger.setMessageHandler(
      'adv_image_picker/image/fetch/original/$imagePath',
      (ByteData message) {
        callback(imagePath, message);
        ServicesBinding.instance.defaultBinaryMessenger.setMessageHandler(
            'adv_image_picker/image/fetch/original/$imagePath', null);

        return null;
      },
    );

    Map<String, dynamic> param = <String, dynamic>{
      "imagePath": imagePath,
      "quality": quality
    };

    if (maxSize != null) param.putIfAbsent("maxSize", () => maxSize);

    var thumbnails = await _channel.invokeMethod("getAlbumOriginal", param);
    return thumbnails;
  }

  static Future<List<String>> getAlbumAssetsId(Album albumItem) async {
    assert(albumItem != null);

    var assets = await _channel.invokeMethod(
        "getAlbumAssetsId", <String, dynamic>{"albumName": albumItem.name});

    return assets.map<String>((asset) {
      return asset.toString();
    }).toList();
  }
}
