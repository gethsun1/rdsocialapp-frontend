import '../helper/user_profile_manager.dart';
import 'package:get/get.dart';

class FeatureModel {
  String? featureKey;
  bool isActive;

  FeatureModel({
    required this.featureKey,
    required this.isActive,
  });

  factory FeatureModel.fromJson(Map<String, dynamic> json) => FeatureModel(
        featureKey: json["feature_key"],
        isActive: json["is_active"] == 1,
      );
}

class SettingModel {
  String? siteName;
  String? email;
  String? phone;
  String? inAppPurchaseId;
  int? isUploadImage;
  int? isUploadVideo;
  int? uploadMaxFile;
  String? facebook;
  String? youtube;
  String? twitter;
  String? linkedin;
  String? pinterest;
  String? instagram;
  String? siteUrl;
  int watchVideoRewardCoins;
  String? latestVersion;
  String? maximumVideoDurationAllowed;
  String? freeLiveTvDurationToView;
  String? latestAppDownloadLink;
  String? disclaimerUrl;
  String? privacyPolicyUrl;
  String? termsOfServiceUrl;
  String? giphyApiKey;

  String? agoraApiKey;
  String? interstitialAdUnitIdForAndroid;
  String? interstitialAdUnitIdForiOS;
  String? rewardInterstitlAdUnitIdForAndroid;
  String? rewardInterstitialAdUnitIdForiOS;
  String? bannerAdUnitIdForAndroid;
  String? bannerAdUnitIdForiOS;
  String? fbInterstitialAdUnitIdForAndroid;
  String? fbInterstitialAdUnitIdForiOS;
  String? fbRewardInterstitialAdUnitIdForAndroid;
  String? fbRewardInterstitialAdUnitIdForiOS;
  String? networkToUse;
  String? stripePublishableKey;
  String? razorpayKey;
  String? imglyApiKey;

  int minWithdrawLimit;
  int minCoinsWithdrawLimit;
  double coinsValue;
  double serviceFee;

  String? pid;
  String? chatGPTKey;

  String? themeColor;
  String? bgColorForLightTheme;
  String? bgColorForDarkTheme;
  String? textColorForLightTheme;
  String? textColorForDarkTheme;
  String? font;
  bool darkLightModeSwitchEnabled;
  List<FeatureModel> features = [];
  String? iosAppLink;
  String? androidAppLink;

  SettingModel(
      {required this.email,
      required this.phone,
      required this.facebook,
      required this.youtube,
      required this.twitter,
      required this.linkedin,
      required this.pinterest,
      required this.instagram,
      required this.watchVideoRewardCoins,
      required this.latestVersion,
      required this.minWithdrawLimit,
      required this.minCoinsWithdrawLimit,
      required this.coinsValue,
      this.pid,
      required this.siteName,
      required this.inAppPurchaseId,
      required this.isUploadImage,
      required this.isUploadVideo,
      required this.uploadMaxFile,
      required this.siteUrl,
      required this.maximumVideoDurationAllowed,
      required this.freeLiveTvDurationToView,
      required this.latestAppDownloadLink,
      required this.disclaimerUrl,
      required this.privacyPolicyUrl,
      required this.termsOfServiceUrl,
      required this.giphyApiKey,
      required this.agoraApiKey,
// required this.googleMapApiKey,
      required this.interstitialAdUnitIdForAndroid,
      required this.interstitialAdUnitIdForiOS,
      required this.rewardInterstitlAdUnitIdForAndroid,
      required this.rewardInterstitialAdUnitIdForiOS,
      required this.bannerAdUnitIdForAndroid,
      required this.bannerAdUnitIdForiOS,
      required this.fbInterstitialAdUnitIdForAndroid,
      required this.fbInterstitialAdUnitIdForiOS,
      required this.fbRewardInterstitialAdUnitIdForAndroid,
      required this.fbRewardInterstitialAdUnitIdForiOS,
      required this.networkToUse,
      required this.serviceFee,
      required this.stripePublishableKey,
      required this.razorpayKey,
      required this.imglyApiKey,
      required this.chatGPTKey,
      required this.font,
      required this.themeColor,
      required this.bgColorForLightTheme,
      required this.bgColorForDarkTheme,
      required this.textColorForLightTheme,
      required this.textColorForDarkTheme,
      required this.darkLightModeSwitchEnabled,
      required this.features,
      this.iosAppLink,
      this.androidAppLink});

  static String? _readString(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final value = json[key];
      if (value == null) continue;
      final normalized = value.toString().trim();
      if (normalized.isNotEmpty && normalized.toLowerCase() != 'null') {
        return normalized;
      }
    }
    return null;
  }

  static int _readInt(Map<String, dynamic> json, List<String> keys,
      {int fallback = 0}) {
    for (final key in keys) {
      final value = json[key];
      if (value == null) continue;
      if (value is int) return value;
      if (value is double) return value.toInt();
      if (value is String) {
        final parsed = int.tryParse(value.trim());
        if (parsed != null) return parsed;
      }
    }
    return fallback;
  }

  static double _readDouble(Map<String, dynamic> json, List<String> keys,
      {double fallback = 0.0}) {
    for (final key in keys) {
      final value = json[key];
      if (value == null) continue;
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) {
        final parsed = double.tryParse(value.trim());
        if (parsed != null) return parsed;
      }
    }
    return fallback;
  }

  static List<FeatureModel> _readFeatures(dynamic rawFeatureList) {
    if (rawFeatureList is List) {
      return rawFeatureList
          .whereType<Map<String, dynamic>>()
          .map((e) => FeatureModel.fromJson(e))
          .toList();
    }

    if (rawFeatureList is Map<String, dynamic>) {
      return rawFeatureList.entries
          .map((entry) => FeatureModel(
                featureKey: entry.key,
                isActive: entry.value == true || entry.value == 1,
              ))
          .toList();
    }

    return [];
  }

  static bool _readBool(Map<String, dynamic> json, List<String> keys,
      {bool fallback = false}) {
    for (final key in keys) {
      final value = json[key];
      if (value == null) continue;
      if (value is bool) return value;
      if (value is num) return value != 0;
      if (value is String) {
        final normalized = value.trim().toLowerCase();
        if (normalized == 'true' || normalized == '1' || normalized == 'yes') {
          return true;
        }
        if (normalized == 'false' || normalized == '0' || normalized == 'no') {
          return false;
        }
      }
    }
    return fallback;
  }

  factory SettingModel.fromJson(Map<String, dynamic> json) => SettingModel(
      email: _readString(json, ["email"]),
      phone: _readString(json, ["phone"]),
      facebook: _readString(json, ["facebook"]),
      youtube: _readString(json, ["youtube"]),
      twitter: _readString(json, ["twitter"]),
      linkedin: _readString(json, ["linkedin"]),
      pinterest: _readString(json, ["pinterest"]),
      instagram: _readString(json, ["instagram"]),
      latestVersion: _readString(json, ["release_version", "version"]),
      watchVideoRewardCoins: _readInt(json, ["each_view_coin"]),
      minWithdrawLimit: _readInt(json, ["min_widhdraw_price"]),
      minCoinsWithdrawLimit: _readInt(json, ["min_coin_redeem"]),
      coinsValue: _readDouble(json, ["per_coin_value"], fallback: 0.0),
      pid: _readString(json, ["user_p_id"]),
      siteName: _readString(json, ["site_name", "app_name"]),
      inAppPurchaseId: _readString(json, ["in_app_purchase_id"]),
      isUploadImage: _readInt(json, ["is_upload_image"], fallback: 0),
      isUploadVideo: _readInt(json, ["is_upload_video"], fallback: 0),
      uploadMaxFile: _readInt(json, ["upload_max_file"], fallback: 0),
      siteUrl: _readString(json, ["site_url"]),
      maximumVideoDurationAllowed:
          _readString(json, ["maximum_video_duration_allowed"]),
      freeLiveTvDurationToView:
          _readString(json, ["free_live_tv_duration_to_view"]),
      latestAppDownloadLink: _readString(json, ["latest_app_download_link"]),
      disclaimerUrl: _readString(json, ["disclaimer_url"]),
      privacyPolicyUrl: _readString(json, ["privacy_policy_url"]),
      termsOfServiceUrl: _readString(json, ["terms_of_service_url"]),
      giphyApiKey: _readString(json, ["giphy_api_key"]),
      agoraApiKey: _readString(json, ["agora_api_key"]),
// googleMapApiKey: json["google_map_api_key"],
      interstitialAdUnitIdForAndroid:
          _readString(json, ["interstitial_ad_unit_id_for_android"]),
      interstitialAdUnitIdForiOS:
          _readString(json, ["interstitial_ad_unit_id_for_IOS"]),
      rewardInterstitlAdUnitIdForAndroid:
          _readString(json, ["reward_Interstitl_ad_unit_id_for_android"]),
      rewardInterstitialAdUnitIdForiOS:
          _readString(json, ["reward_interstitial_ad_unit_id_for_IOS"]),
      bannerAdUnitIdForAndroid:
          _readString(json, ["banner_ad_unit_id_for_android"]),
      bannerAdUnitIdForiOS: _readString(json, ["banner_ad_unit_id_for_IOS"]),
      fbInterstitialAdUnitIdForAndroid:
          _readString(json, ["fb_interstitial_ad_unit_id_for_android"]),
      fbInterstitialAdUnitIdForiOS:
          _readString(json, ["fb_interstitial_ad_unit_id_for_IOS"]),
      fbRewardInterstitialAdUnitIdForAndroid:
          _readString(json, ["fb_reward_interstitial_ad_unit_id_for_android"]),
      fbRewardInterstitialAdUnitIdForiOS:
          _readString(json, ["fb_reward_interstitial_ad_unit_id_for_IOS"]),
      networkToUse: _readString(json, ["network_to_use"]),
      serviceFee: _readDouble(json, ["serviceFee"], fallback: 5),
      stripePublishableKey: _readString(json, ["stripe_publishable_key"]),
      razorpayKey: _readString(json, ["razorpay_api_key"]),
      themeColor: _readString(json, ["theme_color", "themeColor"]) ?? '003366',
      bgColorForLightTheme: _readString(json, [
            "bg_color_for_light_theme",
            "bgColorForLightTheme",
            "theme_light_background_color"
          ]) ??
          'F8FBFF',
      bgColorForDarkTheme: _readString(json, [
            "bg_color_for_dark_theme",
            "bgColorForDarkTheme",
            "theme_dark_background_color"
          ]) ??
          '01041C',
      textColorForLightTheme: _readString(json, [
            "text_color_for_light_theme",
            "textColorForLightTheme",
            "theme_light_text_color"
          ]) ??
          '101426',
      textColorForDarkTheme: _readString(json, [
            "text_color_for_dark_theme",
            "textColorForDarkTheme",
            "theme_dark_text_color"
          ]) ??
          'FFFFFF',
      font: _readString(json, ["theme_font"]),
      chatGPTKey: _readString(json, ["chat_gpt_key"]),
      imglyApiKey: _readString(json, ["imgly_key"]),
      iosAppLink: _readString(json, ["iosAppLink"]) ?? 'ios app link',
      androidAppLink:
          _readString(json, ["androidAppLink"]) ?? 'android app link',
      darkLightModeSwitchEnabled: _readBool(json, [
        "enable_dark_light_mode_switch",
        "enableDarkLightModeSwitch",
        "enable_dark_light_mode_switching"
      ]),
      features: _readFeatures(json["featureList"]));

  bool getFeatureAvailabilityStatus(String featureName) {
    UserProfileManager userProfileManager = Get.find();

    if (userProfileManager.user.value == null) {
      return false;
    }

    List<FeatureModel> matchedFeatures =
        features.where((element) => element.featureKey == featureName).toList();

    if (matchedFeatures.isEmpty) {
      return false;
    }
    if (matchedFeatures.first.isActive == false) {
      return false;
    }
    List<FeatureModel> matchedFeaturesForUser = userProfileManager
        .user.value!.features
        .where((element) => element.featureKey == featureName)
        .toList();
    if (matchedFeaturesForUser.isEmpty) {
      return false;
    }

    return matchedFeaturesForUser.first.isActive;
  }

  bool get enableChatGPT {
    return getFeatureAvailabilityStatus('chat_gpt');
  }

  bool get enableImagePost {
    return getFeatureAvailabilityStatus('enable_photo_post');
  }

  bool get enableVideoPost {
    return getFeatureAvailabilityStatus('enable_video_post');
  }

  bool get enableStories {
    return getFeatureAvailabilityStatus('enable_story');
  }

  bool get enableHighlights {
    return getFeatureAvailabilityStatus('enable_story_highlights');
  }

  bool get enableChat {
    return getFeatureAvailabilityStatus('enable_chat');
  }

  bool get enableLocationSharingInChat {
    return getFeatureAvailabilityStatus('location_share');
  }

  bool get enablePhotoSharingInChat {
    return getFeatureAvailabilityStatus('photo_sharing');
  }

  bool get enableContactSharingInChat {
    return getFeatureAvailabilityStatus('contact_share');
  }

  bool get enableVideoSharingInChat {
    return getFeatureAvailabilityStatus('video_share');
  }

  bool get enableAudioSharingInChat {
    return getFeatureAvailabilityStatus('audio_share');
  }

  bool get enableFileSharingInChat {
    return getFeatureAvailabilityStatus('file_Share');
  }

  bool get enableGifSharingInChat {
    return getFeatureAvailabilityStatus('gif_share');
  }

  bool get enableDrawingSharingInChat {
    return getFeatureAvailabilityStatus('drawing_share');
  }

  bool get enableClubSharingInChat {
    return getFeatureAvailabilityStatus('club_share');
  }

  bool get enableProfileSharingInChat {
    return getFeatureAvailabilityStatus('user_profile_share');
  }

  bool get enableReplyInChat {
    return getFeatureAvailabilityStatus('reply');
  }

  bool get enableForwardingInChat {
    return getFeatureAvailabilityStatus('forward');
  }

  bool get enableStarMessage {
    return getFeatureAvailabilityStatus('star_message');
  }

  bool get enableAudioCalling {
    return getFeatureAvailabilityStatus('enable_audio_calling') &&
        (agoraApiKey?.isNotEmpty ?? false);
  }

  bool get enableVideoCalling {
    return getFeatureAvailabilityStatus('enable_video_calling') &&
        (agoraApiKey?.isNotEmpty ?? false);
  }

  bool get enableLive {
    return getFeatureAvailabilityStatus('enable_live') &&
        (agoraApiKey?.isNotEmpty ?? false);
  }

  bool get enableClubs {
    return getFeatureAvailabilityStatus('enable_clubs');
  }

  bool get enableCompetitions {
    return getFeatureAvailabilityStatus('enable_competitions');
  }

  bool get enableEvents {
    return getFeatureAvailabilityStatus('enable_events');
  }

  bool get enableStrangerChat {
    return getFeatureAvailabilityStatus('enable_staranger_chat');
  }

  bool get enableProfileVerification {
    return getFeatureAvailabilityStatus('enable_profile_verification');
  }

  bool get enableDarkLightModeSwitch {
    return darkLightModeSwitchEnabled ||
        getFeatureAvailabilityStatus('enable_dark_light_mode_switching');
  }

  bool get enableWatchTv {
    return getFeatureAvailabilityStatus('enable_watch_tv');
  }

  bool get enablePodcasts {
    return getFeatureAvailabilityStatus('enable_podcasts');
  }

  bool get enableGift {
    return getFeatureAvailabilityStatus('enable_gift_sending');
  }

  bool get enablePostPhotoVideoEdit {
    return getFeatureAvailabilityStatus('photo_video_editable');
  }

  bool get enablePolls {
    return getFeatureAvailabilityStatus('polls');
  }

  bool get enableFundRaising {
    return getFeatureAvailabilityStatus('enable_fund_raising');
  }

  bool get enableOffers {
    return getFeatureAvailabilityStatus('offer');
  }

  bool get enableJobs {
    return getFeatureAvailabilityStatus('job');
  }

  bool get enableShop {
    return getFeatureAvailabilityStatus('shop');
  }

  bool get enableLiveUserListing {
    return getFeatureAvailabilityStatus('live_user');
  }

  bool get enableReel {
    return getFeatureAvailabilityStatus('reel');
  }

  bool get enableDating {
    return getFeatureAvailabilityStatus('dating');
  }

  bool get canEditPhotoVideo {
    return enablePostPhotoVideoEdit;
  }
}
