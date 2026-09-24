# Store screenshots (goldie)

Framed App Store / Google Play screenshots and preview videos, made with
[goldie](https://skills.sh/kacperkapusciak/goldie). Copy, theme and scene order
live in `shared.ts`; `goldie.config.ts` is the iPhone (App Store) config and
`android/goldie.config.ts` the Google Play one.

## Demo builds

Screenshots use builds that seed six months of sample data
(`DEMO_DATA`) and, on Android, force Spanish (`DEMO_LOCALE`, since the
emulator's system language cannot be changed). Store builds never set these.

```bash
flutter build ios --simulator --debug --dart-define=DEMO_DATA=true
rm -rf goldie/builds/Runner.app && cp -R build/ios/iphonesimulator/Runner.app goldie/builds/

flutter build apk --release --dart-define=DEMO_DATA=true --dart-define=DEMO_LOCALE=es
cp build/app/outputs/flutter-apk/app-release.apk goldie/builds/time_register-demo.apk
```

## Render

```bash
# App Store (iPhone 6.9"): output in goldie/out/
GOLDIE_CONFIG=$PWD/goldie/goldie.config.ts npx -y goldie@0 all

# Google Play (Pixel 10 Pro AVD, adb on PATH): output in goldie/android/out/
PATH=$HOME/Library/Android/sdk/platform-tools:$PATH \
  GOLDIE_CONFIG=$PWD/goldie/android/goldie.config.ts npx -y goldie@0 all
```

## Flows

`.argent/flows/android/` selects everything by visible text. The iOS flows in
`.argent/flows/ios/` cannot: argent's iOS runner reads the UIKit hierarchy,
which has no Flutter widgets, so they tap Flutter widgets by coordinates
(each with an `echo:` saying what it hits) and wait with fixed pauses. Native
views (tab bar, glass add button, segmented control) are still tapped by text.
Coordinates are for the iPhone 17 Pro Max simulator goldie uses.

## iPad

goldie has no iPad device, so the iPad 13" screenshots (2064×2752) in
`goldie/out/screenshots/ipad-13/` are plain simulator captures of the same demo
build on the iPad Pro 13-inch simulator, light mode, status bar at 9:41, with
the alpha channel removed.
