import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:foap/helper/imports/common_import.dart';
import 'package:local_auth/local_auth.dart';

import '../dashboard/loading.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  late bool haveBiometricLogin = false;
  var localAuth = LocalAuthentication();
  RxInt bioMetricType = 0.obs;

  final List<String> onboardingVisuals = const [
    'assets/svg/onboarding/orbit.svg',
    'assets/svg/onboarding/threads.svg',
    'assets/svg/onboarding/spectrum.svg',
    'assets/svg/onboarding/constellation.svg',
  ];

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 6), () async {
      Get.offAll(() => const LoadingScreen());
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: AppColorConstants.backgroundColor,
        body: Stack(
          children: [
            CarouselSlider(
              items: [
                for (String visual in onboardingVisuals)
                  Stack(
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
                        visual,
                        fit: BoxFit.cover,
                        height: double.infinity,
                        width: double.infinity,
                        placeholderBuilder: (context) => Container(
                          color: const Color(0xFF162A44),
                        ),
                      ),
                    ],
                  )
              ],
              options: CarouselOptions(
                autoPlayInterval: const Duration(milliseconds: 3000),
                autoPlayAnimationDuration: const Duration(milliseconds: 1400),
                autoPlay: true,
                autoPlayCurve: Curves.easeInOutCubic,
                enlargeCenterPage: false,
                enableInfiniteScroll: true,
                height: double.infinity,
                viewportFraction: 1,
                onPageChanged: (index, reason) {},
              ),
            ),
            Container(
              height: double.infinity,
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.08),
                    Colors.black.withValues(alpha: 0.15),
                    Colors.black.withValues(alpha: 0.26),
                  ],
                ),
              ),
            ),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(22),
                    child: Image.asset(
                      'assets/rd_logo_new.jpeg',
                      height: 112,
                      width: 112,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(height: 16),
                  BodyLargeText(AppConfigConstants.appName,
                      weight: TextWeight.medium),
                  Heading6Text(
                    AppConfigConstants.appTagline.tr,
                  ),
                ],
              ).bp(200),
            ),
          ],
        ));
  }
}
