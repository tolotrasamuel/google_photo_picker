import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:google_photo_picker/services/google_photo_api/google_photo_api.dart';
import 'package:google_photo_picker/views/photo_list_widgets/photo_gallery.dart';
import 'package:google_photo_picker/views/photo_thumbnail.dart';
import 'package:googleapis/photoslibrary/v1.dart';
import 'package:shared_views/utils/extensions/build_context_extensions.dart';
import 'package:shared_views/utils/toast_util.dart';
import 'package:shared_views/views/load_more_on_scroll_widget.dart';
import 'package:shared_views/views/photo_viewer/photo_viewer_widget.dart';
import 'package:shared_views/views/photoviewer_gallery/photoviewer_gallery.dart';

///Users/samuel/StudioProjects/shared_views/lib/views/photo_viewer/single_photo_picker_widget.dart
import 'package:shared_views/views/photo_viewer/single_photo_picker_widget.dart';
import 'package:shared_views/views/refreshable_list/refreshable_list.dart';
import 'package:shared_views/views/short_text_input_dialog.dart';
import 'package:url_launcher/url_launcher.dart';

class PhotoListWidget extends StatefulWidget {
  final bool pickerMode;
  final String albumId;

  const PhotoListWidget({
    super.key,
    required this.albumId,
    this.pickerMode = false,
  });

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
  viewInGooglePhoto("View Album in Google Photo");

  final String label;
  final Color? color;

  const AlbumActions(this.label, {this.color});
}

class _PhotoListWidgetState extends State<PhotoListWidget> {
  final _photoApi = GooglePhotoApi();
  final List<MediaItem> items = [];

  Album? album;

  SearchMediaItemsResponse? lastResults;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    items.clear();
    await fetchAlbum();
    final List<MediaItem> medias;

    // items.addAll(medias);
    setState(() {});
    return;
  }

  Future<void> fetchAlbum() async {
    album = await _photoApi.getAlbumById(widget.albumId);
    setState(() {});
    return;
  }

  Future<void> _viewPhoto(MediaItem media) async {
    final baseUrl = media.baseUrl;
    if (baseUrl == null) return;
    final originalUrl = _photoApi.getOriginalSizeUrl(baseUrl);

    final videoInfo = media.mediaMetadata?.video;
    final pickedUrl = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => SinglePhotoPickerWidget(
          imageUrl: originalUrl,
          showPicker: widget.pickerMode,
          // description: videoInfo?.toString(),
          label: "Use this ${videoInfo == null ? "photo" : "video"}",
        ),
      ),
    );
    print("is picker Mode ${widget.pickerMode}");
    if (pickedUrl != true) return;
    if (!widget.pickerMode) return;
    Navigator.of(context).pop(media.id);
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
            icon: Icon(
              Icons.photo_library,
            ),
          ),
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
          Expanded(
            child: LoadMoreOnScrollWidget<MediaItem>(
              viewType: ViewType.grid,
              gridCount: () {
                const itemSize = 256;
                final screenWidth = context.mediaSize.width;
                return screenWidth ~/ itemSize;
              },
              fetchMore: () async {
                final albumId = widget.albumId;
                final pageToken = lastResults?.nextPageToken;
                print("Fetching album $albumId");
                final results = await _photoApi.fetchNextPageContent(
                  albumId: albumId,
                  pageToken: pageToken,
                );
                lastResults = results;
                return results.mediaItems ?? [];
              },
              items: items,
              noResultMessage: "No Media found",
              reset: _reload,
              builder: (media) {
                final url = media.baseUrl;
                if (url == null) return Container();
                final thumbnailUrl = _photoApi.getThumbnailUrl(url);
                // print(thumbnailUrl);
                return InkWell(
                  onLongPress: () {
                    // _onMediaTileLongPressed(media);
                    final baseUrl = media.baseUrl;
                    if (baseUrl == null) return;
                    final originalUrl = _photoApi.getOriginalSizeUrl(baseUrl);
                    ToastUtil.copyToClipboard(context, originalUrl);
                  },
                  onTap: () async {
                       _viewPhoto(media);
                    // _viewPhotoInGallery(index);
                  },
                  child: Container(
                    // color: Colors.green,
                    child: Column(
                      children: [
                        Expanded(
                          child: PhotoThumbnail(
                            thumbnailUrl: thumbnailUrl,
                          ),
                        ),
                        // Text("${media.filename}"),
                      ],
                    ),
                  ),
                );
              },
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
      // AlbumActions.selectRanking,
      // AlbumActions.viewDeleted,
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

  void _viewPhotoInGallery(int index) {
    final imageUrls = _getPhotoUrlList();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => PhotoGalleryWidget(
          imageUrls: imageUrls,
          initialIndex: index,
        ),
      ),
    );
  }
}
