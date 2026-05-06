import 'package:foap/screens/login_sign_up/splash_screen.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../helper/imports/common_import.dart';
import '../../util/shared_prefs.dart';

class AskToFollow extends StatelessWidget {
  const AskToFollow({super.key});

  static const List<Map<String, String>> _rdPillars = [
    {
      'title': 'RD insider',
      'subtitle': "news, drops & what's next",
    },
    {
      'title': 'RD culture',
      'subtitle': 'creators, podcasts & live TV vibes',
    },
    {
      'title': 'RD family',
      'subtitle': 'connect, support & grow together',
    },
    {
      'title': 'RD edge',
      'subtitle': 'earn, create & own your opportunities',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColorConstants.backgroundColor,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColorConstants.backgroundColor,
              AppColorConstants.themeColor.withValues(alpha: 0.08),
              AppColorConstants.backgroundColor,
            ],
            stops: const [0.0, 0.45, 1.0],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: IntrinsicHeight(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const SizedBox(height: 24),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(26),
                          child: Image.asset(
                            'assets/rd_logo_new.jpeg',
                            height: 120,
                            width: 120,
                            fit: BoxFit.cover,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'RD your creative home',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 34,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.5,
                            color: AppColorConstants.mainTextColor,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'where culture, community, and opportunity connect',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.manrope(
                            fontSize: 17,
                            height: 1.45,
                            fontWeight: FontWeight.w500,
                            color: AppColorConstants.mainTextColor
                                .withValues(alpha: 0.82),
                          ),
                        ).hp(8),
                        const SizedBox(height: 30),
                        Container(
                          decoration: BoxDecoration(
                            color: AppColorConstants.cardColor
                                .withValues(alpha: 0.28),
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(
                              color: AppColorConstants.themeColor
                                  .withValues(alpha: 0.2),
                            ),
                          ),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 18),
                          child: Column(
                            children: _rdPillars
                                .map((item) => _PillarTile(
                                      title: item['title']!,
                                      subtitle: item['subtitle']!,
                                    ))
                                .toList(),
                          ),
                        ),
                        const Spacer(),
                        const SizedBox(height: 24),
                        AppThemeButton(
                          text: nextString.tr,
                          onPress: () {
                            SharedPrefs().setTutorialSeen();
                            Get.offAll(() => const SplashScreen());
                          },
                        ).hP25,
                        const SizedBox(height: 24),
                      ],
                    ).hp(DesignConstants.horizontalPadding),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _PillarTile extends StatelessWidget {
  final String title;
  final String subtitle;

  const _PillarTile({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: AppColorConstants.backgroundColor.withValues(alpha: 0.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 4),
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: AppColorConstants.themeColor,
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: RichText(
              text: TextSpan(
                text: '$title ',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColorConstants.mainTextColor,
                ),
                children: [
                  TextSpan(
                    text: subtitle,
                    style: GoogleFonts.manrope(
                      fontSize: 15,
                      height: 1.4,
                      fontWeight: FontWeight.w500,
                      color: AppColorConstants.mainTextColor
                          .withValues(alpha: 0.86),
                    ),
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
