import 'dart:async';
import 'dart:typed_data';

import 'package:adv_image_picker/models/album_item.dart';
import 'package:flutter/services.dart';

class AdvImagePickerPlugin {
  static const MethodChannel _channel = const MethodChannel('adv_image_picker');

  static Future<bool> getPermission() async {
    return await _channel.invokeMethod('getPermission');
  }

  static Future<List<Album>> getAlbums() async {
    final List<dynamic> images = await _channel.invokeMethod('getAlbums');
    List<Album> albums = List<Album>();
    for (var element in images) {
      albums.add(Album.fromJson(element));
    }
    return albums;
  }

  static Future<dynamic> getAlbumThumbnail(String albumId, String assetId,
      int width, int height, int quality, Function callback) async {
    assert(albumId != null);
    assert(assetId != null);
    assert(width != null);
    assert(height != null);

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

    BinaryMessages.setMessageHandler(
        'adv_image_picker/image/fetch/thumbnails/$albumId/$assetId',
        (ByteData message) {
      callback(albumId, assetId, message);
      BinaryMessages.setMessageHandler(
          'adv_image_picker/image/fetch/thumbnails/$albumId/$assetId', null);
    });

    var thumbnails =
        await _channel.invokeMethod("getAlbumThumbnail", <String, dynamic>{
      "albumId": albumId,
      "assetId": assetId,
      "width": width,
      "height": height,
      "quality": quality
    });
    return thumbnails;
  }

  static Future<dynamic> getAlbumOriginal(
      String albumId, String assetId, int quality, Function callback) async {
    assert(albumId != null);
    assert(assetId != null);

    if (quality < 0 || quality > 100) {
      throw new ArgumentError.value(
          quality, 'quality should be in range 0-100');
    }

    BinaryMessages.setMessageHandler(
        'adv_image_picker/image/fetch/original/$albumId/$assetId',
        (ByteData message) {
      callback(albumId, assetId, message);
      BinaryMessages.setMessageHandler(
          'adv_image_picker/image/fetch/original/$albumId/$assetId', null);
    });

    var thumbnails = await _channel.invokeMethod(
        "getAlbumOriginal", <String, dynamic>{
      "albumId": albumId,
      "assetId": assetId,
      "quality": quality
    });
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
