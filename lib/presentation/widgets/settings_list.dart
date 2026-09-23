import 'package:cupertino_native_better/cupertino_native_better.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../core/platform/app_platform.dart';

/// A grouped settings section: optional header, a card of rows, optional
/// footer. Styled like iOS Settings on Apple platforms and as an
/// Expressive grouped list elsewhere.
class SettingsSection extends StatelessWidget {
  final String? header;
  final String? footer;
  final List<Widget> children;

  const SettingsSection({
    super.key,
    this.header,
    this.footer,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final apple = isApplePlatform;

    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (header != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Text(
                apple ? header!.toUpperCase() : header!,
                style: apple
                    ? TextStyle(
                        fontSize: 13,
                        letterSpacing: 0.2,
                        color: scheme.onSurfaceVariant,
                      )
                    : TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: scheme.primary,
                      ),
              ),
            ),
          Card(
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                for (var i = 0; i < children.length; i++) ...[
                  if (i > 0) Divider(height: 1, indent: apple ? 58 : 72),
                  children[i],
                ],
              ],
            ),
          ),
          if (footer != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Text(
                footer!,
                style: TextStyle(fontSize: 13, color: scheme.onSurfaceVariant),
              ),
            ),
        ],
      ),
    );
  }
}

/// One settings row: a colored icon badge, a title with optional subtitle,
/// and a trailing value, switch or chevron.
class SettingsTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String? subtitle;

  /// Shown right-aligned in a muted color (e.g. the current value).
  final String? value;
  final VoidCallback? onTap;

  /// Replaces the value/chevron, e.g. with a switch.
  final Widget? trailing;

  const SettingsTile({
    super.key,
    required this.icon,
    required this.color,
    required this.title,
    this.subtitle,
    this.value,
    this.onTap,
    this.trailing,
  });

  /// A row whose trailing control is an on/off switch (native on Apple).
  factory SettingsTile.toggle({
    Key? key,
    required IconData icon,
    required Color color,
    required String title,
    String? subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SettingsTile(
      key: key,
      icon: icon,
      color: color,
      title: title,
      subtitle: subtitle,
      trailing: isApplePlatform
          ? Padding(
              padding: const EdgeInsets.only(right: 4),
              child: CNSwitch(value: value, onChanged: onChanged, height: 31),
            )
          : Switch(value: value, onChanged: onChanged),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final apple = isApplePlatform;

    // iOS Settings: white glyph on a solid rounded square. Expressive: a
    // tonal container with the glyph in the accent color.
    final badge = Container(
      width: apple ? 30 : 40,
      height: apple ? 30 : 40,
      decoration: BoxDecoration(
        color: apple ? color : color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(apple ? 7 : 14),
      ),
      child: Icon(
        icon,
        size: apple ? 18 : 22,
        color: apple ? Colors.white : color,
      ),
    );

    return InkWell(
      onTap: onTap,
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: apple ? 48 : 64),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 14, vertical: apple ? 8 : 10),
          child: Row(
            children: [
              badge,
              SizedBox(width: apple ? 14 : 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: apple ? 16 : 16,
                        fontWeight: apple ? FontWeight.w400 : FontWeight.w600,
                      ),
                    ),
                    if (subtitle != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          subtitle!,
                          style: TextStyle(
                            fontSize: 13,
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              if (trailing != null)
                trailing!
              else ...[
                if (value != null)
                  Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: Text(
                      value!,
                      style: TextStyle(
                        fontSize: 16,
                        color: scheme.onSurfaceVariant,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ),
                if (onTap != null)
                  Padding(
                    padding: const EdgeInsets.only(left: 6),
                    child: Icon(
                      apple
                          ? CupertinoIcons.chevron_forward
                          : Icons.chevron_right_rounded,
                      size: apple ? 16 : 22,
                      color: scheme.onSurfaceVariant.withValues(
                        alpha: apple ? 0.6 : 1,
                      ),
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
