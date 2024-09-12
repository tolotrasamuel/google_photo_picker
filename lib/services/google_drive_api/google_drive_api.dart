import 'dart:math';
import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:googleapis_auth/auth_io.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show kIsWeb;

const List<String> scopes = [drive.DriveApi.driveScope];

final GoogleSignIn _googleSignIn = GoogleSignIn(
  scopes: scopes,
);

class GoogleDriveApi {
  GoogleSignInAccount? currentUser;
  AuthClient? client;

  Future<GoogleSignInAccount?> getUser() async {
    print("Getting user");

    GoogleSignInAccount? user;
    if (!kIsWeb) {
      user = await _googleSignIn.signInSilently();
    }

    user ??= await _googleSignIn.signIn();
    currentUser = user;
    return user;
  }

  Future<http.Client> _getHttpClient() async {
    final clientCache = this.client;
    if (clientCache != null) {
      print("Old Access token: ${clientCache.credentials.accessToken}");
      return clientCache;
    }

    await getUser();
    final AuthClient? client = await _googleSignIn.authenticatedClient();
    if (client == null) {
      throw Exception("Sign-in first");
    }
    this.client = client;
    print("New Access token: ${client.credentials.accessToken}");
    return client;
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

  Future<List<drive.File>> listFolders() async {
    final client = await _getHttpClient();
    final driveApi = drive.DriveApi(client);

    List<drive.File> folders = [];
    String? pageToken;

    while (true) {
      var folderQuery = "mimeType='application/vnd.google-apps.folder' and trashed=false";
      final result = await driveApi.files.list(
        q: folderQuery,
        spaces: 'drive',
        pageSize: 50,
        pageToken: pageToken,
        $fields: 'nextPageToken, files(id, name)',
      );

      folders.addAll(result.files ?? []);
      pageToken = result.nextPageToken;
      if (pageToken == null) break;
    }

    return folders;
  }

  Future<List<drive.File>> listFolderContents(String folderId) async {
    final client = await _getHttpClient();
    final driveApi = drive.DriveApi(client);

    List<drive.File> folderContents = [];
    String? pageToken;

    /// include mimeType
    while (true) {
      final result = await driveApi.files.list(
        q: "'$folderId' in parents and trashed=false",
        spaces: 'drive',
        pageSize: 50,
        pageToken: pageToken,
        $fields: 'nextPageToken, files(id, name, webContentLink, mimeType, webViewLink)',
      );

      folderContents.addAll(result.files ?? []);
      pageToken = result.nextPageToken;
      if (pageToken == null) break;
    }

    return folderContents;
  }

  Future<String?> getWebContentLink(String fileId) async {
    final client = await _getHttpClient();
    final driveApi = drive.DriveApi(client);

    final file = await driveApi.files.get(fileId, $fields: 'webContentLink');
    if (file is! drive.File) return null;
    return file.webContentLink;
  }

  void flush() {
    client = null;
    currentUser = null;
  }

  Future<T> callApi<T>(Future<T> action) async {
    try {
      return await action;
    } catch (e) {
      if (e.toString().contains("invalid_token")) {
        await currentUser?.clearAuthCache();
        flush();
        return await action;
      }
      print("Error: $e");
      throw e;
    }
  }
}
