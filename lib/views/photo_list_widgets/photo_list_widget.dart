import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:google_photo_picker/services/google_photo_api/google_photo_api.dart';
import 'package:google_photo_picker/views/photo_list_widgets/photo_gallery.dart';
import 'package:google_photo_picker/views/photo_thumbnail.dart';
import 'package:googleapis/photoslibrary/v1.dart';
import 'package:shared_views/utils/toast_util.dart';
import 'package:shared_views/views/photo_viewer/photo_viewer_widget.dart';
import 'package:shared_views/views/photoviewer_gallery/photoviewer_gallery.dart';
import 'package:shared_views/views/refreshable_list/refreshable_list.dart';
import 'package:shared_views/views/short_text_input_dialog.dart';

class PhotoListWidget extends StatefulWidget {
  final String albumId;
  const PhotoListWidget({super.key, required this.albumId});

  @override
  State<PhotoListWidget> createState() => _PhotoListWidgetState();
}

enum SortBy {
  dateAsc,
  dateDesc,
  rankAsc,
  rankDesc,
}

enum MediaActions implements BaseAction {
  removeFromAlbum("Remove from Album"),
  undelete("Undelete");

  final String label;
  final Color? color;
  const MediaActions(this.label, {this.color});
}

enum AlbumActions implements BaseAction {
  duplicate("Duplicate Album"),
  selectRanking("Select Ranking"),
  viewInGooglePhoto("View in Google Photo"),
  viewDeleted("View Deleted"); // show undelete button

  final String label;
  final Color? color;
  const AlbumActions(this.label, {this.color});
}

class _PhotoListWidgetState extends State<PhotoListWidget> {
  final _photoApi = GooglePhotoApi();
  final List<MediaItem> items = [];

  Album? album;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    items.clear();
    await fetchRanking();
    await fetchAlbum();
    final List<MediaItem> medias;


    // items.addAll(medias);
    setState(() {});
    return;
  }

  Future<void> fetchAlbum() async {
    setState(() {});
    return;
  }

  Future<void> fetchRanking() async {
    setState(() {});
    return;
  }

  void _viewPhoto(String media1url) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(),
          body: PhotoViewerWidget(
            imageUrl: media1url,
          ),
        ),
      ),
    );
  }

  Widget buildRankingTile(List<String> ranking, String title) {
    return ListTile(
      title: Text(title),
      onTap: () {
        Navigator.of(context).pop(ranking);
      },
    );
  }


  List<String> _getPhotoUrlList() {
    final imageUrls = items
        .map((e) => e.baseUrl)
        .whereType<String>()
        .map(_photoApi.getOriginalSizeUrl)
        .toList();
    return imageUrls;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(album?.title ?? ""),
        actions: [
          IconButton(
              onPressed: () {
                _viewPhotoInGallery(0);
                // _viewPhoto(media1url
              },
              icon: Icon(Icons.photo_library)),
          IconButton(
            onPressed: () async {
              final album = this.album;
              if (album == null) return;
              _onMoreTapped(album);
            },
            icon: Icon(Icons.more_vert),
          ),
        ],
      ),
      body: Column(
        children: [
          // DropdownButtonFormField<SortBy>(
          //   value: SortBy.rankAsc,
          //   onChanged: (value) {
          //     activityForm.activityStatus = value ?? ActivityStatus.todo;
          //     setState(() {});
          //   },
          //   items: SortBy.values
          //       .map(
          //         (e) => DropdownMenuItem(
          //           value: e,
          //           child: Text(e.label),
          //         ),
          //       )
          //       .toList(),
          //   decoration: InputDecoration(
          //     labelText: 'Activity Status',
          //     border: OutlineInputBorder(),
          //   ),
          // ),
          Expanded(
            child: RefreshableWidget(
              onRefresh: _reload,
              noResultMessage: "No Media found",
              isEmpty: items.isEmpty,
              scrollableView: ListView.builder(
                itemBuilder: (context, index) {
                  final media = items[index];
                  final url = media.baseUrl;
                  if (url == null) return Container();
                  final thumbnailUrl = _photoApi.getThumbnailUrl(url);
                  // print(thumbnailUrl);
                  return InkWell(
                    onLongPress: () {
                      // _onMediaTileLongPressed(media);
                    },
                    onTap: () async {
                      final baseUrl = media.baseUrl;
                      if (baseUrl == null) return;
                      final originalUrl = _photoApi.getOriginalSizeUrl(baseUrl);
                      // _viewPhoto(originalUrl);
                      _viewPhotoInGallery(index);
                    },
                    child: Row(
                      children: [
                        PhotoThumbnail(
                          thumbnailUrl: thumbnailUrl,
                        ),
                        Text("${media.filename}"),
                      ],
                    ),
                  );
                },
                itemCount: items.length,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _onMoreTapped(Album activityFeed) async {
    final actions = [
      // AlbumActions.duplicate,
      AlbumActions.viewInGooglePhoto,
      AlbumActions.selectRanking,
      AlbumActions.viewDeleted,
    ];

    final action = await ToastUtil.moreTappedDialog(actions, context);
    if (action is! AlbumActions) return;
    switch (action) {
      case AlbumActions.duplicate:
        _onDuplicate(activityFeed);
        break;

      case AlbumActions.viewInGooglePhoto:
        _onViewInGooglePhoto(activityFeed);
        break;

      case AlbumActions.selectRanking:
        _onSelectRanking();
        break;

      case AlbumActions.viewDeleted:
        _onViewDeleted();
        break;
      default:
        break;
    }
  }

  Future<void> _onDuplicate(Album activityFeed) async {
    final name = await ShortInputDialog.promptScheduleName(
      context,
     title: "${activityFeed.title} - Copy",
    );
    if (name == null) return;
    final albumId = activityFeed.id;
    if (albumId == null) return;
    final result = await _photoApi.duplicateAlbum(albumId, name);
    await _reload();
  }

  void _onViewInGooglePhoto(Album activityFeed) {
    final url = activityFeed.productUrl;
    if (url == null) return;
    final uri = Uri.parse(url);
    launchUrl(uri);
  }

  final List<String> debugRanking = [];
  Future<void> _onSelectRanking() async {
    final result = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        insetPadding: EdgeInsets.symmetric(horizontal: 16),
        title: Text("Ranking"),
        content: Container(
          width: double.maxFinite,
        ),
      ),
    );
    if (result is! List<String>) {
      return;
    }
    debugRanking.clear();
    debugRanking.addAll(result);
    _reload();
  }

  Future<void> _onViewDeleted() async {
    _reload();
  }


  void _viewPhotoInGallery(int index) {
    final imageUrls = _getPhotoUrlList();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) =>
            PhotoGalleryWidget(imageUrls: imageUrls, initialIndex: index),
      ),
    );
  }
}
