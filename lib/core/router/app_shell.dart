import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/tokens.dart';
import '../../features/profile/presentation/home_screen.dart';
import '../../features/profile/presentation/journey_screen.dart';
import '../../features/profile/presentation/events_screen.dart';
import '../../features/profile/presentation/leaderboard_screen.dart';
import '../../features/profile/presentation/rewards_screen.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _selectedIndex = 0;

  static const _screens = [
    HomeScreen(),
    JourneyScreen(),
    EventsScreen(),
    LeaderboardScreen(),
    RewardsScreen(),
  ];

  static const _tabs = [
    _TabItem(icon: '🏠', label: 'Home'),
    _TabItem(icon: '🗺️', label: 'Journey'),
    _TabItem(icon: '⚡', label: 'Events'),
    _TabItem(icon: '🏆', label: 'Rank'),
    _TabItem(icon: '🎁', label: 'Rewards'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgDeep,
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: _BottomBar(
        selectedIndex: _selectedIndex,
        tabs: _tabs,
        onTap: (i) => setState(() => _selectedIndex = i),
      ),
    );
  }
}

class _TabItem {
  final String icon;
  final String label;

  const _TabItem({required this.icon, required this.label});
}

class _BottomBar extends StatelessWidget {
  final int selectedIndex;
  final List<_TabItem> tabs;
  final ValueChanged<int> onTap;

  const _BottomBar({
    required this.selectedIndex,
    required this.tabs,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: bgDeep,
      padding: const EdgeInsets.only(top: 4, bottom: 8),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            for (int i = 0; i < tabs.length; i++)
              _TabButton(
                item: tabs[i],
                active: selectedIndex == i,
                onTap: () => onTap(i),
              ),
          ],
        ),
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  final _TabItem item;
  final bool active;
  final VoidCallback onTap;

  const _TabButton({
    required this.item,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          gradient: active ? pinkFull : null,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedSlide(
              offset: active ? const Offset(0, -0.15) : Offset.zero,
              duration: const Duration(milliseconds: 200),
              child: Text(item.icon, style: const TextStyle(fontSize: 18)),
            ),
            Text(
              item.label,
              style: GoogleFonts.nunito(
                color: active ? textCol : textDim,
                fontWeight: FontWeight.w700,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
