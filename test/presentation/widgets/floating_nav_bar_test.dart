import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:time_register/l10n/app_localizations.dart';
import 'package:time_register/presentation/widgets/floating_nav_bar.dart';

void main() {
  Widget wrap(int selectedIndex, Locale locale) => MaterialApp(
    locale: locale,
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

  // Narrowest iPhone Flutter still supports (iPhone SE, 320pt) up to a
  // regular-width iPhone. Every tab must fit in every locale.
  const widths = <double>[320, 375, 402, 430];

  for (final locale in const [Locale('es'), Locale('en')]) {
    for (final width in widths) {
      for (var index = 0; index < 4; index++) {
        testWidgets(
          'no overflow: locale=${locale.languageCode} width=$width tab=$index',
          (tester) async {
            tester.view.physicalSize = Size(width * 3, 874 * 3);
            tester.view.devicePixelRatio = 3.0;
            addTearDown(tester.view.reset);

            await tester.pumpWidget(wrap(index, locale));
            await tester.pumpAndSettle();

            expect(tester.takeException(), isNull);
          },
        );
      }
    }
  }
}
