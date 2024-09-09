// import 'package:cached_network_image/cached_network_image.dart';
// import 'package:flutter/material.dart';
// import 'package:photo_view/photo_view.dart';
// import 'package:photo_view/photo_view_gallery.dart';
//
// class PhotoGalleryWidget extends StatefulWidget {
//   final List<String> imageUrls;
//   final int initialIndex;
//   const PhotoGalleryWidget(
//       {super.key, required this.imageUrls, required this.initialIndex});
//
//   @override
//   State<PhotoGalleryWidget> createState() => _PhotoGalleryWidgetState();
// }
//
// class _PhotoGalleryWidgetState extends State<PhotoGalleryWidget> {
//   late final controller = PageController(initialPage: widget.initialIndex);
//   @override
//   void initState() {
//     // TODO: implement initState
//     super.initState();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(),
//       body: Container(
//         child: PhotoViewGallery.builder(
//           pageController: controller,
//           scrollPhysics: const BouncingScrollPhysics(),
//           builder: (BuildContext context, int index) {
//             return PhotoViewGalleryPageOptions(
//               imageProvider: CachedNetworkImageProvider(
//                 widget.imageUrls[index],
//               ),
//               initialScale: PhotoViewComputedScale.contained,
//               heroAttributes:
//                   PhotoViewHeroAttributes(tag: widget.imageUrls[index]),
//             );
//           },
//           itemCount: widget.imageUrls.length,
//           loadingBuilder: (context, event) => Center(
//             child: Container(
//               width: 20.0,
//               height: 20.0,
//               child: CircularProgressIndicator(
//                 value: event == null
//                     ? 0
//                     : event.cumulativeBytesLoaded /
//                         (event.expectedTotalBytes ?? 1),
//               ),
//             ),
//           ),
//           // backgroundDecoration: widget.backgroundDecoration,
//           // pageController: widget.pageController,
//           onPageChanged: onPageChanged,
//         ),
//       ),
//     );
//   }
//
//   void onPageChanged(int index) {}
// }
