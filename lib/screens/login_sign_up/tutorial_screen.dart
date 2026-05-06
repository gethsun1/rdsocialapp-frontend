import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:foap/helper/imports/common_import.dart';
import 'package:foap/screens/login_sign_up/auth_tab.dart';
import 'package:foap/util/shared_prefs.dart';
import 'package:google_fonts/google_fonts.dart';

class TutorialScreen extends StatefulWidget {
  const TutorialScreen({super.key});

  @override
  TutorialScreenState createState() => TutorialScreenState();
}

class TutorialScreenState extends State<TutorialScreen> {
  int _current = 0;

  final List<String> visuals = const [
    'assets/svg/onboarding/orbit.svg',
    'assets/svg/onboarding/threads.svg',
    'assets/svg/onboarding/spectrum.svg',
    'assets/svg/onboarding/constellation.svg',
  ];

  final List<String> headings = const [
    'RD insider',
    'RD culture',
    'RD family',
    'RD edge',
  ];

  final List<String> subHeadings = const [
    "news, drops & what's next",
    'creators, podcasts & live TV vibes',
    'connect, support & grow together',
    'earn, create & own your opportunities',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: AppColorConstants.backgroundColor,
        body: Column(children: [
          Expanded(
            child: CarouselSlider(
              items: addImages(),
              options: CarouselOptions(
                  enlargeCenterPage: false,
                  enableInfiniteScroll: false,
                  height: double.infinity,
                  viewportFraction: 1,
                  onPageChanged: (index, reason) {
                    setState(() {
                      _current = index;
                    });
                  }),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: visuals.map((url) {
              int index = visuals.indexOf(url);
              return AnimatedContainer(
                duration: const Duration(milliseconds: 420),
                curve: Curves.easeOutCubic,
                width: _current == index ? 18.0 : 8.0,
                height: 8.0,
                margin:
                    const EdgeInsets.symmetric(vertical: 20.0, horizontal: 2.0),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: _current == index
                      ? AppColorConstants.themeColor
                      : AppColorConstants.dividerColor,
                ),
              );
            }).toList(),
          ),
          Text(
            headings[_current],
            textAlign: TextAlign.center,
            style: GoogleFonts.spaceGrotesk(
              color: AppColorConstants.themeColor,
              fontWeight: FontWeight.w700,
              fontSize: 27,
            ),
          ).setPadding(left: 50, right: 50),
          const SizedBox(
            height: 12,
          ),
          Text(
            subHeadings[_current],
            textAlign: TextAlign.center,
            style: GoogleFonts.manrope(
              fontSize: 17,
              height: 1.4,
              fontWeight: FontWeight.w500,
              color: AppColorConstants.mainTextColor.withValues(alpha: 0.85),
            ),
          ).setPadding(left: 25, right: 25),
          const SizedBox(
            height: 52,
          ),
          addActionBtn(),
          const SizedBox(
            height: 56,
          ),
        ]));
  }

  List<Widget> addImages() {
    return visuals
        .map((item) => Stack(
              fit: StackFit.expand,
              children: [
                Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF0E1E34),
                        Color(0xFF1D3552),
                        Color(0xFF253F60),
                      ],
                    ),
                  ),
                ),
                SvgPicture.asset(
                  item,
                  fit: BoxFit.cover,
                  placeholderBuilder: (context) => Container(
                    color: const Color(0xFF162A44),
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.14),
                      ],
                    ),
                  ),
                ),
              ],
            ))
        .toList();
  }

  Padding addActionBtn() {
    return AppThemeButton(
      onPress: () {
        SharedPrefs().setTutorialSeen();
        Get.to(() => const AuthTab());
      },
      text: signInString.tr,
    ).hP25;
  }
}
