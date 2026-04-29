# RB Project Setup Checklist (Firebase + Google Login + Agora)

Use this checklist for Firebase project `rdsocial-a01d2` and validate end-to-end auth/live flows.

## 1) Firebase CLI + FlutterFire CLI

```bash
npm install -g firebase-tools
firebase login

dart pub global activate flutterfire_cli
```

## 2) Generate Firebase config for RB

Run from project root:

```bash
flutterfire configure \
  --project=rdsocial-a01d2 \
  --platforms=android,ios \
  --android-package-name=com.rbsocial \
  --ios-bundle-id=com.rb.apptesting \
  --out=lib/firebase_options.dart
```

This updates `lib/firebase_options.dart` and syncs Firebase app IDs.

## 3) Replace platform Firebase files

Download from Firebase Console for project `rdsocial-a01d2` and replace:

- `android/app/google-services.json`
- `ios/Runner/GoogleService-Info.plist`

## 4) Enable Google Sign-In in Firebase

In Firebase Console (`rdsocial-a01d2`):

1. Authentication -> Sign-in method -> enable `Google`.
2. Add support email.
3. Confirm Android package name is `com.rbsocial`.
4. Confirm iOS bundle ID is `com.rb.apptesting`.

## 5) Add SHA fingerprints (required for Android Google login)

Add both debug and release SHA-1/SHA-256 to the Android app in Firebase:

```bash
# Debug keystore
keytool -list -v -alias androiddebugkey -keystore ~/.android/debug.keystore -storepass android -keypass android

# Release/upload keystore (replace path + alias)
keytool -list -v -alias <alias> -keystore <path-to-keystore>

# Verify certificate used by generated APK (recommended)
keytool -printcert -jarfile build/app/outputs/flutter-apk/app-arm64-v8a-release.apk
```

After adding SHA keys in Firebase, download a fresh `google-services.json` again.

Current local build certificate (from `app-arm64-v8a-release.apk`):

- SHA1: `15:53:15:9F:48:01:FB:B1:C8:1B:5B:91:03:01:16:51:12:14:61:20`
- SHA256: `8A:DB:21:16:B1:57:59:52:A6:52:DB:07:EE:C0:24:13:34:F4:E7:A8:C5:2F:3C:F6:4F:3C:92:D8:60:C6:94:AA`

## 6) Agora

Agora App ID is already wired as fallback in code:

- `lib/util/app_config_constants.dart` -> `fallbackAgoraAppId`

Current value:

- `510ff736f6b74b0a8efeb9ac38372932`

If backend settings API later returns Agora key, it will override fallback automatically.

## 7) Build verification

```bash
flutter clean
flutter pub get
flutter build apk --release --split-per-abi
```

(Optional universal APK for easy manual QA)

```bash
flutter build apk --release
```

## 8) Functional smoke test

1. Install APK, open app.
2. Tap `Skip` on follow screen -> app should continue past splash.
3. Land on tutorial/auth screen (no blank hang).
4. Test Google login.
5. Confirm dashboard opens after login.
6. Test live/call entry path (Agora join/create).

## 9) Backend session bridge (required for full app)

This app's feeds, chat, profile, uploads, and live modules still read/write via
`https://api.rdsocialapp.co.ke/app/api/web/v1/` and require backend `auth_key`.

Firebase authentication alone is not enough for full functionality.

After Firebase login/signup, app now calls backend `users/login-social` using:

- `social_type`: `firebase` (configurable in `AppConfigConstants.firebaseBackendSocialType`)
- `social_id`: Firebase UID
- `email` + `name`: from Firebase user

Expected backend behavior:

1. Create/find user by (`social_type`, `social_id`) or verified email.
2. Return backend `auth_key` (same as legacy social login).
3. `/users/profile` should return a complete profile payload for the app.

If backend does not accept `social_type=firebase`, either:

1. Add `firebase` as an allowed social provider in backend, or
2. Change app config `firebaseBackendSocialType` to a provider value the backend accepts.
