import 'package:foap/screens/chat/media.dart';
import 'package:get/get.dart';

import '../../helper/enum.dart';
class SelectPostMediaController extends GetxController {
  RxList<Media> selectedMediaList = <Media>[].obs;
  RxBool allowMultipleSelection = false.obs;
  RxInt currentIndex = 0.obs;

  void clear() {
    allowMultipleSelection.value = false;
    selectedMediaList.clear();
    update();
  }

  void toggleMultiSelectionMode() {
    allowMultipleSelection.value = !allowMultipleSelection.value;
    update();
  }

  void mediaSelected(List<Media> media) {
    selectedMediaList.value = media;
    selectedMediaList.refresh();
    update();
  }

  void updateGallerySlider(int index) {
    currentIndex.value = index;
    update();
  }

  void replaceMediaWithEditedMedia(
      {required Media originalMedia, required Media editedMedia}) {
    int indexOfItemToReplace = selectedMediaList
        .indexWhere((element) => element.id == originalMedia.id);
    selectedMediaList.removeAt(indexOfItemToReplace);
    selectedMediaList.insert(indexOfItemToReplace, editedMedia);
    selectedMediaList.refresh();
    update();
  }

  bool get canEditMedia {
    return selectedMediaList
        .where((element) =>
    element.mediaType == GalleryMediaType.photo ||
        element.mediaType == GalleryMediaType.video)
        .isNotEmpty;
  }
}
