import 'dart:io';

import 'package:image/image.dart' as img;

void main() async {
  final sourceBytes = await File('assets/rd_logo_v2.jpeg').readAsBytes();
  final source = img.decodeImage(sourceBytes);
  if (source == null) {
    throw StateError('Unable to decode assets/rd_logo_v2.jpeg');
  }

  final androidIcons = <String, int>{
    'android/app/src/main/res/mipmap-mdpi/ic_launcher.png': 48,
    'android/app/src/main/res/mipmap-hdpi/ic_launcher.png': 72,
    'android/app/src/main/res/mipmap-xhdpi/ic_launcher.png': 96,
    'android/app/src/main/res/mipmap-xxhdpi/ic_launcher.png': 144,
    'android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png': 192,
    'android/app/src/main/res/mipmap-mdpi/ic_launcher_round.png': 48,
    'android/app/src/main/res/mipmap-hdpi/ic_launcher_round.png': 72,
    'android/app/src/main/res/mipmap-xhdpi/ic_launcher_round.png': 96,
    'android/app/src/main/res/mipmap-xxhdpi/ic_launcher_round.png': 144,
    'android/app/src/main/res/mipmap-xxxhdpi/ic_launcher_round.png': 192,
    'android/app/src/main/res/mipmap-mdpi/ic_launcher_foreground.png': 108,
    'android/app/src/main/res/mipmap-hdpi/ic_launcher_foreground.png': 162,
    'android/app/src/main/res/mipmap-xhdpi/ic_launcher_foreground.png': 216,
    'android/app/src/main/res/mipmap-xxhdpi/ic_launcher_foreground.png': 324,
    'android/app/src/main/res/mipmap-xxxhdpi/ic_launcher_foreground.png': 432,
    'android/app/src/main/res/drawable/ic_launcher.png': 48,
  };

  final iosIcons = <String, int>{
    'ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-20x20@1x.png': 20,
    'ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-20x20@2x.png': 40,
    'ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-20x20@3x.png': 60,
    'ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-29x29@1x.png': 29,
    'ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-29x29@2x.png': 58,
    'ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-29x29@3x.png': 87,
    'ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-40x40@1x.png': 40,
    'ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-40x40@2x.png': 80,
    'ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-40x40@3x.png': 120,
    'ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-60x60@2x.png': 120,
    'ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-60x60@3x.png': 180,
    'ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-76x76@1x.png': 76,
    'ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-76x76@2x.png': 152,
    'ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-83.5x83.5@2x.png':
        167,
    'ios/Runner/Assets.xcassets/AppIcon.appiconset/ItunesArtwork@2x.png': 1024,
  };

  for (final entry in {...androidIcons, ...iosIcons}.entries) {
    _writePng(source, entry.key, entry.value);
  }
}

void _writePng(img.Image source, String path, int size) {
  final resized = img.copyResize(
    source,
    width: size,
    height: size,
    interpolation: img.Interpolation.cubic,
  );
  File(path).writeAsBytesSync(img.encodePng(resized));
}
