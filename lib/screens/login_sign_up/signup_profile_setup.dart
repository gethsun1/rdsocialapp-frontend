import 'package:flutter/cupertino.dart';
import 'package:foap/api_handler/apis/profile_api.dart';
import 'package:foap/api_handler/apis/users_api.dart';
import 'package:foap/controllers/profile/profile_controller.dart';
import 'package:foap/helper/imports/common_import.dart';
import 'package:foap/helper/list_extension.dart';
import 'package:foap/manager/location_manager.dart';
import 'package:foap/manager/socket_manager.dart';
import 'package:foap/screens/dashboard/dashboard_screen.dart';
import 'package:foap/util/shared_prefs.dart';
import 'package:foap/util/username_validator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

class SignupProfileSetup extends StatefulWidget {
  const SignupProfileSetup({super.key});

  @override
  State<SignupProfileSetup> createState() => _SignupProfileSetupState();
}

class _SignupProfileSetupState extends State<SignupProfileSetup> {
  static const int _stepCount = 4;

  final ProfileController _profileController = Get.find();
  final UserProfileManager _userProfileManager = Get.find();
  final ImagePicker _picker = ImagePicker();
  final PageController _pageController = PageController();
  final ScrollController _suggestionsScrollController = ScrollController();
  final TextEditingController _usernameController = TextEditingController();

  DateTime? _dateOfBirth;
  int _currentStep = 0;
  bool _isSubmitting = false;
  bool _isLoadingSuggestions = false;
  bool _hasMoreSuggestions = true;
  int _suggestionsPage = 1;
  final List<UserModel> _suggestedUsers = [];

  DateTime get _latestAllowedDob {
    final now = DateTime.now();
    return DateTime(now.year - 13, now.month, now.day);
  }

  @override
  void initState() {
    super.initState();
    final user = _userProfileManager.user.value;
    if (user != null) {
      _profileController.setUser(user);
      _usernameController.text = user.userName;
      _profileController.verifyUsername(userName: user.userName);
      _dateOfBirth = _parseBackendDate(user.dob);
    }
    _suggestionsScrollController.addListener(_loadMoreSuggestionsIfNeeded);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _suggestionsScrollController.dispose();
    _usernameController.dispose();
    super.dispose();
  }

  Future<void> _goToStep(int step) async {
    setState(() {
      _currentStep = step;
    });
    await _pageController.animateToPage(
      step,
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
    );
    if (step == 3) {
      _fetchSuggestedUsers();
    }
  }

  Future<void> _continueFromUsername() async {
    if (_isSubmitting) return;

    final normalizedUserName =
        UsernameValidator.normalize(_usernameController.text);
    if (!UsernameValidator.isValid(normalizedUserName)) {
      AppUtil.showToast(
          message: pleaseEnterValidUserNameString.tr, isSuccess: false);
      return;
    }

    setState(() {
      _isSubmitting = true;
    });
    final updated = await ProfileApi.updateSignupProfile(
      userName: normalizedUserName,
      failureCallback: (message) {
        AppUtil.showToast(message: message, isSuccess: false);
      },
    );
    if (updated) {
      await _profileController.getMyProfile();
      await _goToStep(1);
    }
    if (mounted) {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  Future<void> _continueFromImages() async {
    final user =
        _profileController.user.value ?? _userProfileManager.user.value;
    if (user == null) return;

    if ((user.picture ?? '').trim().isEmpty) {
      AppUtil.showToast(
          message: 'Please add a profile image to continue.', isSuccess: false);
      return;
    }
    if ((user.coverImage ?? '').trim().isEmpty) {
      AppUtil.showToast(
          message: 'Please add a cover image to continue.', isSuccess: false);
      return;
    }
    await _goToStep(2);
  }

  Future<void> _continueFromDateOfBirth() async {
    if (_isSubmitting) return;
    final dob = _dateOfBirth;
    if (dob == null) {
      AppUtil.showToast(
          message: 'Please add your date of birth to continue.',
          isSuccess: false);
      return;
    }
    if (dob.isAfter(_latestAllowedDob)) {
      AppUtil.showToast(
          message: 'You must be at least 13 years old to use RD.',
          isSuccess: false);
      return;
    }

    setState(() {
      _isSubmitting = true;
    });
    final updated = await ProfileApi.updateSignupProfile(
      dateOfBirth: _formatBackendDate(dob),
      failureCallback: (message) {
        AppUtil.showToast(message: message, isSuccess: false);
      },
    );
    if (updated) {
      await _profileController.getMyProfile();
      await _goToStep(3);
    }
    if (mounted) {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  Future<void> _finishSetup() async {
    if (_isSubmitting) return;
    setState(() {
      _isSubmitting = true;
    });
    await SharedPrefs().setSignupProfileSetupPending(false);
    getIt<LocationManager>().postLocation();
    getIt<SocketManager>().connect();
    Get.offAll(() => const DashboardScreen());
  }

  Future<void> _pickImage({required bool isCoverImage}) async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: AppColorConstants.backgroundColor,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: Icon(Icons.camera_alt_outlined,
                  color: AppColorConstants.iconColor),
              title: BodyLargeText(takePhotoString.tr),
              onTap: () => Get.back(result: ImageSource.camera),
            ),
            divider(),
            ListTile(
              leading: Icon(Icons.wallpaper_outlined,
                  color: AppColorConstants.iconColor),
              title: BodyLargeText(chooseFromGalleryString.tr),
              onTap: () => Get.back(result: ImageSource.gallery),
            ),
          ],
        ),
      ),
    );

    if (source == null) return;

    final pickedFile = await _picker.pickImage(source: source);
    if (pickedFile == null) return;

    await _profileController.updateProfileImageForSignupSetup(
      pickedFile,
      isCoverImage,
    );
  }

  Future<void> _selectDateOfBirth() async {
    final selected = await showModalBottomSheet<DateTime>(
      context: context,
      backgroundColor: AppColorConstants.backgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        var draftDate = _dateOfBirth ?? _latestAllowedDob;
        return SafeArea(
          child: SizedBox(
            height: 360,
            child: Column(
              children: [
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                  child: Row(
                    children: [
                      BodyLargeText('Date of birth',
                          weight: TextWeight.semiBold),
                      const Spacer(),
                      BodyLargeText(doneString.tr,
                              weight: TextWeight.semiBold,
                              color: AppColorConstants.themeColor)
                          .ripple(() => Get.back(result: draftDate)),
                    ],
                  ),
                ),
                divider(),
                Expanded(
                  child: CupertinoDatePicker(
                    mode: CupertinoDatePickerMode.date,
                    initialDateTime: draftDate,
                    maximumDate: _latestAllowedDob,
                    minimumYear: 1900,
                    maximumYear: _latestAllowedDob.year,
                    onDateTimeChanged: (value) {
                      draftDate = value;
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (selected != null) {
      setState(() {
        _dateOfBirth = selected;
      });
    }
  }

  void _fetchSuggestedUsers() {
    if (_isLoadingSuggestions || !_hasMoreSuggestions) return;

    setState(() {
      _isLoadingSuggestions = true;
    });
    UsersApi.getSuggestedUsers(
      page: _suggestionsPage,
      resultCallback: (users) {
        if (!mounted) return;
        setState(() {
          _suggestedUsers.addAll(users);
          _suggestedUsers.unique((e) => e.id);
          _suggestionsPage += 1;
          _hasMoreSuggestions = users.isNotEmpty;
          _isLoadingSuggestions = false;
        });
      },
    );
  }

  void _loadMoreSuggestionsIfNeeded() {
    if (!_suggestionsScrollController.hasClients) return;
    final position = _suggestionsScrollController.position;
    if (position.pixels >= position.maxScrollExtent - 240) {
      _fetchSuggestedUsers();
    }
  }

  void _toggleFollow(UserModel user) {
    final isFollowing = user.followingStatus != FollowingStatus.notFollowing;
    setState(() {
      user.followingStatus = isFollowing
          ? FollowingStatus.notFollowing
          : FollowingStatus.following;
    });
    UsersApi.followUnfollowUser(isFollowing: !isFollowing, user: user);
  }

  DateTime? _parseBackendDate(String? value) {
    final normalized = (value ?? '').trim();
    if (normalized.isEmpty) return null;
    return DateTime.tryParse(normalized);
  }

  String _formatBackendDate(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }

  String _formatDisplayDate(DateTime date) {
    return DateFormat('MMM d, yyyy').format(date);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: AppColorConstants.backgroundColor,
        body: SafeArea(
          child: Obx(() {
            final user =
                _profileController.user.value ?? _userProfileManager.user.value;
            return user == null
                ? Center(
                    child: CircularProgressIndicator(
                      color: AppColorConstants.themeColor,
                    ),
                  )
                : Column(
                    children: [
                      _progressHeader(),
                      Expanded(
                        child: PageView(
                          controller: _pageController,
                          physics: const NeverScrollableScrollPhysics(),
                          children: [
                            _usernameScreen(),
                            _imagesScreen(user),
                            _dateOfBirthScreen(),
                            _followSuggestionsScreen(),
                          ],
                        ),
                      ),
                    ],
                  );
          }),
        ),
      ),
    );
  }

  Widget _progressHeader() {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        DesignConstants.horizontalPadding,
        18,
        DesignConstants.horizontalPadding,
        6,
      ),
      child: Column(
        children: [
          Row(
            children: List.generate(
              _stepCount,
              (index) => Expanded(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  height: 4,
                  margin:
                      EdgeInsets.only(right: index == _stepCount - 1 ? 0 : 8),
                  decoration: BoxDecoration(
                    color: index <= _currentStep
                        ? AppColorConstants.themeColor
                        : AppColorConstants.dividerColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              BodyMediumText('Step ${_currentStep + 1} of $_stepCount',
                  color:
                      AppColorConstants.mainTextColor.withValues(alpha: 0.7)),
              const Spacer(),
              BodyMediumText('RD',
                  weight: TextWeight.semiBold,
                  color: AppColorConstants.themeColor),
            ],
          ),
        ],
      ),
    );
  }

  Widget _screenShell({
    required String title,
    required String subtitle,
    required Widget child,
    required String buttonText,
    required VoidCallback onNext,
    Widget? secondaryAction,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: DesignConstants.horizontalPadding,
              vertical: 16,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Heading3Text(title, weight: TextWeight.bold),
                const SizedBox(height: 8),
                BodyLargeText(
                  subtitle,
                  color:
                      AppColorConstants.mainTextColor.withValues(alpha: 0.75),
                ),
                const SizedBox(height: 30),
                child,
              ],
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(
            DesignConstants.horizontalPadding,
            8,
            DesignConstants.horizontalPadding,
            18,
          ),
          child: Column(
            children: [
              AppThemeButton(
                text: _isSubmitting ? loadingString.tr : buttonText,
                onPress: _isSubmitting ? () {} : onNext,
              ),
              if (secondaryAction != null) ...[
                const SizedBox(height: 12),
                secondaryAction,
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _usernameScreen() {
    return _screenShell(
      title: setUserNameString.tr,
      subtitle:
          'Pick a public RD username with letters, numbers, underscores, or dots.',
      buttonText: nextString.tr,
      onNext: _continueFromUsername,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          BodyLargeText(userNameString.tr, weight: TextWeight.semiBold),
          const SizedBox(height: 10),
          Stack(
            children: [
              AppTextField(
                controller: _usernameController,
                maxLength: 20,
                onChanged: (value) {
                  _profileController.verifyUsername(userName: value);
                },
              ),
              Positioned(
                right: 0,
                bottom: 0,
                top: 0,
                child: Center(
                  child: Obx(
                    () => _profileController.userNameCheckStatus.value == 1
                        ? ThemeIconWidget(
                            ThemeIcon.checkMark,
                            color: AppColorConstants.themeColor,
                          )
                        : _profileController.userNameCheckStatus.value == 0
                            ? ThemeIconWidget(
                                ThemeIcon.close,
                                color: AppColorConstants.red,
                              )
                            : Container(),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          BodySmallText(
            '3-20 characters. No spaces, email addresses, @, #, %, or symbols.',
            color: AppColorConstants.mainTextColor.withValues(alpha: 0.62),
          ),
        ],
      ),
    );
  }

  Widget _imagesScreen(UserModel user) {
    return _screenShell(
      title: 'Add your photos',
      subtitle: 'Add a profile image and cover image before entering RD.',
      buttonText: nextString.tr,
      onNext: _continueFromImages,
      child: _coverPicker(user),
    );
  }

  Widget _dateOfBirthScreen() {
    return _screenShell(
      title: 'Date of birth',
      subtitle: 'This helps keep RD age-appropriate. You must be 13 or older.',
      buttonText: nextString.tr,
      onNext: _continueFromDateOfBirth,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          BodyLargeText('Birthday', weight: TextWeight.semiBold),
          const SizedBox(height: 10),
          Container(
            height: 56,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: AppColorConstants.cardColor.darken(0.02),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Expanded(
                  child: BodyLargeText(
                    _dateOfBirth == null
                        ? 'Select your date of birth'
                        : _formatDisplayDate(_dateOfBirth!),
                    color: _dateOfBirth == null
                        ? AppColorConstants.mainTextColor
                            .withValues(alpha: 0.55)
                        : AppColorConstants.mainTextColor,
                  ),
                ),
                Icon(Icons.calendar_month_outlined,
                    color: AppColorConstants.iconColor),
              ],
            ),
          ).ripple(_selectDateOfBirth),
        ],
      ),
    );
  }

  Widget _followSuggestionsScreen() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(
            DesignConstants.horizontalPadding,
            16,
            DesignConstants.horizontalPadding,
            12,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Heading3Text("Who's on RD", weight: TextWeight.bold),
              const SizedBox(height: 8),
              BodyLargeText(
                'Follow a few accounts to shape your first feed.',
                color: AppColorConstants.mainTextColor.withValues(alpha: 0.75),
              ),
            ],
          ),
        ),
        Expanded(
          child: _suggestedUsers.isEmpty && _isLoadingSuggestions
              ? Center(
                  child: CircularProgressIndicator(
                    color: AppColorConstants.themeColor,
                  ),
                )
              : ListView.separated(
                  controller: _suggestionsScrollController,
                  padding: EdgeInsets.symmetric(
                    horizontal: DesignConstants.horizontalPadding,
                  ),
                  itemBuilder: (context, index) {
                    if (index == _suggestedUsers.length) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        child: Center(
                          child: CircularProgressIndicator(
                            color: AppColorConstants.themeColor,
                          ),
                        ),
                      );
                    }
                    return _suggestionTile(_suggestedUsers[index]);
                  },
                  separatorBuilder: (context, index) => divider(height: 1),
                  itemCount: _suggestedUsers.length +
                      (_isLoadingSuggestions && _suggestedUsers.isNotEmpty
                          ? 1
                          : 0),
                ),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(
            DesignConstants.horizontalPadding,
            8,
            DesignConstants.horizontalPadding,
            18,
          ),
          child: Column(
            children: [
              AppThemeButton(
                text: doneString.tr,
                onPress: _finishSetup,
              ),
              const SizedBox(height: 12),
              Center(
                child: BodyLargeText(
                  skipString.tr,
                  weight: TextWeight.semiBold,
                  color: AppColorConstants.mainTextColor.withValues(alpha: 0.7),
                ).ripple(_finishSetup),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _suggestionTile(UserModel user) {
    final isFollowing = user.followingStatus != FollowingStatus.notFollowing;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          UserAvatarView(
            user: user,
            size: 50,
            hideLiveIndicator: true,
            hideOnlineIndicator: true,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                BodyLargeText(
                  user.userName,
                  weight: TextWeight.semiBold,
                  maxLines: 1,
                ),
                if ((user.name ?? '').trim().isNotEmpty)
                  BodySmallText(
                    user.name!,
                    color:
                        AppColorConstants.mainTextColor.withValues(alpha: 0.62),
                    maxLines: 1,
                  ),
              ],
            ),
          ),
          SizedBox(
            width: 118,
            child: isFollowing
                ? AppThemeButton(
                    text: unFollowString.tr,
                    height: 38,
                    onPress: () => _toggleFollow(user),
                  )
                : AppThemeBorderButton(
                    text: followString.tr,
                    height: 38,
                    onPress: () => _toggleFollow(user),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _coverPicker(UserModel user) {
    final coverImage = user.coverImage;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          height: 190,
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppColorConstants.cardColor,
            borderRadius: BorderRadius.circular(12),
          ),
          clipBehavior: Clip.hardEdge,
          child: coverImage != null && coverImage.isNotEmpty
              ? CachedNetworkImage(
                  imageUrl: coverImage,
                  fit: BoxFit.cover,
                )
              : Container(
                  color: AppColorConstants.themeColor.withValues(alpha: 0.12),
                  child: Center(
                    child: BodyLargeText(chooseCoverImageString.tr),
                  ),
                ),
        ).ripple(() => _pickImage(isCoverImage: true)),
        Positioned(
          right: 12,
          bottom: 12,
          child: _smallActionButton(
            label: chooseCoverImageString.tr,
            onTap: () => _pickImage(isCoverImage: true),
          ),
        ),
        Positioned(
          left: 18,
          bottom: -42,
          child: Stack(
            children: [
              UserAvatarView(
                user: user,
                size: 92,
                hideLiveIndicator: true,
                hideOnlineIndicator: true,
              ).ripple(() => _pickImage(isCoverImage: false)),
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  height: 32,
                  width: 32,
                  decoration: BoxDecoration(
                    color: AppColorConstants.themeColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(Icons.camera_alt_outlined, size: 18),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 158, left: 122),
          child: BodyMediumText(
            editProfilePictureString.tr,
            weight: TextWeight.medium,
          ).ripple(() => _pickImage(isCoverImage: false)),
        ),
      ],
    );
  }

  Widget _smallActionButton({
    required String label,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColorConstants.backgroundColor.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(18),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: BodyMediumText(label, weight: TextWeight.medium),
    ).ripple(onTap);
  }
}
