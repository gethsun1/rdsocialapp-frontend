import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_video_info/flutter_video_info.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import '../../components/giphy/giphy_get.dart';
import '../../helper/imports/common_import.dart';
import '../../util/constant_util.dart';
import '../chat/drawing_screen.dart';
import '../chat/media.dart';
import '../settings_menu/settings_controller.dart';

enum PostContext { none, dailyDrop, challenge, riverRun, chat }

class PostOptionsPopup extends StatelessWidget {
  final SettingsController _settingsController = Get.find();
  final Function(List<Media>)? selectedMediaList;
  final Function(Media)? selectGif;
  final Function(Media)? recordedAudio;
  final ImagePicker _picker = ImagePicker();

  PostOptionsPopup({
    super.key,
    this.selectedMediaList,
    this.selectGif,
    this.recordedAudio,
  });

  @override
  Widget build(BuildContext context) {
    List<Widget> options = [];

    options.add(cameraButton());

    if (_settingsController.setting.value!.enableImagePost) {
      options.add(galleryButton());
    }
    if (_settingsController.setting.value!.enableVideoPost) {
      options.add(videoButton());
    }

    options.add(drawButton());
    options.add(gifButton());

    return SizedBox(
      height: 30,
      child: ListView.separated(
        padding: EdgeInsets.only(
            left: DesignConstants.horizontalPadding,
            right: DesignConstants.horizontalPadding),
        scrollDirection: Axis.horizontal,
        itemCount: options.length,
        itemBuilder: (ctx, index) {
          return options[index];
        },
        separatorBuilder: (ctx, index) {
          return const SizedBox(
            width: 8,
          );
        },
      ),
    );
  }

  Widget cameraButton() {
    return ModalComponents(
      check: true,
      icon: ThemeIcon.camera,
      name: cameraString.tr,
      onPress: () async {
        selectPhoto(
          source: ImageSource.camera,
        );
      },
    );
  }

  Widget galleryButton() {
    return ModalComponents(
      check: true,
      icon: ThemeIcon.gallery,
      name: galleryString.tr,
      onPress: () async {
        selectPhoto(
          source: ImageSource.gallery,
        );
      },
    );
  }

  Widget videoButton() {
    return ModalComponents(
      check: true,
      icon: ThemeIcon.videoCamera,
      name: videoString.tr,
      onPress: () async {
        selectVideo(
          source: ImageSource.gallery,
        );
      },
    );
  }

  Widget drawButton() {
    return ModalComponents(
      check: true,
      icon: ThemeIcon.drawing,
      name: drawingString.tr,
      imageUrl: 'assets/images/dashboard/draw_icon.svg',
      onPress: () {
        openDrawingBoard();
      },
    );
  }

  Widget gifButton() {
    return ModalComponents(
      check: true,
      icon: ThemeIcon.gif,
      name: gifString.tr,
      onPress: () {
        openGify();
      },
    );
  }

  void openGify() async {
    String randomId = 'hsvcewd78djhbejkd';

    GiphyGif? gif = await GiphyGet.getGif(
      context: Get.context!,
      //Required
      apiKey: _settingsController.setting.value!.giphyApiKey!,
      //Required.
      lang: GiphyLanguage.english,
      //Optional - Language for query.
      randomID: randomId,
      // Optional - An ID/proxy for a specific user.
      tabColor: Colors.teal, // Optional- default accent color.
    );

    if (gif != null) {
      Media media = Media();
      media.filePath = 'https://i.giphy.com/media/${gif.id}/200.gif';
      media.mediaType = GalleryMediaType.gif;
      if (selectGif != null) {
        selectGif!(media);
      }
    }
  }

  void openDrawingBoard() {
    showModalBottomSheet(
        backgroundColor: Colors.transparent,
        context: Get.context!,
        // isDismissible: false,
        isScrollControlled: true,
        // enableDrag: false,
        builder: (context) => FractionallySizedBox(
            heightFactor: 0.9,
            child: DrawingScreen(
              drawingCompleted: (media) {
                if (selectedMediaList != null) {
                  // Navigator.of(context).pop();
                  EasyLoading.show(status: loadingString);
                  Future.delayed(const Duration(milliseconds: 200), () {
                    EasyLoading.dismiss();
                    selectedMediaList!([media]);
                  });
                }
              },
            )));
  }

  Future<void> selectPhoto({
    required ImageSource source,
  }) async {
    try {
      if (source == ImageSource.camera) {
        XFile? image = await _picker.pickImage(
          source: ImageSource.camera,
          imageQuality: 75,
          maxWidth: 1600,
          maxHeight: 1600,
          requestFullMetadata: false,
        );

        if (image != null) {
          convertToMedias(files: [image], mediaType: GalleryMediaType.photo);
        }
      } else {
        List<XFile> images = await _picker.pickMultiImage(
          imageQuality: 75,
          maxWidth: 1600,
          maxHeight: 1600,
          requestFullMetadata: false,
        );
        convertToMedias(files: images, mediaType: GalleryMediaType.photo);
      }
    } on PlatformException catch (e) {
      AppUtil.showToast(
          message: e.message ?? 'Unable to access camera/gallery',
          isSuccess: false);
    } catch (_) {
      AppUtil.showToast(
          message: 'Unable to pick media right now. Please try again.',
          isSuccess: false);
    }
  }

  Future<void> selectVideo({
    required ImageSource source,
  }) async {
    try {
      XFile? file = await _picker.pickVideo(
        source: source,
        maxDuration: const Duration(minutes: 3),
      );

      if (file != null) {
        convertToMedias(files: [file], mediaType: GalleryMediaType.video);
      }
    } on PlatformException catch (e) {
      AppUtil.showToast(
          message: e.message ?? 'Unable to access video picker',
          isSuccess: false);
    } catch (_) {
      AppUtil.showToast(
          message: 'Unable to pick video right now. Please try again.',
          isSuccess: false);
    }
  }

  Future<void> convertToMedias(
      {required List<XFile> files, required GalleryMediaType mediaType}) async {
    List<Media> medias = [];
    for (XFile mediaFile in files) {
      final file = File(mediaFile.path);
      if (!await file.exists()) {
        continue;
      }

      Media media = Media();
      media.mediaType = mediaType;
      media.file = file;

      if (mediaType == GalleryMediaType.photo) {
        try {
          final Uint8List bytes = await mediaFile.readAsBytes();
          media.mainFileBytes = bytes;
        } catch (e) {
          debugPrint(
              '[PostOptionsPopup] Unable to cache picked image bytes: $e');
        }
      }

      if (mediaType == GalleryMediaType.video) {
        try {
          final videoInfo =
              await FlutterVideoInfo().getVideoInfo(mediaFile.path);
          if (videoInfo?.width != null && videoInfo?.height != null) {
            media.size = Size(
                videoInfo!.width!.toDouble(), videoInfo.height!.toDouble());
          }

          media.thumbnail = await VideoThumbnail.thumbnailData(
            video: mediaFile.path,
            imageFormat: ImageFormat.JPEG,
            maxWidth: 500,
            quality: 25,
          );
        } catch (_) {}
      }

      media.id = randomId();
      medias.add(media);
    }

    if (medias.isNotEmpty) {
      selectedMediaList!(medias);
    }
  }
}

class ModalComponents extends StatelessWidget {
  final bool check;
  final String? imageUrl;
  final ThemeIcon icon;
  final String name;
  final VoidCallback? onPress;

  const ModalComponents(
      {super.key,
      required this.check,
      this.imageUrl,
      required this.icon,
      required this.name,
      this.onPress});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ThemeIconWidget(icon),
        const SizedBox(
          width: 10,
        ),
        BodySmallText(
          name,
        ),
      ],
    ).hP8.borderWithRadius(value: 0.5, radius: 5).ripple(() {
      onPress!();
    });
  }
}
