import 'dart:ui';

import 'package:foap/helper/imports/chat_imports.dart';
import 'package:foap/helper/imports/common_import.dart';
import 'package:image_picker/image_picker.dart';
import '../../components/force_update_view.dart';
import '../../main.dart';
import '../add_on/ui/reel/reels.dart';
import '../home_feed/home_feed_screen.dart';
import '../profile/my_profile.dart';
import '../settings_menu/settings_controller.dart';
import 'explore.dart';

class DashboardController extends GetxController {
  RxInt currentIndex = 0.obs;
  RxInt unreadMsgCount = 0.obs;
  RxBool isLoading = false.obs;

  void indexChanged(int index) {
    currentIndex.value = index;
  }

  void updateUnreadMessageCount(int count) {
    unreadMsgCount.value = count;
  }
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  DashboardState createState() => DashboardState();
}

class DashboardState extends State<DashboardScreen> {
  final DashboardController _dashboardController = Get.find();
  final SettingsController _settingsController = Get.find();

  List<Widget> items = [];
  final picker = ImagePicker();
  bool hasPermission = false;

  @override
  void initState() {
    isAnyPageInStack = true;
    items = [
      const HomeFeedScreen(),
      const Explore(),
      const Reels(
        needBackBtn: false,
      ),
      const ChatHistory(),
      const MyProfile(
        showBack: false,
      ),
      //const Settings()
    ];

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() => _dashboardController.isLoading.value == true
        ? SizedBox(
            height: Get.height,
            width: Get.width,
            child: const Center(child: CircularProgressIndicator()),
          )
        : _settingsController.forceUpdate.value == true
            ? ForceUpdateView()
            : _settingsController.appearanceChanged?.value == null
                ? Container()
                : Scaffold(
                    backgroundColor: AppColorConstants.backgroundColor,
                    body: items[_dashboardController.currentIndex.value],
                    floatingActionButtonLocation:
                        FloatingActionButtonLocation.centerDocked,
                    bottomNavigationBar: _buildBottomNavigation(context)));
  }

  Widget _buildBottomNavigation(BuildContext context) {
    final double bottomInset = MediaQuery.of(context).viewPadding.bottom;
    final int currentIndex = _dashboardController.currentIndex.value;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          height: bottomInset > 0 ? 96 : 76,
          width: Get.width,
          padding: EdgeInsets.only(bottom: bottomInset > 0 ? bottomInset : 6),
          decoration: BoxDecoration(
            color: AppColorConstants.cardColor
                .withValues(alpha: isDark ? 0.78 : 0.96),
            border: Border(
              top: BorderSide(
                color: AppColorConstants.borderColor.withValues(alpha: 0.45),
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.28 : 0.08),
                blurRadius: 24,
                offset: const Offset(0, -8),
              ),
            ],
          ),
          child: BottomNavigationBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            type: BottomNavigationBarType.fixed,
            currentIndex: currentIndex,
            selectedFontSize: 11,
            unselectedFontSize: 11,
            unselectedItemColor:
                AppColorConstants.iconColor.withValues(alpha: 0.58),
            selectedItemColor: AppColorConstants.themeColor,
            onTap: onTabTapped,
            items: [
              _navItem(
                icon: ThemeIcon.home,
                label: homeString.tr,
                index: 0,
                currentIndex: currentIndex,
              ),
              _navItem(
                icon: ThemeIcon.search,
                label: exploreString.tr,
                index: 1,
                currentIndex: currentIndex,
              ),
              _navItem(
                icon: ThemeIcon.reels,
                label: reelsString.tr,
                index: 2,
                currentIndex: currentIndex,
                isPrimary: true,
              ),
              BottomNavigationBarItem(
                icon: _chatNavIcon(currentIndex),
                label: chatsString.tr,
              ),
              _navItem(
                icon: ThemeIcon.account,
                label: accountString.tr,
                index: 4,
                currentIndex: currentIndex,
              ),
            ],
          ),
        ),
      ),
    );
  }

  BottomNavigationBarItem _navItem({
    required ThemeIcon icon,
    required String label,
    required int index,
    required int currentIndex,
    bool isPrimary = false,
  }) {
    return BottomNavigationBarItem(
      icon: _navIcon(
        icon: icon,
        isSelected: currentIndex == index,
        isPrimary: isPrimary,
      ),
      label: label,
    );
  }

  Widget _chatNavIcon(int currentIndex) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        _navIcon(
          icon: ThemeIcon.chat,
          isSelected: currentIndex == 3,
        ),
        if (_dashboardController.unreadMsgCount.value > 0)
          Positioned(
            right: 6,
            top: 3,
            child: Container(
              height: 9,
              width: 9,
              decoration: BoxDecoration(
                color: AppColorConstants.themeColor,
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColorConstants.cardColor,
                  width: 1.5,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _navIcon({
    required ThemeIcon icon,
    required bool isSelected,
    bool isPrimary = false,
  }) {
    final Color color = isSelected
        ? AppColorConstants.themeColor
        : AppColorConstants.iconColor.withValues(alpha: 0.72);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      height: 38,
      width: isSelected ? 54 : 44,
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(19),
        color: isSelected || isPrimary
            ? AppColorConstants.themeColor
                .withValues(alpha: isSelected ? 0.16 : 0.08)
            : Colors.transparent,
      ),
      child: Center(
        child: ThemeIconWidget(
          icon,
          size: isPrimary ? 27 : 25,
          color: color,
        ),
      ),
    );
  }

  void onTabTapped(int index) async {
    // if (index == 2) {
    //   Future.delayed(
    //     Duration.zero,
    //     () => showGeneralDialog(
    //         context: context,
    //         pageBuilder: (context, animation, secondaryAnimation) =>
    //             const SelectMedia()),
    //   );
    // } else {
    Future.delayed(
        Duration.zero, () => _dashboardController.indexChanged(index));
    // }
  }
}
