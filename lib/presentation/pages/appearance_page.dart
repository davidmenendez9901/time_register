import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:time_register/l10n/app_localizations.dart';

import '../../core/entities/settings.dart' as app_settings;
import '../../core/platform/app_platform.dart';
import '../../core/theme/app_palette.dart';
import '../blocs/settings/settings_bloc.dart';
import '../blocs/settings/settings_event.dart';
import '../blocs/settings/settings_state.dart';
import '../widgets/settings_list.dart';

/// Localized name of a color palette.
String paletteLabel(AppLocalizations l10n, AppPalette palette) {
  switch (palette) {
    case AppPalette.blue:
      return l10n.paletteBlue;
    case AppPalette.purple:
      return l10n.palettePurple;
    case AppPalette.green:
      return l10n.paletteGreen;
    case AppPalette.orange:
      return l10n.paletteOrange;
  }
}

/// Theme mode and accent palette, as checkmark lists (iOS Settings style).
class AppearancePage extends StatelessWidget {
  const AppearancePage({super.key});

  /// Wide layouts (iPad, Mac, tablets) center the list at this width.
  static const double _maxContentWidth = 700;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final apple = isApplePlatform;

    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final gutter = constraints.maxWidth > _maxContentWidth + 32
              ? (constraints.maxWidth - _maxContentWidth) / 2
              : 16.0;
          return BlocBuilder<SettingsBloc, SettingsState>(
            builder: (context, state) {
              final settings = state is SettingsLoaded ? state.settings : null;
              return CustomScrollView(
                slivers: [
                  SliverAppBar.large(title: Text(l10n.appearance)),
                  if (settings != null)
                    SliverPadding(
                      padding: EdgeInsets.fromLTRB(gutter, 8, gutter, 32),
                      sliver: SliverList.list(
                        children: [
                          SettingsSection(
                            header: l10n.mode,
                            children: [
                              for (final (mode, label, icon, color) in [
                                (
                                  app_settings.ThemeMode.system,
                                  l10n.system,
                                  apple
                                      ? CupertinoIcons.circle_lefthalf_fill
                                      : Icons.brightness_auto_rounded,
                                  const Color(0xFF8E8E93),
                                ),
                                (
                                  app_settings.ThemeMode.light,
                                  l10n.light,
                                  apple
                                      ? CupertinoIcons.sun_max_fill
                                      : Icons.light_mode_rounded,
                                  const Color(0xFFFF9500),
                                ),
                                (
                                  app_settings.ThemeMode.dark,
                                  l10n.dark,
                                  apple
                                      ? CupertinoIcons.moon_fill
                                      : Icons.dark_mode_rounded,
                                  const Color(0xFF5856D6),
                                ),
                              ])
                                SettingsTile(
                                  icon: icon,
                                  color: color,
                                  title: label,
                                  trailing: _Check(
                                    selected: settings.themeMode == mode,
                                  ),
                                  onTap: () => context.read<SettingsBloc>().add(
                                    UpdateThemeMode(mode),
                                  ),
                                ),
                            ],
                          ),
                          SettingsSection(
                            header: l10n.colors,
                            footer: l10n.appearanceSubtitle,
                            children: [
                              for (final palette in AppPalette.values)
                                SettingsTile(
                                  icon: apple
                                      ? CupertinoIcons.paintbrush_fill
                                      : Icons.palette_rounded,
                                  color: palette.primary,
                                  title: paletteLabel(l10n, palette),
                                  trailing: _Check(
                                    selected: settings.palette == palette,
                                  ),
                                  onTap: () => context.read<SettingsBloc>().add(
                                    UpdateAppPalette(palette),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

class _Check extends StatelessWidget {
  final bool selected;

  const _Check({required this.selected});

  @override
  Widget build(BuildContext context) {
    // Keep the slot sized when unselected so titles don't shift.
    return SizedBox(
      width: 28,
      child: selected
          ? Icon(
              isApplePlatform
                  ? CupertinoIcons.checkmark_alt
                  : Icons.check_circle_rounded,
              size: isApplePlatform ? 20 : 24,
              color: Theme.of(context).colorScheme.primary,
            )
          : null,
    );
  }
}
