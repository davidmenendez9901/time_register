import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// sqflite's native plugin covers Android, iOS and macOS.
/// Linux and Windows need the FFI factory; web is not supported.
void initDesktopSqliteIfNeeded() {
  if (kIsWeb) return;
  if (Platform.isLinux || Platform.isWindows) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }
}
