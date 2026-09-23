import 'package:cupertino_native_better/cupertino_native_better.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:time_register/l10n/app_localizations.dart';

import '../../core/platform/app_platform.dart';
import 'work_entry_form_page.dart';
import 'home_content.dart';
import 'weekly_summary_page.dart';
import 'stats_page.dart';
import 'settings_page.dart';

/// Root shell. Apple platforms get native Liquid Glass chrome (a tab bar on
/// iPhone, a glass sidebar on iPad and Mac); everything else gets Material 3
/// Expressive (a navigation bar on phones, a rail on tablets).
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  /// Below this width Apple platforms use a tab bar, above it a sidebar.
  static const double _appleSidebarBreakpoint = 700;

  /// Material window-size class boundary between compact and medium.
  static const double _materialRailBreakpoint = 600;

  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _addEntry() {
    Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (context) => const WorkEntryFormPage(),
      ),
    );
  }

  List<_Destination> _destinations(AppLocalizations l10n) => [
    _Destination(
      label: l10n.homeTab,
      symbol: 'house',
      cupertinoIcon: CupertinoIcons.house_fill,
      icon: Icons.home_outlined,
      selectedIcon: Icons.home_rounded,
    ),
    _Destination(
      label: l10n.summaryTab,
      symbol: 'chart.bar',
      cupertinoIcon: CupertinoIcons.chart_bar_fill,
      icon: Icons.bar_chart_outlined,
      selectedIcon: Icons.bar_chart_rounded,
    ),
    _Destination(
      label: l10n.statsTab,
      symbol: 'chart.pie',
      cupertinoIcon: CupertinoIcons.chart_pie_fill,
      icon: Icons.pie_chart_outline_rounded,
      selectedIcon: Icons.pie_chart_rounded,
    ),
    _Destination(
      label: l10n.settingsTab,
      symbol: 'gearshape',
      cupertinoIcon: CupertinoIcons.gear_solid,
      icon: Icons.settings_outlined,
      selectedIcon: Icons.settings_rounded,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final destinations = _destinations(AppLocalizations.of(context)!);
    final pages = IndexedStack(
      index: _selectedIndex,
      children: const [
        HomeContent(),
        WeeklySummaryPage(),
        StatsPage(),
        SettingsPage(),
      ],
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        if (isApplePlatform) {
          return width >= _appleSidebarBreakpoint
              ? _buildAppleSidebar(context, destinations, pages)
              : _buildAppleTabBar(context, destinations, pages);
        }
        return width >= _materialRailBreakpoint
            ? _buildMaterialRail(context, destinations, pages)
            : _buildMaterialNavigationBar(context, destinations, pages);
      },
    );
  }

  // ---------------------------------------------------------------- Apple

  Widget _buildAppleTabBar(
    BuildContext context,
    List<_Destination> destinations,
    Widget pages,
  ) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    return Scaffold(
      body: Stack(
        children: [
          pages,
          // Keys keep the tab bar's element (and its native view) stable
          // when the add button enters or leaves the Stack; otherwise the
          // bar is recreated and replays its selection animation.
          if (_selectedIndex == 0)
            Positioned(
              key: const ValueKey('addButton'),
              right: 20,
              // Clear the floating native tab bar (~62pt plus its own
              // margin above the home indicator) with a small gap.
              bottom: bottomInset + 96,
              child: _GlassAddButton(onPressed: _addEntry),
            ),
          Positioned(
            key: const ValueKey('tabBar'),
            left: 0,
            right: 0,
            bottom: 0,
            child: SafeArea(
              top: false,
              child: CNTabBar(
                items: [
                  for (final d in destinations)
                    CNTabBarItem(
                      label: d.label,
                      icon: CNSymbol(d.symbol),
                      activeIcon: CNSymbol('${d.symbol}.fill'),
                    ),
                ],
                currentIndex: _selectedIndex,
                onTap: _onItemTapped,
                tint: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppleSidebar(
    BuildContext context,
    List<_Destination> destinations,
    Widget pages,
  ) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    final sidebar = SafeArea(
      right: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 16, 12, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 8, 20),
              child: Text(
                l10n.appTitle,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            for (var i = 0; i < destinations.length; i++)
              _SidebarItem(
                destination: destinations[i],
                selected: i == _selectedIndex,
                onTap: () => _onItemTapped(i),
              ),
            const Spacer(),
            // The native glass button drops its label on macOS, so the Mac
            // sidebar uses a plain capsule button instead.
            if (defaultTargetPlatform == TargetPlatform.macOS)
              FilledButton.icon(
                onPressed: _addEntry,
                icon: const Icon(CupertinoIcons.add, size: 18),
                label: Text(l10n.addWorkEntry),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(44),
                ),
              )
            else
              CNButton(
                label: l10n.addWorkEntry,
                icon: const CNSymbol('plus', size: 16),
                tint: theme.colorScheme.primary,
                config: const CNButtonConfig(
                  style: CNButtonStyle.prominentGlass,
                  minHeight: 44,
                ),
                onPressed: _addEntry,
              ),
          ],
        ),
      ),
    );

    return Scaffold(
      body: Row(
        children: [
          Padding(
            padding: const EdgeInsets.all(10),
            child: SizedBox(
              width: 260,
              child: PlatformVersion.shouldUseNativeGlass
                  ? LiquidGlassContainer(
                      config: const LiquidGlassConfig(
                        shape: CNGlassEffectShape.rect,
                        cornerRadius: 26,
                      ),
                      child: sidebar,
                    )
                  : DecoratedBox(
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(26),
                      ),
                      child: sidebar,
                    ),
            ),
          ),
          Expanded(child: pages),
        ],
      ),
    );
  }

  // ------------------------------------------------------------- Material

  Widget _buildMaterialNavigationBar(
    BuildContext context,
    List<_Destination> destinations,
    Widget pages,
  ) {
    return Scaffold(
      body: pages,
      floatingActionButton: _selectedIndex == 0
          ? FloatingActionButton.large(
              onPressed: _addEntry,
              tooltip: AppLocalizations.of(context)!.addWorkEntry,
              child: const Icon(Icons.add_rounded, size: 36),
            )
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _onItemTapped,
        destinations: [
          for (final d in destinations)
            NavigationDestination(
              icon: Icon(d.icon),
              selectedIcon: Icon(d.selectedIcon),
              label: d.label,
            ),
        ],
      ),
    );
  }

  Widget _buildMaterialRail(
    BuildContext context,
    List<_Destination> destinations,
    Widget pages,
  ) {
    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: _selectedIndex,
            onDestinationSelected: _onItemTapped,
            groupAlignment: -0.6,
            leading: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: FloatingActionButton(
                onPressed: _addEntry,
                elevation: 0,
                tooltip: AppLocalizations.of(context)!.addWorkEntry,
                child: const Icon(Icons.add_rounded, size: 28),
              ),
            ),
            destinations: [
              for (final d in destinations)
                NavigationRailDestination(
                  icon: Icon(d.icon),
                  selectedIcon: Icon(d.selectedIcon),
                  label: Text(d.label),
                ),
            ],
          ),
          Expanded(child: pages),
        ],
      ),
    );
  }
}

class _Destination {
  final String label;

  /// SF Symbol name; the native tab bar appends `.fill` when selected.
  final String symbol;
  final IconData cupertinoIcon;
  final IconData icon;
  final IconData selectedIcon;

  const _Destination({
    required this.label,
    required this.symbol,
    required this.cupertinoIcon,
    required this.icon,
    required this.selectedIcon,
  });
}

class _GlassAddButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _GlassAddButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: AppLocalizations.of(context)!.addWorkEntry,
      child: CNButton.icon(
        icon: const CNSymbol('plus', size: 24),
        tint: Theme.of(context).colorScheme.primary,
        config: const CNButtonConfig(
          style: CNButtonStyle.prominentGlass,
          width: 58,
          minHeight: 58,
        ),
        onPressed: onPressed,
      ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  final _Destination destination;
  final bool selected;
  final VoidCallback onTap;

  const _SidebarItem({
    required this.destination,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final foreground = selected ? Colors.white : scheme.onSurface;

    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Semantics(
        button: true,
        selected: selected,
        child: GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: selected ? scheme.primary : Colors.transparent,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Icon(
                  destination.cupertinoIcon,
                  size: 20,
                  color: selected ? foreground : scheme.primary,
                ),
                const SizedBox(width: 12),
                Text(
                  destination.label,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                    color: foreground,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
