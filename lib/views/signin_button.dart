import 'package:flutter/material.dart';
import 'package:google_photo_picker/services/google_photo_api/google_photo_api.dart';
import 'package:google_photo_picker/views/photo_list_widgets/photo_list_widget.dart';
import 'package:google_photo_picker/views/photo_thumbnail.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/photoslibrary/v1.dart';
import 'package:shared_views/utils/toast_util.dart';
import 'package:shared_views/views/load_more_on_scroll_widget.dart';

enum AlbumType {
  shared,
  owned,
}

enum AlbumActions implements BaseAction {
  duplicate("Duplicate Album"),
  viewInGooglePhoto("View in Google Photo");

  final String label;
  final Color? color;
  const AlbumActions(this.label, {this.color});
}

class AlbumsWidget extends StatefulWidget {
  const AlbumsWidget({super.key});

  @override
  State<AlbumsWidget> createState() => _AlbumsWidgetState();
}

class _AlbumsWidgetState extends State<AlbumsWidget> {
  final List<Album> items = [];
  final _photoApi = GooglePhotoApi();
  AlbumType albumType = AlbumType.owned;

  @override
  void initState() {
    super.initState();
    fetch();
  }

  Future<void> fetch() async {
    // await _photoApi.getUser();
    return;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            onPressed: () async {
              final result = await showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  insetPadding: EdgeInsets.symmetric(horizontal: 16),
                  title: Text("Pick Album Type"),
                  content: Container(
                    width: double.maxFinite,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ListTile(
                          title: Text("Shared"),
                          onTap: () {
                            Navigator.of(context).pop(AlbumType.shared);
                          },
                        ),
                        ListTile(
                          title: Text("Owned"),
                          onTap: () {
                            Navigator.of(context).pop(AlbumType.owned);
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              );
              if (result is! AlbumType) {
                return;
              }
              albumType = result;
              await _reload();
            },
            icon: Icon(Icons.photo_library_outlined),
          ),
        ],
      ),
      body: Column(
        children: [
          _getHeader(),
          Expanded(
            child: LoadMoreOnScrollWidget<Album>(
              updatingMessage: "Updating contacts...",
              items: items,
              fetchMore: () async {
                if (items.isNotEmpty) return [];
                return fetchAlbums();
              },
              reset: () async {
                _reload();
                // return await _activityService.reset();
              },
              builder: (album) {
                final thumbnailUrl = album.coverPhotoBaseUrl;
                return InkWell(
                  onLongPress: () {
                    // _onMediaTileLongPressed(media);
                  },
                  onTap: () async {
                    final albumId = album.id;
                    if (albumId == null) return;
                    final result = await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) =>    PhotoListWidget(albumId: albumId),
                        ),
                    );
                  },
                  child: Row(
                    children: [
                      PhotoThumbnail(
                        thumbnailUrl: thumbnailUrl,
                      ),
                      SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("${album.title}",
                              style: TextStyle(fontSize: 18)),
                          Text("${album.mediaItemsCount} items"),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleSignOut() async {
    // CacheService.instance.flush();
    await _photoApi.handleSignOut();
    setState(() {});
  }

  Future<void> _handleSignIn() async {
    await _photoApi.getUser();
    setState(() {});
  }

  Widget _getHeader() {
    final user = _photoApi.currentUser;
    print("user $user");
    if (user == null)
      return ElevatedButton(
        onPressed: _handleSignIn,
        child: const Text('CONNECT GOOGLE PHOTO'),
      );
    return Column(
      children: [
        ListTile(
          leading: GoogleUserCircleAvatar(
            identity: user,
          ),
          title: Text(user.displayName ?? ''),
          subtitle: Text(user.email),
        ),
        const Text('Signed in successfully.'),
        ElevatedButton(
          onPressed: _handleSignOut,
          child: const Text('SIGN OUT'),
        ),
      ],
    );
  }

  Future<List<Album>> fetchAlbums() async {
    if (albumType == AlbumType.owned) {
      return await _photoApi.getAlbums();
    } else {
      return await _photoApi.getSharedAlbums();
    }
  }

  Future<void> _reload() async {
    final items = await fetchAlbums();
    items.sort((a, b) =>
        (a.title?.toLowerCase() ?? "").compareTo(b.title?.toLowerCase() ?? ""));
    this.items.clear();
    this.items.addAll(items);
    setState(() {});
    return;
  }
}
