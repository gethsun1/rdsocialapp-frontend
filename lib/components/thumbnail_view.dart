import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:foap/helper/imports/common_import.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import '../model/story_model.dart';
import 'package:path_provider/path_provider.dart';

import '../screens/story/story_updates_bar.dart';

class MediaThumbnailView extends StatefulWidget {
  final StoryMediaModel media;

  final double? size;
  final Color? borderColor;

  const MediaThumbnailView({
    super.key,
    required this.media,
    this.size,
    this.borderColor,
  });

  @override
  State<MediaThumbnailView> createState() => _MediaThumbnailViewState();
}

class _MediaThumbnailViewState extends State<MediaThumbnailView> {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
            height: widget.size ?? storyCircleSize,
            width: widget.size ?? storyCircleSize,
            child: widget.media.type == 2
                ? _networkThumbnail(widget.media.image ?? '')
                : (widget.media.image?.trim().isNotEmpty == true
                    ? Stack(
                        fit: StackFit.expand,
                        children: [
                          _networkThumbnail(widget.media.image ?? ''),
                          const Center(
                            child: Icon(
                              Icons.play_circle_fill_rounded,
                              color: Colors.white,
                              size: 22,
                            ),
                          ),
                        ],
                      )
                    : FutureBuilder<ThumbnailResult>(
                        future: genThumbnail(widget.media.video ?? ''),
                        builder:
                            (BuildContext context, AsyncSnapshot snapshot) {
                          if (snapshot.hasData) {
                            final image = snapshot.data.userImage;

                            return Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: <Widget>[
                                image,
                              ],
                            );
                          } else if (snapshot.hasError) {
                            debugPrint(
                                '[MediaThumbnailView] Thumbnail failed: ${widget.media.video} error=${snapshot.error}');
                            return const SizedBox(
                              height: 20,
                              width: 20,
                              child: Icon(Icons.error_outline),
                            );
                          } else {
                            return const CircularProgressIndicator().p16;
                          }
                        },
                      )))
        .borderWithRadius(
            value: 2,
            radius: 40,
            color: widget.borderColor ?? AppColorConstants.themeColor);
  }

  Widget _networkThumbnail(String url) {
    return CachedNetworkImage(
      imageUrl: url,
      fit: BoxFit.cover,
      placeholder: (context, url) => SizedBox(
          height: 20, width: 20, child: const CircularProgressIndicator().p16),
      errorWidget: (context, url, error) =>
          const SizedBox(height: 20, width: 20, child: Icon(Icons.error)),
    ).round(40).p(1);
  }
}

Future<ThumbnailResult> genThumbnail(String path) async {
  if (path.trim().isEmpty) {
    throw ArgumentError('Empty video URL');
  }
  //WidgetsFlutterBinding.ensureInitialized();
  Directory tempDirPath = await getTemporaryDirectory();
  Uint8List bytes;
  final Completer<ThumbnailResult> completer = Completer();
  final thumbnailPath = await VideoThumbnail.thumbnailFile(
          video: path,
          // headers: {
          //   "USERHEADER1": "user defined header1",
          //   "USERHEADER2": "user defined header2",
          // },
          thumbnailPath: tempDirPath.path,
          imageFormat: ImageFormat.JPEG,
          maxHeight: 50,
          maxWidth: 50,
          timeMs: 0,
          quality: 50)
      .timeout(const Duration(seconds: 8));

  if (thumbnailPath != null) {
    final file = File(thumbnailPath);
    bytes = file.readAsBytesSync();

    int imageDataSize = bytes.length;

    final image = Image.memory(bytes);
    image.image
        .resolve(const ImageConfiguration())
        .addListener(ImageStreamListener((ImageInfo info, bool _) {
      completer.complete(ThumbnailResult(
        image: image,
        dataSize: imageDataSize,
        height: info.image.height,
        width: info.image.width,
      ));
    }));
  } else {
    throw StateError('Unable to generate video thumbnail');
  }

  return completer.future;
}

class ThumbnailResult {
  final Image image;
  final int dataSize;
  final int height;
  final int width;

  const ThumbnailResult(
      {required this.image,
      required this.dataSize,
      required this.height,
      required this.width});
}
