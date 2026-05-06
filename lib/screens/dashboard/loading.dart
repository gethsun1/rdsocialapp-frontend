import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:foap/helper/imports/common_import.dart';
import 'package:image_picker/image_picker.dart';

import 'package:local_auth/error_codes.dart' as auth_error;
import 'package:local_auth/local_auth.dart';

import '../../controllers/misc/subscription_packages_controller.dart';
import '../../helper/file_extension.dart';
import '../../manager/socket_manager.dart';
import '../chat/media.dart';
import '../../util/shared_prefs.dart';
import '../login_sign_up/ask_to_follow.dart';
import '../login_sign_up/auth_tab.dart';
import '../login_sign_up/signup_profile_setup.dart';
import '../post/add_post_screen.dart';
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
  List<Media> _recoveredPostMedia = [];

  @override
  void initState() {
    super.initState();
    _startupFuture = checkBiometric();
  }

  Future<void> _restoreSavedSessionIfNeeded() async {
    if (_userProfileManager.isLogin == true) {
      return;
    }

    final authKey = await SharedPrefs().getAuthorizationKey();
    if (authKey == null || authKey.isEmpty) {
      return;
    }

    await _userProfileManager.refreshProfile();
  }

  Future<void> openNextScreen() async {
    if (_isRouting || !mounted) return;
    _isRouting = true;

    await _restoreSavedSessionIfNeeded();
    if (!mounted) return;

    if (_userProfileManager.isLogin == true) {
      final setupPending = await SharedPrefs().getSignupProfileSetupPending();
      final profileNeedsSetup =
          _userProfileManager.user.value?.requiresSignupProfileSetup ?? false;
      if (!mounted) return;
      if (setupPending || profileNeedsSetup) {
        await SharedPrefs().setSignupProfileSetupPending(true);
        Get.offAll(() => const SignupProfileSetup());
        return;
      }

      packageController.initiate();
      Get.offAll(() => const DashboardScreen());
      getIt<SocketManager>().connect();
      _openRecoveredPostComposerIfNeeded();
    } else {
      final tutorialSeen = await SharedPrefs().getTutorialSeen();
      if (!mounted) return;
      Get.offAll(() => tutorialSeen ? const AuthTab() : const AskToFollow());
    }
  }

  Future<void> recoverLostPickerData() async {
    try {
      final LostDataResponse response = await ImagePicker().retrieveLostData();
      if (response.isEmpty) {
        return;
      }

      final List<XFile>? files = response.files;
      if (files == null || files.isEmpty) {
        debugPrint(
            '[LoadingScreen] retrieveLostData has no files: ${response.exception}');
        return;
      }

      final List<Media> recovered = [];
      for (final file in files) {
        final detectedType = File(file.path).mediaType;
        if (detectedType != GalleryMediaType.photo &&
            detectedType != GalleryMediaType.video) {
          continue;
        }
        recovered.add(await file.toMedia(detectedType));
      }

      if (recovered.isNotEmpty) {
        _recoveredPostMedia = recovered;
      }
    } catch (e) {
      debugPrint('[LoadingScreen] retrieveLostData failed: $e');
    }
  }

  void _openRecoveredPostComposerIfNeeded() {
    if (_recoveredPostMedia.isEmpty) {
      return;
    }

    final items = List<Media>.from(_recoveredPostMedia);
    _recoveredPostMedia = [];

    Future.delayed(const Duration(milliseconds: 500), () {
      if (Get.context == null) return;
      AppUtil.showToast(
          message: 'Recovered your captured media. Continue posting.',
          isSuccess: true);
      Get.to(() => AddPostScreen(
            postType: PostType.basic,
            items: items,
            postCompletionHandler: () {},
          ));
    });
  }

  Future checkBiometric() async {
    await recoverLostPickerData();

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
      unawaited(openNextScreen());
    }
  }

  void biometricLogin() async {
    try {
      bool didAuthenticate = await localAuth.authenticate(
          localizedReason: 'Please authenticate to login into app');

      if (didAuthenticate == true) {
        unawaited(openNextScreen());
      }
    } on PlatformException catch (e) {
      debugPrint('[LoadingScreen] Biometric login failed: ${e.code}');
      if (e.code == auth_error.notAvailable) {
        unawaited(openNextScreen());
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
