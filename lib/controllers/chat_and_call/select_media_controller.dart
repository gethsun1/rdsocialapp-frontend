import 'package:foap/helper/imports/chat_imports.dart';
import 'package:get/get.dart';

class SelectMediaController extends GetxController {
  RxList<Media> mediaList = <Media>[].obs;
  final RxList<Media> selectedItems = <Media>[].obs;

  RxBool allowMultipleSelection = false.obs;

  RxInt numberOfItems = 0.obs;
  bool isLoading = false;

  void clear() {
    allowMultipleSelection.value = false;
    mediaList.clear();
  }

  void mediaSelected(List<Media> media) {
    mediaList.value = media;
  }

  void toggleMultiSelectionMode() {
    allowMultipleSelection.value = !allowMultipleSelection.value;
    update();
  }
}
