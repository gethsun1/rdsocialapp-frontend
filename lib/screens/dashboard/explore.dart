import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:foap/helper/imports/common_import.dart';
import '../../components/search_bar.dart';
import '../../components/sm_tab_bar.dart';
import '../../controllers/misc/explore_controller.dart';
import '../../controllers/post/post_controller.dart';
import '../../segmentAndMenu/horizontal_menu.dart';
import '../home_feed/quick_links.dart';
import '../reuseable_widgets/club_listing.dart';
import '../reuseable_widgets/hashtags.dart';
import '../reuseable_widgets/post_list.dart';
import '../reuseable_widgets/users_list.dart';

class Explore extends StatefulWidget {
  const Explore({super.key});

  @override
  State<Explore> createState() => _ExploreState();
}

class _ExploreState extends State<Explore> {
  final ExploreController exploreController = ExploreController();
  final PostController postController = Get.find();

  final List<QuickLink> exploreQuickLinks = [
    QuickLink(
      icon: 'assets/stories.png',
      heading: 'Story',
      subHeading: 'Story',
      linkType: QuickLinkType.story,
    ),
    QuickLink(
      icon: 'assets/highlights.png',
      heading: 'Highlights',
      subHeading: 'Highlights',
      linkType: QuickLinkType.highlights,
    ),
    QuickLink(
      icon: 'assets/live_users.png',
      heading: 'Live Users',
      subHeading: 'Live Users',
      linkType: QuickLinkType.liveUsers,
    ),
    QuickLink(
      icon: 'assets/competitions.png',
      heading: 'Competitions',
      subHeading: 'Competitions',
      linkType: QuickLinkType.competition,
    ),
    QuickLink(
      icon: 'assets/club_colored.png',
      heading: 'Clubs',
      subHeading: 'Clubs',
      linkType: QuickLinkType.clubs,
    ),
    QuickLink(
      icon: 'assets/tv/tv.png',
      heading: "TV's",
      subHeading: "TV's",
      linkType: QuickLinkType.tv,
    ),
    QuickLink(
      icon: 'assets/chat_colored.png',
      heading: 'Incognito Chat',
      subHeading: 'Incognito Chat',
      linkType: QuickLinkType.randomChat,
    ),
    QuickLink(
      icon: 'assets/podcast.png',
      heading: 'Pod Cast',
      subHeading: 'Pod Cast',
      linkType: QuickLinkType.podcast,
    ),
    QuickLink(
      icon: 'assets/events.png',
      heading: 'Events',
      subHeading: 'Events',
      linkType: QuickLinkType.events,
    ),
    QuickLink(
      icon: 'assets/dating.png',
      heading: 'Dating',
      subHeading: 'Dating',
      linkType: QuickLinkType.dating,
    ),
    QuickLink(
      icon: 'assets/reel.png',
      heading: 'Reels',
      subHeading: 'Reels',
      linkType: QuickLinkType.reel,
    ),
    QuickLink(
      icon: 'assets/ai.png',
      heading: 'ChatGPT',
      subHeading: 'ChatGPT',
      linkType: QuickLinkType.chatGPT,
    ),
  ];

  List<String> segments = [
    postsString.tr,
    accountString.tr,
    hashTagsString.tr,
    clubsString.tr,
  ];

  @override
  void initState() {
    super.initState();
  }

  @override
  void didUpdateWidget(covariant Explore oldWidget) {
    super.didUpdateWidget(oldWidget);
  }

  @override
  void dispose() {
    exploreController.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      bottom: false,
      child: Scaffold(
        backgroundColor: AppColorConstants.backgroundColor,
        body: KeyboardDismissOnTap(
            child: Column(
          children: [
            const SizedBox(
              height: 40,
            ),
            Row(
              children: [
                Expanded(
                  child: SFSearchBar(
                      showSearchIcon: true,
                      iconColor: AppColorConstants.themeColor,
                      onSearchChanged: (value) {
                        exploreController.searchTextChanged(value);
                      },
                      onSearchStarted: () {
                        //controller.startSearch();
                      },
                      onSearchCompleted: (searchTerm) {}),
                ),
                Obx(() => exploreController.searchText.isNotEmpty
                    ? Row(
                        children: [
                          const SizedBox(
                            width: 10,
                          ),
                          Container(
                            height: 50,
                            width: 50,
                            color: AppColorConstants.themeColor,
                            child: ThemeIconWidget(
                              ThemeIcon.close,
                              color: AppColorConstants.backgroundColor,
                              size: 25,
                            ),
                          ).round(20).ripple(() {
                            exploreController.closeSearch();
                          }),
                        ],
                      )
                    : Container())
              ],
            ).setPadding(
                left: DesignConstants.horizontalPadding,
                right: DesignConstants.horizontalPadding,
                top: 25),
            Expanded(
                child: DefaultTabController(
                    length: segments.length,
                    child: Obx(() => exploreController.searchText.isNotEmpty
                        ? Column(
                            children: [
                              SMTabBar(
                                tabs: segments,
                                canScroll: true,
                              ),
                              // segmentView(),
                              // divider(height: 0.2),
                              Expanded(
                                child: TabBarView(children: [
                                  PostList(
                                    postSource: PostSource.posts,
                                  ),
                                  UsersList(),
                                  HashTagsList(),
                                  ClubListing(),
                                ]),
                              )
                            ],
                          )
                        : QuickLinkWidget(
                            callback: () {},
                            links: exploreQuickLinks,
                          )))),
          ],
        )),
      ),
    );
  }

  Widget segmentView() {
    return HorizontalSegmentBar(
        width: Get.width,
        onSegmentChange: (segment) {
          exploreController.segmentChanged(segment);
        },
        segments: [
          topString.tr,
          accountString.tr,
          hashTagsString.tr,
          // locations,
        ]);
  }
}
