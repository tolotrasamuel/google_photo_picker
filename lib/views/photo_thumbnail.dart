import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class PhotoThumbnail extends StatelessWidget {
  final String? thumbnailUrl;
  const PhotoThumbnail({super.key, this.thumbnailUrl});

  @override
  Widget build(BuildContext context) {
    return _getAlbumThumbnail(thumbnailUrl);
  }

  Widget _getAlbumThumbnail(String? coverPhotoBaseUrl) {
    return Card(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minWidth: 128,
        ),
        child: Container(
          width: 128,
          height: 128,
          child: _getAlbumThumbnailImage(coverPhotoBaseUrl),
        ),
      ),
    );
  }

  Widget _getAlbumThumbnailImage(String? url) {
    if (url == null) {
      return Icon(Icons.photo);
    }
    return CachedNetworkImage(
      imageUrl: url,
      placeholder: (context, url) => Center(
        child: Container(
          height: 32,
          width: 32,
          child: CircularProgressIndicator(),
        ),
      ),
      errorWidget: (context, url, error) => Icon(Icons.error),
    );
  }
}