import 'package:foap/helper/imports/common_import.dart';
import 'package:foap/theme/theme.dart';

class TextStoryMakerController extends GetxController {
  Rx<Color> selectedStrokeColor = Colors.black.obs;
  Rx<Color?> selectedBackgroundColor = Colors.white.obs;
  Rx<String> fontName = 'Lato'.obs;
  RxString inputText = ''.obs;

  void textChanged(String text) {
    inputText.value = text;
  }

  void setFont(Font font) {
    switch (font) {
      case Font.roboto:
        fontName.value = 'Roboto';
        break;
      case Font.raleway:
        fontName.value = 'Raleway';
        break;
      case Font.poppins:
        fontName.value = 'Poppins';
        break;
      case Font.openSans:
        fontName.value = 'OpenSans';
        break;
      case Font.lato:
        fontName.value = 'Lato';
        break;
    }
    update();
  }

  void setStrokeColor(Color color) {
    selectedStrokeColor.value = color;
  }

  void setBackgroundColor(Color color) {
    selectedBackgroundColor.value = color;
  }

  void postTextStory({required String text, required String backgroundColor}) {
    // StoryApi.postStory(gallery: [
    //   {
    //     'image': '',
    //     'video': '',
    //     'type': '1',
    //     'description': text,
    //     'background_color': backgroundColor,
    //   }
    // ]);
    // Get.offAll(const DashboardScreen());
  }
}
