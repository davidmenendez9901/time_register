import 'package:flutter/material.dart';
import 'package:time_register/l10n/app_localizations.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class FloatingNavBar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemSelected;
  final bool isVisible;

  const FloatingNavBar({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
    required this.isVisible,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return AnimatedPositioned(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      bottom: isVisible ? 32 : -100,
      left: 32,
      right: 32,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
          border: isDark
              ? Border.all(color: Colors.white.withValues(alpha: 0.1))
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildNavItem(
              context,
              icon: FontAwesomeIcons.house,
              index: 0,
              label: AppLocalizations.of(context)!.homeTab,
              isSelected: selectedIndex == 0,
            ),
            _buildNavItem(
              context,
              icon: FontAwesomeIcons.chartSimple,
              index: 1,
              label: AppLocalizations.of(context)!.summaryTab,
              isSelected: selectedIndex == 1,
            ),
            _buildNavItem(
              context,
              icon: FontAwesomeIcons.gear,
              index: 2,
              label: AppLocalizations.of(context)!.settingsTab,
              isSelected: selectedIndex == 2,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context, {
    required IconData icon,
    required int index,
    required String label,
    required bool isSelected,
  }) {
    final theme = Theme.of(context);

    // Explicitly define colors for better contrast in dark mode
    final selectedColor = theme.colorScheme.primary;
    final unselectedColor = theme.colorScheme.onSurface.withValues(alpha: 0.5);

    // Background bubble color
    final bubbleColor = selectedColor.withValues(alpha: 0.15);

    return InkWell(
      onTap: () => onItemSelected(index),
      borderRadius: BorderRadius.circular(24),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? bubbleColor : Colors.transparent,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            FaIcon(
              icon,
              color: isSelected ? selectedColor : unselectedColor,
              size: 20,
            ),
            if (isSelected) ...[
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: selectedColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
