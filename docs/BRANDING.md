# Rider logo and launcher icons

The active Flutter logo and Android/web icons use the user-supplied
`GooRiders.jpg` artwork. The selected square master is
[gooriders-icon.png](../assets/branding/gooriders-icon.png).

The built-in imagegen tool prepared the supplied artwork for an icon. Prompt:
extract the existing red rounded-square tile, remove the dark outer margins,
make the outside transparent, and preserve the white rider, scooter, smiling
bag, speed lines, red color and exact `GooRiders` lettering. The source download
was left untouched. This is a supplied-brand asset, not a replacement brand design.

Flutter login/registration and workspace headers use the same master. The
application name and backend account identity remain BagooPH Rider.

`flutter_launcher_icons` 0.14.4 is a development-only generator under the
[MIT license](https://pub.dev/packages/flutter_launcher_icons/license). Its
[maintainer documentation](https://pub.dev/packages/flutter_launcher_icons)
supports legacy/adaptive Android icons and web favicon/PWA icons.
The current Dart SDK resolved its dependencies successfully.

Regenerate the checked-in launcher resources after changing the master:

```sh
flutter pub get
dart run flutter_launcher_icons
```

[flutter_launcher_icons.yaml](../flutter_launcher_icons.yaml) supplies the
master path, Android density/adaptive settings and web colors. Icon generation
does not enable new app permissions or native backend capabilities. No iOS
runner is included in this repository.

Recorded October 8: icon generation, Android debug build and static analysis
passed, along with 26 relevant UI checks. The preview APK was installed by USB
on an authorized Android phone and the new Flutter logo was visually confirmed.
The device denied ADB tap injection, and later screen-control commands timed out;
automated navigation/keyboard and a launcher-screen visual check are not claimed.
The installed package includes the generated legacy/adaptive launcher resources.
Current phone checks use the ordinary Azure build and **Profile → Settings**;
the earlier sample-only app entry has been retired.
