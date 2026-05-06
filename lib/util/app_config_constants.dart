import '../helper/color_extension.dart';
import '../helper/imports/common_import.dart';
import '../screens/settings_menu/settings_controller.dart';
import 'constant_util.dart';

final SettingsController settingsController = Get.find();

class AppConfigConstants {
  // Name of app
  static String appName = 'RD';

  static String currentVersion = '2.3';
  static const liveAppLink = 'https://rdsocialapp.co.ke/';

  static String appTagline = 'Connect, converse, and stream live';
  static const googleMapApiKey = 'AIzaSyA4vcqErGvq5NRbvhvq8JKSp0VFpNBBPjE';

  static const restApiBaseUrl = 'https://api.rdsocialapp.co.ke/';

  // Keep explicit :443 for better socket client compatibility on some devices.
  static const socketApiBaseUrl = "https://api.rdsocialapp.co.ke:443";

  // Firebase-only mode: use Firebase auth providers and avoid backend auth APIs.
  static const useFirebaseOnlyMode = true;

  // Use Firebase Auth for email/password flows.
  static const useFirebaseAuthForEmailPassword = useFirebaseOnlyMode;

  // Use Firebase Auth for Google sign-in flow.
  static const useFirebaseAuthForGoogleSignIn = useFirebaseOnlyMode;

  // Even in Firebase-auth mode, most app modules still depend on backend APIs.
  // Keep this enabled so post-login obtains a real backend auth_key.
  static const requireBackendSessionAfterFirebaseAuth = true;

  // Allow app login to continue with Firebase-only local session when backend
  // bridge is unreachable (useful while backend setup is pending).
  static const allowFirebaseLoginWithoutBackendSession = true;

  // Backend `users/login-social` provider used for Firebase-authenticated users.
  // Change this to match backend allow-list if needed (e.g. `google`).
  static const firebaseBackendSocialType = 'firebase';

  // Legacy bridge fallback (`social_type=google`) for older backends that
  // don't accept `social_type=firebase` yet. Keep disabled for strict
  // single-backend contract on current Django VPS.
  static const allowLegacyGoogleSocialTypeFallback = false;

  // Firebase Web OAuth client ID (client_type: 3) required by GoogleSignIn
  // to reliably fetch tokens for Firebase credential exchange.
  static const firebaseWebClientId =
      '659874334588-juo6pp6lp1to8hh5jmshd8p2fmhm6vda.apps.googleusercontent.com';

  // Chat encryption key -- DO NOT CHANGE THIS
  static const encryptionKey = 'bbC2H19lkVbQDfakxcrtNMQdd0FloLyw';

  // Local fallback for builds where backend settings are not yet configured.
  static const fallbackAgoraAppId = '510ff736f6b74b0a8efeb9ac38372932';

  // White-label deployments: keep disabled unless you explicitly want app-blocking
  // force updates based on backend version values.
  static const enforceForceUpdateGate = false;

  // enable encryption -- DO NOT CHANGE THIS
  static const int enableEncryption = 1;

  // chat version
  static const int chatVersion = 1;

  // is demo app
  static const bool isDemoApp = false;

  // parameters for delete chat
  static const secondsInADay = 86400;
  static const secondsInThreeDays = 259200;
  static const secondsInSevenDays = 604800;
  static const liveBattleConfirmationWaitTime = 30;
}

class DesignConstants {
  static double horizontalPadding = 24;
}

class AppColorConstants {
  static Color rdPrimary = HexColor.fromHex('003366');
  static Color rdSecondary = HexColor.fromHex('FF9900');
  static Color rdAccent = HexColor.fromHex('FF9900');
  static Color rdDark = HexColor.fromHex('01041C');

  static Color themeColor = settingsController.setting.value == null
      ? rdPrimary
      : HexColor.fromHex(settingsController.setting.value!.themeColor!);

  static Color get backgroundColor => isDarkMode
      ? HexColor.fromHex(
          settingsController.setting.value?.bgColorForDarkTheme ?? '01041C')
      : HexColor.fromHex(
          settingsController.setting.value?.bgColorForLightTheme ?? 'F8FBFF');

  static Color get cardColor =>
      isDarkMode ? HexColor.fromHex('636e72') : HexColor.fromHex('dfe6e9');

  static Color get dividerColor => isDarkMode
      ? const Color(0xFFFFFFFF).withOpacity(0.4)
      : Colors.grey.withOpacity(0.7);

  static Color get borderColor =>
      isDarkMode ? Colors.white.withOpacity(0.9) : Colors.grey.withOpacity(0.2);

  static Color get disabledColor =>
      isDarkMode ? Colors.grey.withOpacity(0.2) : Colors.grey.withOpacity(0.2);

  static Color get shadowColor => isDarkMode
      ? Colors.white.withOpacity(0.2)
      : Colors.black.withOpacity(0.2);

  // static Color get inputFieldBackgroundColor =>
  //     isDarkMode ? const Color(0xFF212121) : const Color(0xFF212121);

  static Color get iconColor =>
      isDarkMode ? Colors.white : const Color(0xFF212121);

  static Color get inputFieldTextColor =>
      isDarkMode ? const Color(0xFFFAFAFA) : const Color(0xFF212121);

  static Color get inputFieldPlaceholderTextColor => isDarkMode
      ? const Color(0xFFFAFAFA).lighten()
      : const Color(0xFF212121).darken();

  static Color get red => isDarkMode ? Colors.red : Colors.red;

  static Color get green => isDarkMode ? Colors.green : Colors.green;

  // text colors

  static Color get mainTextColor => isDarkMode
      ? settingsController.setting.value == null
          ? Colors.white
          : HexColor.fromHex(
              settingsController.setting.value!.textColorForDarkTheme!)
      : settingsController.setting.value == null
          ? Colors.black
          : HexColor.fromHex(
              settingsController.setting.value!.textColorForLightTheme!);

  // static Color get mainTextColor => isDarkMode
  //     ? settingsController.setting.value == null
  //         ? Colors.white.withOpacity(0.8)
  //         : HexColor.fromHex(
  //                 settingsController.setting.value!.textColorForDarkTheme!)
  //             .withOpacity(0.8)
  //     : settingsController.setting.value == null
  //         ? Colors.black.withOpacity(0.8)
  //         : HexColor.fromHex(
  //                 settingsController.setting.value!.textColorForLightTheme!)
  //             .withOpacity(0.8);
  //
  // static Color get mainTextColor => isDarkMode
  //     ? settingsController.setting.value == null
  //         ? Colors.white.withOpacity(0.7)
  //         : HexColor.fromHex(
  //                 settingsController.setting.value!.textColorForDarkTheme!)
  //             .withOpacity(0.7)
  //     : settingsController.setting.value == null
  //         ? Colors.black.withOpacity(0.7)
  //         : HexColor.fromHex(
  //                 settingsController.setting.value!.textColorForLightTheme!)
  //             .withOpacity(0.7);

  static Color get subHeadingTextColor => isDarkMode
      ? settingsController.setting.value == null
          ? const Color(0xFF34495e)
          : HexColor.fromHex(
                  settingsController.setting.value!.textColorForDarkTheme!)
              .withOpacity(0.8)
      : settingsController.setting.value == null
          ? const Color(0xFFecf0f1)
          : HexColor.fromHex(
                  settingsController.setting.value!.textColorForLightTheme!)
              .withOpacity(0.8);
}

class DatingProfileConstants {
  static List<String> genders = ['Male', 'Female', 'Other'];
  static List<String> colors = ['Black', 'White', 'Brown'];
  static List<String> religions = [
    'Christians',
    'Muslims',
    'Hindus',
    'Buddhists',
    'Sikhs',
    'Jainism',
    'Judaism'
  ];
  static List<String> maritalStatus = ['Single', 'Married', 'Divorced'];
  static List<String> drinkHabits = ['Regular', 'Planning to quit', 'Socially'];
}
