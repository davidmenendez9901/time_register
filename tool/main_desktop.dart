// Dev-only entrypoint to run the app on Linux/macOS/Windows desktop.
//
// `sqflite` has no desktop implementation, so the FFI factory is installed
// before delegating to the real entrypoint in lib/main.dart. Nothing under
// lib/ is touched, and `sqflite_common_ffi` stays a dev dependency, so the
// shipped Android/iOS builds are unaffected.
//
// Usage: flutter run -d linux -t tool/main_desktop.dart
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:time_register/main.dart' as app;

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;
  app.main();
}
