import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// iOS, iPadOS and macOS get native Liquid Glass chrome; every other platform
/// gets Material 3 Expressive.
bool get isApplePlatform =>
    !kIsWeb &&
    (defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS);

bool _iosAppOnMac = false;

/// True on macOS, and for the iPad app running on a Mac ("Designed for
/// iPad"), where Flutter reports iOS but native controls behave like macOS.
bool get runsOnMac =>
    !kIsWeb && (defaultTargetPlatform == TargetPlatform.macOS || _iosAppOnMac);

/// Call once before `runApp` so [runsOnMac] is accurate.
Future<void> initAppPlatform() async {
  if (kIsWeb || defaultTargetPlatform != TargetPlatform.iOS) return;
  try {
    _iosAppOnMac =
        await const MethodChannel(
          'time_register/platform',
        ).invokeMethod<bool>('isiOSAppOnMac') ??
        false;
  } on PlatformException {
    _iosAppOnMac = false;
  } on MissingPluginException {
    _iosAppOnMac = false;
  }
}
