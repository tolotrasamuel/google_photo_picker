import 'dart:io' show Platform;
import 'dart:math';

import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/photoslibrary/v1.dart' as gp;
import 'package:googleapis/photoslibrary/v1.dart';
import 'package:googleapis_auth/auth_io.dart';
import 'package:http/http.dart' as http;

const thumbnailSize = 'w256-h256';
const originalSize = 'd';

final iosClientId =
    // '223888301605-utcolsavqjq3raprfjjml0mvcmh8ptik.apps.googleusercontent.com';
    '223888301605-n8uecni4l4erpbhb80dub2mm5sfkfpf4.apps.googleusercontent.com';
final androidClientId =
    '223888301605-56d2n3eciapd5cu9268t2q52vj0gqd3t.apps.googleusercontent.com';
const scopes = <String>[
  PhotosLibraryApi.photoslibraryScope,
];
final GoogleSignIn _googleSignIn = GoogleSignIn(
  clientId: (Platform.isIOS || Platform.isMacOS) ? iosClientId : null,
  scopes: scopes,
);

class GooglePhotoApi {
  GoogleSignInAccount? currentUser;
  AuthClient? client;

  Future<void> removeMediaFromAlbum(String albumId, String mediaId) async {
    final client = await _getHttpClient();
    final photo = gp.PhotosLibraryApi(client);
    final request = BatchRemoveMediaItemsFromAlbumRequest(
      mediaItemIds: [mediaId],
    );
    await photo.albums.batchRemoveMediaItems(request, albumId);
    return;
  }

  Future<GoogleSignInAccount?> getUser() async {
    // _googleSignIn.tok
    print("Getting user");
    GoogleSignInAccount? user = await _googleSignIn.signInSilently();
    // await user?.clearAuthCache();
    // print("Auth headers: ${await user?.authHeaders}");
    user ??= await _googleSignIn.signIn();
    currentUser = user;

    // await user?.clearAuthCache();
    // print("Auth headers: ${user?.authHeaders}");
    // final accessToken = await user?.authentication;
    // print("Auth token: $accessToken");
    return user;
  }

  Future<http.Client> _getHttpClient() async {
    // final bool isAuthorized = await _googleSignIn.canAccessScopes(scopes);
    // print("Is authorized: $isAuthorized");
    final _client = this.client;
    if (_client != null) {
      print("Old Access token: ${_client.credentials.accessToken}");
      return _client;
    }
    // GoogleSignInAccount? user = await _googleSignIn.signInSilently();
    // user ??= await _googleSignIn.signIn();
    // currentUser = user;
    // await _googleSignIn.requestScopes(scopes);
    await getUser();
    final AuthClient? client = await _googleSignIn.authenticatedClient();
    if (client == null) {
      throw Exception("Sign-in first");
    }
    this.client = client;
    print("New Access token: ${client.credentials.accessToken}");
    return client;
  }

  // Future<List<gp.Album>> getAlbums() async {
  //   final client = await _getHttpClient();
  //   final photo = gp.PhotosLibraryApi(client);
  //   print("Current user: $currentUser");
  //
  //   // client.ref
  //   final albums = await photo.albums.list();
  //   print(albums);
  //   return albums.albums ?? [];
  // }

  Future<List<Album>> getSharedAlbums() async {
    final client = await _getHttpClient();
    final service = gp.PhotosLibraryApi(client);
    List<Album> albumsResult = [];
    String? pageToken;

    while (true) {
      final albums = await service.sharedAlbums.list(
        pageSize: 50,
        pageToken: pageToken,
      );

      albumsResult.addAll(albums.sharedAlbums ?? []);

      pageToken = albums.nextPageToken;
      if (pageToken == null) {
        break;
      }
    }
    return albumsResult;
  }

  Future<List<Album>> getAlbums() async {
    final client = await _getHttpClient();
    final service = gp.PhotosLibraryApi(client);
    List<Album> albumsResult = [];
    String? pageToken;

    while (true) {
      final albums = await service.albums.list(
        pageSize: 50,
        pageToken: pageToken,
      );

      albumsResult.addAll(albums.albums ?? []);

      pageToken = albums.nextPageToken;
      if (pageToken == null) {
        break;
      }
    }
    return albumsResult;
  }

  Future<void> handleSignOut() async {
    try {
      await currentUser?.clearAuthCache();
    } catch (e) {
      print("Error: $e");
    }
    await _googleSignIn.signOut();
    await _googleSignIn.disconnect();
    flush();
  }

  Future<T> callApi<T>(Future<T> search) async {
    try {
      return await search;
    } catch (e) {
      if (e is AccessDeniedException) {
        print("Access denied, trying to refresh token");
        if (e.message.contains("invalid_token")) {
          await currentUser?.clearAuthCache();
          flush();
          return await search;
        }
      }
      print("Error: $e");
      throw e;
    }
  }

  Future<List<gp.MediaItem>> getAlbumContent(String albumId) async {
    return await callApi(_getAlbumContent(albumId));
  }

  Future<List<gp.MediaItem>> _getAlbumContent(String albumId) async {
    final client = await _getHttpClient();
    final photo = gp.PhotosLibraryApi(client);

    List<gp.MediaItem> mediaItems = [];
    String? pageToken;

    while (true) {
      print("Fetching album $albumId");
      final request = SearchMediaItemsRequest(
        albumId: albumId,
        pageSize: 100,
        pageToken: pageToken,
      );
      final results = await callApi(photo.mediaItems.search(request));
      pageToken = results.nextPageToken;
      mediaItems.addAll(results.mediaItems ?? []);
      if (pageToken == null) {
        break;
      }
    }
    return mediaItems;
  }

  String getImageUrl(String url, String size) {
    // item['baseUrl'] + f'={size}'
    return "$url=$size";
  }

  String getThumbnailUrl(String url) {
    return getImageUrl(url, thumbnailSize);
  }

  String getOriginalSizeUrl(String url) {
    return getImageUrl(url, originalSize);
  }

  Future<gp.Album> getAlbumById(String albumId) async {
    return await callApi(_getAlbumById(albumId));
  }

  Future<gp.Album> _getAlbumById(String albumId) async {
    final client = await _getHttpClient();
    final photo = gp.PhotosLibraryApi(client);
    final album = await photo.albums.get(albumId);
    return album;
  }

  Future<gp.MediaItem> getMediaById(String id) {
    return callApi(_getMediaById(id));
  }

  Future<gp.MediaItem> _getMediaById(String id) {
    return _getHttpClient().then((client) {
      final photo = gp.PhotosLibraryApi(client);
      return photo.mediaItems.get(id);
    });
  }

  // https://stackoverflow.com/questions/56374316/google-photo-returns-error-400-request-contains-an-invalid-media-item-id-inv

  Future<gp.Album> duplicateAlbum(String albumId, String name) async {
    final client = await _getHttpClient();
    final photo = gp.PhotosLibraryApi(client);
    final request = CreateAlbumRequest(
      album: Album(
        title: name,
        isWriteable: true,
      ),
    );
    final newAlbum = await photo.albums.create(request);
    final mediaItems = await getAlbumContent(albumId);
    final mediaItemIds =
        mediaItems.map((e) => e.id).whereType<String>().toList();

    const batchSize = 50;
    int start = 0;
    int end = batchSize;
    while (true) {
      print("Adding batch $start - $end");
      end = min(end, mediaItemIds.length);
      final batchAddRequest = BatchAddMediaItemsToAlbumRequest(
        mediaItemIds: mediaItemIds.sublist(start, end - 1),
      );
      await photo.albums.batchAddMediaItems(batchAddRequest, newAlbum.id!);
      if (end >= mediaItemIds.length) {
        break;
      }
      start = end;
      end += batchSize;
    }
    return newAlbum;
  }

  void flush() {
    client = null;
    currentUser = null;
  }

  // void launchURL(String url) {
  //   launchUrl(url)
  // }
}
