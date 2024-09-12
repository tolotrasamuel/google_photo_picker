import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_photo_picker/services/google_drive_api/google_drive_api.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:googleapis/drive/v3.dart' as drive;

final GoogleDriveApi _googleDriveApi = GoogleDriveApi();

class GoogleDriveWidget extends StatefulWidget {
  @override
  _GoogleDriveWidgetState createState() => _GoogleDriveWidgetState();
}

class _GoogleDriveWidgetState extends State<GoogleDriveWidget> {
  GoogleSignInAccount? _currentUser;
  String? _currentFolderId;
  List<drive.File> _currentFolderContents = [];
  List<String> _folderStack = [];

  @override
  void initState() {
    super.initState();
    _handleSignInSilently();
  }

  Future<void> _handleSignInSilently() async {
    final user = await _googleDriveApi.getUser();
    if (user != null) {
      setState(() {
        _currentUser = user;
      });
      await _loadFolderContents('root'); // Load root folder on initialization
    }
  }

  Future<void> _loadFolderContents(String folderId) async {
    setState(() {
      _currentFolderId = folderId;
    });

    final folderContents = await _googleDriveApi.listFolderContents(folderId);
    setState(() {
      _currentFolderContents = folderContents;
    });
  }

  Future<void> _handleSignIn() async {
    final user = await _googleDriveApi.getUser();
    if (user != null) {
      setState(() {
        _currentUser = user;
      });
      await _loadFolderContents('root');
    }
  }

  Future<void> _handleSignOut() async {
    await _googleDriveApi.handleSignOut();
    setState(() {
      _currentUser = null;
      _currentFolderContents = [];
      _folderStack.clear();
    });
  }

  Future<void> _copyLinkToClipboard(String link) async {
    await Clipboard.setData(ClipboardData(text: link));
    Fluttertoast.showToast(
      msg: "Link copied to clipboard",
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
    );
  }

  void _navigateToFolder(String folderId) {
    print('Navigating to folder: $folderId');
    _folderStack.add(_currentFolderId ?? 'root');
    _loadFolderContents(folderId);
  }

  void _goBack() {
    if (_folderStack.isNotEmpty) {
      final parentFolderId = _folderStack.removeLast();
      _loadFolderContents(parentFolderId);
    }
  }

  AppBar _buildAppBar() {
    return AppBar(
      title: Text(_currentUser != null
          ? 'Google Drive - ${_currentUser?.displayName}'
          : 'Google Drive'),
      actions: [
        _buildSignInOutButton(),
      ],
    );
  }

  Widget _buildSignInOutButton() {
    if (_currentUser != null) {
      return IconButton(
        icon: Icon(Icons.logout),
        onPressed: _handleSignOut,
      );
    } else {
      return IconButton(
        icon: Icon(Icons.login),
        onPressed: _handleSignIn,
      );
    }
  }

  Widget _buildFolderList() {
    return Expanded(
      child: ListView.builder(
        itemCount: _currentFolderContents.length,
        itemBuilder: (context, index) {
          final file = _currentFolderContents[index];
          return _buildFileTile(file);
        },
      ),
    );
  }

  Widget _buildFileTile(drive.File file) {
    final isFolder = file.mimeType == 'application/vnd.google-apps.folder';

    return ListTile(
      onTap: isFolder ? () => _navigateToFolder(file.id!) : null,
      // onTap: isFolder
      //     ? null
      //     : () => _copyLinkToClipboard(file.webContentLink!),
      title: Text(file.name ?? 'Unnamed'),
      subtitle: Text(isFolder ? 'Folder' : 'File'),
      trailing: Icon(isFolder ? Icons.folder : Icons.insert_drive_file),

    );
  }

  Widget _buildBackButton() {
    if (_folderStack.isNotEmpty) {
      return ElevatedButton(
        onPressed: _goBack,
        child: Text('Back'),
      );
    }
    return SizedBox.shrink();
  }

  Widget _buildBody() {
    if (_currentUser == null) {
      return Center(child: Text('Please sign in to Google Drive'));
    }

    return Column(
      children: [
        _buildBackButton(),
        _buildFolderList(),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: _buildBody(),
    );
  }
}
