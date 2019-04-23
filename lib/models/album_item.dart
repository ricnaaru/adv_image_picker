import 'package:flutter/services.dart';

class Album {
  final String name;
  final String identifier;
  final int assetCount;
  final int assetSelected;
  final List<AlbumItem> items;

  Album(this.name, this.identifier, this.assetCount,
      {int assetSelected, List<AlbumItem> items})
      : this.assetSelected = assetSelected ?? 0,
        this.items = items ?? [];

  factory Album.fromJson(Map<dynamic, dynamic> raw) {
    return Album(raw["name"], raw["identifier"], raw["assetCount"]);
  }

  Album copyWith({
    String name, String identifier, int assetCount, int assetSelected, List<AlbumItem> items
  }) {
    return Album(
      name ?? this.name,
      identifier ?? this.identifier,
      assetCount ?? this.assetCount,
      assetSelected: assetSelected ?? this.assetSelected,
      items: items ?? this.items,
    );
  }
}

class AlbumItem {
  final String identifier;

  ByteData get thumbnail => _thumbnail;

  int selectionIndex = 0;

  set thumbnail(ByteData value) {
    _thumbnail = value;
  }

  ByteData _thumbnail;

  AlbumItem(this.identifier);


}
class SelectedAlbumItem {
  final String albumId;
  final String assetId;
  final ByteData thumbnail;

  SelectedAlbumItem(this.albumId, this.assetId, this.thumbnail);
}