import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:animations/animations.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../blocs/time_tracking/time_tracking_bloc.dart';
import '../blocs/time_tracking/time_tracking_event.dart';
import '../widgets/floating_nav_bar.dart';
import 'work_entry_form_page.dart';
import 'home_content.dart';
import 'weekly_summary_page.dart';
import 'stats_page.dart';
import 'settings_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: Stack(
        children: [
          IndexedStack(
            index: _selectedIndex,
            children: const [
              HomeContent(),
              WeeklySummaryPage(),
              StatsPage(),
              SettingsPage(),
            ],
          ),
          // Fade the content out as it scrolls behind the floating nav bar
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: 150,
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Theme.of(
                        context,
                      ).scaffoldBackgroundColor.withValues(alpha: 0),
                      Theme.of(
                        context,
                      ).scaffoldBackgroundColor.withValues(alpha: 0.9),
                      Theme.of(context).scaffoldBackgroundColor,
                    ],
                    stops: const [0.0, 0.55, 1.0],
                  ),
                ),
              ),
            ),
          ),
          FloatingNavBar(
            selectedIndex: _selectedIndex,
            onItemSelected: _onItemTapped,
          ),
        ],
      ),
      floatingActionButton: _selectedIndex == 0
          ? Padding(
              padding: const EdgeInsets.only(bottom: 80),
              child: OpenContainer(
                transitionDuration: const Duration(milliseconds: 500),
                openBuilder: (context, _) => const WorkEntryFormPage(),
                onClosed: (_) {
                  if (context.mounted) {
                    context.read<TimeTrackingBloc>().add(LoadWorkEntries());
                  }
                },
                tappable: false,
                closedShape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(16)),
                ),
                closedColor: Theme.of(context).colorScheme.primary,
                closedElevation: 6,
                closedBuilder: (context, openContainer) {
                  return FloatingActionButton(
                    onPressed: openContainer,
                    elevation: 0,
                    child: const FaIcon(FontAwesomeIcons.plus),
                  );
                },
              ),
            )
          : null,
    );
  }
}
