import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class PhotoThumbnail extends StatelessWidget {
  final String? thumbnailUrl;
  final double? size;

  const PhotoThumbnail({
    super.key,
    this.thumbnailUrl,
    this.size,
  });

  @override
  Widget build(BuildContext context) {
    return _getAlbumThumbnail(thumbnailUrl);
  }

  Widget _getAlbumThumbnail(String? coverPhotoBaseUrl) {
    return Card(
      margin: EdgeInsets.zero,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minWidth: 128,
        ),
        child: Container(
          width: size,
          height: size,
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
      fit: BoxFit.fitWidth,
      height: size,
      // width: 128,
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
