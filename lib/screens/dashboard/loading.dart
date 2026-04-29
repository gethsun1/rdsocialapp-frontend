import 'package:flutter/services.dart';
import 'package:foap/helper/imports/common_import.dart';

import 'package:local_auth/error_codes.dart' as auth_error;
import 'package:local_auth/local_auth.dart';

import '../../controllers/misc/subscription_packages_controller.dart';
import '../../manager/socket_manager.dart';
import '../../util/shared_prefs.dart';
import '../login_sign_up/set_user_name.dart';
import '../login_sign_up/tutorial_screen.dart';
import 'dashboard_screen.dart';

class LoadingScreen extends StatefulWidget {
  const LoadingScreen({super.key});

  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen> {
  final UserProfileManager _userProfileManager = Get.find();
  final SubscriptionPackageController packageController = Get.find();

  late bool haveBiometricLogin = false;
  var localAuth = LocalAuthentication();
  RxInt bioMetricType = 0.obs;
  late final Future<void> _startupFuture;
  bool _isRouting = false;

  @override
  void initState() {
    super.initState();
    _startupFuture = checkBiometric();
  }

  void openNextScreen() {
    if (_isRouting || !mounted) return;
    _isRouting = true;

    if (_userProfileManager.isLogin == true) {
      packageController.initiate();
      if (_userProfileManager.user.value!.userName.isNotEmpty) {
        Get.offAll(() => const DashboardScreen());

        getIt<SocketManager>().connect();
      } else {
        Get.offAll(() => const SetUserName());
      }
    } else {
      Get.offAll(() => const TutorialScreen());
    }
  }

  Future checkBiometric() async {
    try {
      bool bioMetricAuthStatus = await SharedPrefs().getBioMetricAuthStatus();
      if (bioMetricAuthStatus == true) {
        final List<BiometricType> availableBiometrics =
            await localAuth.getAvailableBiometrics();

        if (availableBiometrics.contains(BiometricType.face)) {
          bioMetricType.value = 1;
          return;
        } else if (availableBiometrics.contains(BiometricType.fingerprint)) {
          bioMetricType.value = 2;
          return;
        }
      }
    } catch (e) {
      debugPrint('[LoadingScreen] Biometric check failed: $e');
    }

    if (mounted) {
      openNextScreen();
    }
  }

  void biometricLogin() async {
    try {
      bool didAuthenticate = await localAuth.authenticate(
          localizedReason: 'Please authenticate to login into app');

      if (didAuthenticate == true) {
        openNextScreen();
      }
    } on PlatformException catch (e) {
      debugPrint('[LoadingScreen] Biometric login failed: ${e.code}');
      if (e.code == auth_error.notAvailable) {
        openNextScreen();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: AppColorConstants.backgroundColor,
        body: FutureBuilder<void>(
            future: _startupFuture,
            // a previously-obtained Future<String> or null
            builder: (BuildContext context, AsyncSnapshot<void> snapshot) {
              return bioMetricType.value == 0
                  ? Center(
                      child: CircularProgressIndicator(
                        color: AppColorConstants.themeColor,
                      ),
                    )
                  : Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.asset(
                            bioMetricType.value == 1
                                ? 'assets/face-id.png'
                                : 'assets/fingerprint.png',
                            height: 80,
                            width: 80,
                            color: AppColorConstants.themeColor,
                          ),
                          const SizedBox(
                            height: 50,
                          ),
                          Heading4Text(appLockedString.tr,
                              weight: TextWeight.medium),
                          const SizedBox(
                            height: 10,
                          ),
                          Heading4Text(
                            bioMetricType.value == 1
                                ? unlockAppWithFaceIdString.tr
                                : unlockAppWithTouchIdString.tr,
                          ),
                          const SizedBox(
                            height: 50,
                          ),
                          Heading3Text(
                            bioMetricType.value == 1
                                ? useFaceIdString.tr
                                : useTouchIdString.tr,
                            color: AppColorConstants.themeColor,
                          ).ripple(() {
                            biometricLogin();
                          }),
                        ],
                      ),
                    );
            }));
  }
}
