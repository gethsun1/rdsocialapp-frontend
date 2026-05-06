import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:foap/helper/imports/common_import.dart';
import 'package:image_picker/image_picker.dart';

class CoverImageAdjustScreen extends StatefulWidget {
  final XFile imageFile;

  const CoverImageAdjustScreen({super.key, required this.imageFile});

  @override
  State<CoverImageAdjustScreen> createState() => _CoverImageAdjustScreenState();
}

class _CoverImageAdjustScreenState extends State<CoverImageAdjustScreen> {
  final GlobalKey _previewKey = GlobalKey();
  bool _isSaving = false;

  Future<void> _applyCoverImage() async {
    if (_isSaving) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final boundary = _previewKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary == null) {
        throw StateError('Cover preview is not ready.');
      }

      final image = await boundary.toImage(pixelRatio: 3);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      if (bytes == null) {
        throw StateError('Unable to export cover image.');
      }

      Get.back(result: bytes.buffer.asUint8List());
    } catch (error) {
      debugPrint('[CoverImageAdjustScreen] export failed: $error');
      AppUtil.showToast(
          message: 'Unable to prepare cover image. Please try again.',
          isSuccess: false);
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final previewHeight = Get.height * 0.42;

    return Scaffold(
      backgroundColor: AppColorConstants.backgroundColor,
      body: Column(
        children: [
          backNavigationBar(title: editProfileCoverString.tr),
          Expanded(
            child: Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: RepaintBoundary(
                  key: _previewKey,
                  child: SizedBox(
                    width: Get.width,
                    height: previewHeight,
                    child: InteractiveViewer(
                      minScale: 1,
                      maxScale: 4,
                      boundaryMargin: EdgeInsets.zero,
                      child: Image.file(
                        File(widget.imageFile.path),
                        width: Get.width,
                        height: previewHeight,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            top: false,
            child: AppThemeButton(
              text: _isSaving ? loadingString.tr : doneString.tr,
              onPress: _applyCoverImage,
            ).hp(DesignConstants.horizontalPadding).vP16,
          ),
        ],
      ),
    );
  }
}
