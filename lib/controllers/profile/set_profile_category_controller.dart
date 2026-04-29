import 'package:foap/api_handler/apis/misc_api.dart';
import 'package:get/get.dart';
import '../../model/category_model.dart';

class SetProfileCategoryController extends GetxController {
  RxList<CategoryModel> categories = <CategoryModel>[].obs;
  RxInt profileCategoryType = (-1).obs;

  void getProfileTypeCategories() {
    MiscApi.getProfileCategoryType(resultCallback: (result) {
      categories.value = result;
    });
  }

  void setProfileCategoryType(int categoryType) {
    profileCategoryType.value = categoryType;
    update();
  }
}
