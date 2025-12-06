import 'package:flutter/material.dart';

enum AppPalette { blue, purple, green, orange }

extension AppPaletteExtension on AppPalette {
  String get name {
    switch (this) {
      case AppPalette.blue:
        return 'Blue';
      case AppPalette.purple:
        return 'Purple';
      case AppPalette.green:
        return 'Green';
      case AppPalette.orange:
        return 'Orange';
    }
  }

  Color get primary {
    switch (this) {
      case AppPalette.blue:
        return const Color(0xFF2563EB);
      case AppPalette.purple:
        return const Color(0xFF7C3AED);
      case AppPalette.green:
        return const Color(0xFF059669);
      case AppPalette.orange:
        return const Color(0xFFEA580C);
    }
  }

  Color get secondary {
    switch (this) {
      case AppPalette.blue:
        return const Color(0xFF10B981);
      case AppPalette.purple:
        return const Color(0xFFDB2777);
      case AppPalette.green:
        return const Color(0xFF3B82F6);
      case AppPalette.orange:
        return const Color(0xFFFACC15);
    }
  }
}
