import 'package:foap/helper/imports/common_import.dart';
import 'package:foap/screens/profile/update_profile.dart';
import 'package:foap/screens/profile/user_post_media.dart';
import 'package:foap/screens/settings_menu/settings.dart';
import '../../components/sm_tab_bar.dart';
import '../../controllers/post/archived_post_controller.dart';
import '../../controllers/post/post_controller.dart';
import '../../controllers/post/saved_post_controller.dart';
import '../../controllers/profile/profile_controller.dart';
import '../../model/post_search_query.dart';
import '../reuseable_widgets/post_list.dart';
import 'blocked_users.dart';
import '../settings_menu/settings_controller.dart';
import 'follower_following_list.dart';

class MyProfile extends StatefulWidget {
  final bool showBack;

  const MyProfile({super.key, required this.showBack});

  @override
  MyProfileState createState() => MyProfileState();
}

class MyProfileState extends State<MyProfile>
    with SingleTickerProviderStateMixin {
  final ProfileController _profileController = Get.find();
  final SettingsController _settingsController = Get.find();
  final UserProfileManager _userProfileManager = Get.find();
  final PostController _postController = Get.find();
  final SavedPostController _savedPostController =
      Get.isRegistered<SavedPostController>()
          ? Get.find<SavedPostController>()
          : Get.put(SavedPostController());
  final ArchivedPostController _archivedPostController =
      Get.isRegistered<ArchivedPostController>()
          ? Get.find<ArchivedPostController>()
          : Get.put(ArchivedPostController());

  List<String> tabs = [
    postsString.tr,
    mentionsString.tr,
    savedPostsString.tr,
    archivedPostsString.tr
  ];

  TabController? controller;

  @override
  void initState() {
    super.initState();

    controller = TabController(vsync: this, length: tabs.length)
      ..addListener(() {});
    initialLoad();
  }

  void initialLoad() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _profileController.clear();
      loadData();
    });
  }

  @override
  void didUpdateWidget(covariant MyProfile oldWidget) {
    super.didUpdateWidget(oldWidget);
    loadData();
  }

  @override
  void dispose() {
    _profileController.clear();
    _postController.clear();
    super.dispose();
  }

  void loadData() {
    _profileController.getMyProfile();
    _profileController.getMentionPosts(_userProfileManager.user.value!.id);
    PostSearchQuery query = PostSearchQuery();
    query.userId = _userProfileManager.user.value!.id;
    _postController.setPostSearchQuery(query: query, callback: () {});
    _profileController.getReels(_userProfileManager.user.value!.id);
    _savedPostController.refreshData(() {});
    _archivedPostController.refreshData(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() => Scaffold(
          backgroundColor: AppColorConstants.backgroundColor,
          body: Stack(children: [
            if (_settingsController.appearanceChanged!.value) Container(),
            NestedScrollView(
                headerSliverBuilder:
                    (BuildContext context, bool innerBoxIsScrolled) {
                  return <Widget>[
                    SliverAppBar(
                      backgroundColor: AppColorConstants.backgroundColor,
                      pinned: true,
                      automaticallyImplyLeading: false,
                      expandedHeight: 560.0,
                      toolbarHeight: 0,
                      flexibleSpace: FlexibleSpaceBar(
                        background: addProfileView(),
                      ),
                    ),
                    SliverPersistentHeader(
                      delegate: _SliverAppBarDelegate(
                        getTextTabBar(
                            tabs: tabs,
                            controller: controller,
                            canScroll: false),
                      ),
                      pinned: true,
                      // floating: true,
                    )
                  ];
                },
                body: TabBarView(
                  controller: controller,
                  children: [
                    PostList(
                      postSource: PostSource.posts,
                      emptyTitleOverride:
                          'No Posts Here publish your first post Now',
                    ),
                    MentionsList(),
                    PostList(
                      postSource: PostSource.saved,
                      emptyTitleOverride: savedPostsString.tr,
                    ),
                    PostList(
                      postSource: PostSource.archived,
                      emptyTitleOverride: archivedPostsString.tr,
                    ),
                  ],
                )),
          ]),
        ));
  }

  Widget addProfileView() {
    return Stack(
      children: [
        GetBuilder<ProfileController>(
            init: _profileController,
            builder: (ctx) {
              final user = _profileController.user.value;
              return user == null
                  ? Container()
                  : Column(
                      children: [
                        Stack(
                          children: [
                            user.coverImage != null
                                ? Stack(
                                    children: [
                                      CachedNetworkImage(
                                          width: Get.width,
                                          height: 280,
                                          fit: BoxFit.cover,
                                          imageUrl: user.coverImage!),
                                      Container(
                                        height: 280,
                                        color: Colors.black26,
                                      ),
                                    ],
                                  ).bottomRounded(34)
                                : SizedBox(width: Get.width, height: 280),
                            Positioned(
                              left: 0,
                              right: 0,
                              top: 100,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  UserAvatarView(
                                      user: user,
                                      size: 85,
                                      onTapHandler: () {}),
                                  const SizedBox(height: 10),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Heading6Text(
                                        user.userName,
                                        weight: TextWeight.medium,
                                      ),
                                      if (user.isVerified) verifiedUserTag()
                                    ],
                                  ).bP4,
                                  if (user.profileCategoryTypeId != 0)
                                    BodyLargeText(
                                      user.profileCategoryTypeName,
                                      weight: TextWeight.medium,
                                    ).bP4,
                                  user.country != null
                                      ? BodyMediumText(
                                          '${user.country}, ${user.city}',
                                        )
                                      : Container(),
                                ],
                              ).p16,
                            ),
                          ],
                        ),
                        _profileBioView(user)
                            .tp(20)
                            .hp(DesignConstants.horizontalPadding),
                        _profileButtonsView()
                            .tP16
                            .hp(DesignConstants.horizontalPadding),
                        _profileStatsView(user)
                            .tp(20)
                            .hp(DesignConstants.horizontalPadding),
                      ],
                    );
            }),
        Positioned(top: 0, left: 0, right: 0, child: appBar())
      ],
    );
  }

  Widget _profileBioView(UserModel user) {
    final bio = user.bio?.trim() ?? '';
    final joined = user.joinedMonthYear;

    return Column(
      children: [
        if (bio.isNotEmpty)
          BodyMediumText(
            bio,
            maxLines: 3,
            textAlign: TextAlign.center,
            weight: TextWeight.regular,
          ).bP8,
        if (joined.isNotEmpty)
          BodySmallText(
            '${joinedString.tr} $joined',
            color: AppColorConstants.subHeadingTextColor,
            textAlign: TextAlign.center,
          ),
      ],
    );
  }

  Widget _profileButtonsView() {
    final buttons = Row(
      children: [
        Expanded(
          child: AppThemeButton(
              height: 40,
              text: editProfileString.tr,
              onPress: () {
                Get.to(() => const UpdateProfile())!.then((value) {
                  loadData();
                });
              }),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: AppThemeBorderButton(
              height: 40,
              text: blockedUserString.tr,
              onPress: () {
                Get.to(() => const BlockedUsersList());
              }),
        ),
      ],
    ).bP8;

    return Column(
      children: [
        buttons,
        if (_profileController.user.value?.isVerified != true)
          AppThemeButton(
            height: 40,
            text: getVerifiedBadgeString.tr,
            leading: Image.asset(
              'assets/verified.png',
              height: 16,
              width: 16,
            ),
            onPress: () {
              _profileController.enableDemoVerifiedBadge();
            },
          ),
      ],
    );
  }

  Widget _profileStatsView(UserModel user) {
    return Container(
      color: AppColorConstants.cardColor.darken(),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Heading4Text(
                user.totalPost.toString(),
                weight: TextWeight.medium,
              ).bP8,
              BodySmallText(postsString.tr),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Heading4Text(
                '${user.totalFollower}',
                weight: TextWeight.medium,
              ).bP8,
              BodySmallText(followersString.tr),
            ],
          ).ripple(() {
            if (user.totalFollower > 0) {
              Get.to(() => FollowerFollowingList(
                        isFollowersList: true,
                        userId: _userProfileManager.user.value!.id,
                      ))!
                  .then((value) {
                loadData();
              });
            }
          }),
          Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Heading4Text(
                '${user.totalFollowing}',
                weight: TextWeight.medium,
              ).bP8,
              BodySmallText(followingString.tr),
            ],
          ).ripple(() {
            if (user.totalFollowing > 0) {
              Get.to(() => FollowerFollowingList(
                      isFollowersList: false,
                      userId: _userProfileManager.user.value!.id))!
                  .then((value) {
                loadData();
              });
            }
          }),
        ],
      ).p16,
    ).round(15);
  }

  Widget appBar() {
    return SizedBox(
      // color: Colors.black26,
      height: 100,
      child: widget.showBack == true
          ? backNavigationBarWithIcon(
              title: '',
              icon: ThemeIcon.setting,
              iconColor: AppColorConstants.themeColor,
              iconBtnClicked: () {
                Get.to(() => const Settings());
              }).tp(40)
          : titleNavigationBarWithIcon(
              title: '',
              icon: ThemeIcon.setting,
              iconColor: AppColorConstants.themeColor,
              completion: () {
                Get.to(() => const Settings());
              }).tp(40),
    );
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverAppBarDelegate(this._tabBar);

  final TabBar _tabBar;

  @override
  double get minExtent => _tabBar.preferredSize.height;

  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: AppColorConstants.backgroundColor,
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
}
