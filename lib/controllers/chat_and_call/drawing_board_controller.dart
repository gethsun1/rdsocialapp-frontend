
import 'package:foap/helper/imports/common_import.dart';

class DrawingBoardController extends GetxController {
  RxDouble selectedStrokeWidth = 2.toDouble().obs;
  Rx<Color> selectedStrokeColor = Colors.black.obs;
  Rx<Color> selectedBackgroundColor = Colors.white.obs;
  RxBool isErasing = false.obs;

  void eraseToggle(){
    isErasing.value = !isErasing.value;
  }

  void setStrokeWidth(double width) {
    selectedStrokeWidth.value = width;
  }

  void setStrokeColor(Color color) {
    selectedStrokeColor.value = color;
  }

  void setBackgroundColor(Color color) {
    selectedBackgroundColor.value = color;
  }
}
