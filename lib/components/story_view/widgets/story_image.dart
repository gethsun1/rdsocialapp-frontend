import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class StoryImage extends StatefulWidget {
  final String imageUrl;
  final bool? isAsset;
  const StoryImage({
    super.key,
    required this.imageUrl,
    this.isAsset = false,
  });

  factory StoryImage.url(String url, {bool? isAsset = false}) {
    return StoryImage(imageUrl: url, isAsset: isAsset);
  }

  @override
  State<StoryImage> createState() => _StoryImageState();
}

class _StoryImageState extends State<StoryImage> {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
        width: double.infinity,
        height: double.infinity,
        child: widget.isAsset == true
            ? Image.asset(
                widget.imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  debugPrint(
                      '[StoryImage] Asset image failed: ${widget.imageUrl} error=$error');
                  return const _StoryImageFallback();
                },
              )
            : CachedNetworkImage(
                imageUrl: widget.imageUrl,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: Colors.black,
                  child: const Center(
                    child: CircularProgressIndicator(color: Colors.white70),
                  ),
                ),
                errorWidget: (context, url, error) {
                  debugPrint(
                      '[StoryImage] Network image failed: $url error=$error');
                  return const _StoryImageFallback();
                },
              ));
  }
}

class _StoryImageFallback extends StatelessWidget {
  const _StoryImageFallback();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Colors.grey.shade900,
      child: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.broken_image_outlined, color: Colors.white70, size: 42),
            SizedBox(height: 12),
            Text(
              'Image could not be loaded.',
              style: TextStyle(color: Colors.white70, fontSize: 15),
            ),
          ],
        ),
      ),
    );
  }
}
