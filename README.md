<!--
This README describes the package. If you publish this package to pub.dev,
this README's contents appear on the landing page for your package.

For information about how to write a good package README, see the guide for
[writing package pages](https://dart.dev/guides/libraries/writing-package-pages).

For general information about developing packages, see the Dart guide for
[creating packages](https://dart.dev/guides/libraries/create-library-packages)
and the Flutter guide for
[developing packages and plugins](https://flutter.dev/developing-packages).
-->

TODO: Put a short description of the package here that helps potential users
know whether this package might be useful for them.

## Features

TODO: List what your package can do. Maybe include images, gifs, or videos.

## Getting started

TODO: List prerequisites and provide or point to information on how to
start using the package.

## Usage

- Enable "Google Photos Library API" in Google Cloud Console
- https://console.cloud.google.com/apis/library/photoslibrary.googleapis.com
- For web, it seems that "People API" is also required
- Also, the client_id needs to be added in the meta tag of web/index.html
- It can be obtained from Google Cloud Console at https://console.cloud.google.com/apis/credentials?project=app-gallery-b4090
- I don't know why the simple Authentication didn't require those two steps
- If you used Firebase, your OAuth 2.0 client ID is already generated under Oauth 2.0 Client IDs > Web client (auto created by Firebase) > Client ID 
TODO: Include short and useful examples for package users. Add longer examples
to `/example` folder.

```dart
const like = 'sample';
```

## Additional information

TODO: Tell users more about the package: where to find more information, how to
contribute to the package, how to file issues, what response they can expect
from the package authors, and more.
