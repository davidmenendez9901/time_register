import 'package:flutter/foundation.dart';

/// iOS, iPadOS and macOS get native Liquid Glass chrome; every other platform
/// gets Material 3 Expressive.
bool get isApplePlatform =>
    !kIsWeb &&
    (defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS);
