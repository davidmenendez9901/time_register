import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:time_register/l10n/app_localizations.dart';
import 'package:time_register/presentation/widgets/floating_nav_bar.dart';

/// The overflow test above is font-agnostic; this one renders with the real
/// bundled Lato so we also know the labels are not silently ellipsized on the
/// phone sizes we actually target.
void main() {
  setUpAll(() async {
    final loader = FontLoader('Lato');
    for (final name in const ['Lato-Regular.ttf', 'Lato-Bold.ttf']) {
      final bytes = await File('assets/google_fonts/$name').readAsBytes();
      loader.addFont(Future.value(bytes.buffer.asByteData()));
    }
    await loader.load();
  });

  Widget wrap(int selectedIndex, Locale locale) => MaterialApp(
    locale: locale,
    theme: ThemeData(fontFamily: 'Lato'),
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(
      body: Stack(
        children: [
          FloatingNavBar(selectedIndex: selectedIndex, onItemSelected: (_) {}),
        ],
      ),
    ),
  );

  const labels = {
    'es': ['Inicio', 'Resumen', 'Estadísticas', 'Ajustes'],
    'en': ['Home', 'Summary', 'Statistics', 'Settings'],
  };

  // iPhone SE (3rd gen) through iPhone Pro Max.
  for (final width in const <double>[375, 390, 402, 430]) {
    for (final entry in labels.entries) {
      for (var index = 0; index < 4; index++) {
        testWidgets('label fits: locale=${entry.key} width=$width tab=$index', (
          tester,
        ) async {
          tester.view.physicalSize = Size(width * 3, 874 * 3);
          tester.view.devicePixelRatio = 3.0;
          addTearDown(tester.view.reset);

          await tester.pumpWidget(wrap(index, Locale(entry.key)));
          await tester.pumpAndSettle();

          final paragraph = tester.renderObject<RenderParagraph>(
            find.text(entry.value[index]),
          );
          expect(
            paragraph.didExceedMaxLines,
            isFalse,
            reason: '"${entry.value[index]}" was ellipsized at ${width}pt',
          );
        });
      }
    }
  }
}
