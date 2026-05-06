import 'package:foap/helper/imports/common_import.dart';
import '../../controllers/profile/profile_controller.dart';

class ChangeBio extends StatefulWidget {
  const ChangeBio({super.key});

  @override
  State<ChangeBio> createState() => _ChangeBioState();
}

class _ChangeBioState extends State<ChangeBio> {
  final TextEditingController bio = TextEditingController();
  final ProfileController profileController = Get.find();
  final UserProfileManager _userProfileManager = Get.find();

  @override
  void initState() {
    super.initState();
    bio.text = _userProfileManager.user.value?.bio ?? '';
  }

  @override
  void dispose() {
    bio.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColorConstants.backgroundColor,
      body: Column(
        children: [
          const SizedBox(height: 50),
          profileScreensNavigationBar(
              title: bioString.tr,
              rightBtnTitle: doneString.tr,
              completion: () {
                profileController.updateBio(bio: bio.text);
              }),
          divider().vP8,
          const SizedBox(height: 20),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Heading6Text(bioString.tr, weight: TextWeight.medium),
              Container(
                color: Colors.transparent,
                child: AppTextField(
                  controller: bio,
                  hintText: bioHintString.tr,
                  maxLines: 4,
                  maxLength: 160,
                ),
              ).vP8,
              BodySmallText(
                bioLimitHintString.tr,
                color: AppColorConstants.subHeadingTextColor,
              ),
            ],
          ).hp(DesignConstants.horizontalPadding),
        ],
      ),
    );
  }
}
