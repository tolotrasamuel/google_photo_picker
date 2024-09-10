import 'package:flutter/material.dart';
import 'package:google_photo_picker/services/google_photo_api/google_photo_api.dart';
import 'package:google_photo_picker/views/photo_list_widgets/photo_list_widget.dart';
import 'package:google_photo_picker/views/photo_thumbnail.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/photoslibrary/v1.dart';
import 'package:shared_core/utils/extensions/extensions.dart';
import 'package:shared_views/utils/toast_util.dart';
// gap
import 'package:gap/gap.dart';
import 'package:shared_views/views/load_more_on_scroll_widget.dart';
// lib/views/dropdown/dropdown_selector.dart
import 'package:shared_views/views/dropdown/dropdown_selector.dart';
import 'package:shared_views/views/loaders/fullscreen_loader.dart';
// collection
import 'package:collection/collection.dart';
enum SortBy implements BaseActionIcon {
  title,
  date,
  count;

  String get label {
    switch (this) {
      case SortBy.title:
        return "Title";
      case SortBy.date:
        return "Date";
      case SortBy.count:
        return "Count";
    }
  }

  Color get color {
    switch (this) {
      case SortBy.title:
        return Colors.blue;
      case SortBy.date:
        return Colors.green;
      case SortBy.count:
        return Colors.red;
    }
  }
  IconData get icon {
    switch (this) {
      case SortBy.title:
        return Icons.title;
      case SortBy.date:
        return Icons.date_range;
      case SortBy.count:
        return Icons.format_list_numbered;
    }
  }

}
enum AlbumType implements BaseActionIcon {
  shared,
  owned;


  IconData get icon {
    switch (this) {
      case AlbumType.shared:
        return Icons.people;
      case AlbumType.owned:
        return Icons.photo_library;
    }
  }
  Color get color {
    switch (this) {
      case AlbumType.shared:
        return Colors.blue;
      case AlbumType.owned:
        return Colors.green;
    }
  }

  String get label {
    switch (this) {
      case AlbumType.shared:
        return "Shared";
      case AlbumType.owned:
        return "Owned";
    }
  }

  // BaseActionIcon toBaseActionIcon() {
  //   switch (this) {
  //     case AlbumType.shared:
  //       return BaseActionIcon("Shared",
  //     case AlbumType.owned:
  //       return BaseActionIcon(this, "Owned");
  //   }
  // }
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

  SortBy sortBy = SortBy.date;
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: [

          /// show logged in header
          IconButton(
            onPressed: () async {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  scrollable: true,
                  content: _getHeader(),
                ),
              );
            },
            icon: Icon(Icons.account_circle),
          ),

          /// sort by
          IconButton(
            onPressed: () async {
              final result = await ToastUtil.showDialogBaseActionIcon(
                context,
                actions: SortBy.values.toList(),
                title: "Sort by",
                selectedAction: sortBy,
              );
              if (result is! SortBy) return;
              // fetch();
              sortBy = result;
              _reload();
              setState(() {});
            },
            icon: Icon(Icons.sort),
          ),

        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            DropdownSelectorView(
              labelTxt: "Album Type",
              items: AlbumType.values.toList(),
              selectedAction: albumType,
              onSelected: (x) {
                if (x is! AlbumType) return;
                albumType = x;
                // fetch();
                _reload();
              },
            ),
            Gap(8.0),
            Expanded(
              child: LoadMoreOnScrollWidget<Album>(
                // viewType: ViewType.grid,
                header: Text("Results: ${items.length}", textAlign: TextAlign.start,),
                updatingMessage: "Updating albums...",
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
                          builder: (context) =>  PhotoListWidget(albumId: albumId),
                          ),
                      );
                    },
                    child: Container(
                      // color: Colors.green,
                      child: Row(
                        mainAxisSize: MainAxisSize.max,
                        children: [
                          PhotoThumbnail(
                            thumbnailUrl: thumbnailUrl,
                          ),
                          SizedBox(width: 16),
                          Expanded(
                            child: Container(
                              // color: Colors.pink,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text("${album.title}",
                                      style: TextStyle(fontSize: 18)),
                                  Text("${album.mediaItemsCount} items"),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
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
    // await Future.delayed(Duration(seconds: 3));

    if (albumType == AlbumType.owned) {
      return await _photoApi.getAlbums();
    } else {
      return await _photoApi.getSharedAlbums();
    }
  }

  Future<void> _reload() async {
    final items = await fetchAlbums().withLocalLoader(context);
    switch (sortBy) {
      case SortBy.title:
        items.sortBy((e)=>e.title ?? "");
            break;
      case SortBy.date:
        break;
      case SortBy.count:
        items.sortByDesc<num>((e)=>e.mediaItemsCount?.tryAsInt ?? 0);
        break;
    }
    // items.sort((a, b) =>
    //     (a.title?.toLowerCase() ?? "").compareTo(b.title?.toLowerCase() ?? ""));
    this.items.clear();
    this.items.addAll(items);
    setState(() {});
    return;
  }
}
