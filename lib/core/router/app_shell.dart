import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/tokens.dart';
import '../../features/profile/application/profile_provider.dart';
import '../../features/profile/presentation/home_screen.dart';
import '../../features/profile/presentation/rewards_screen.dart';
import '../../features/discover/presentation/discover_screen.dart';
import '../../features/mylist/presentation/my_list_screen.dart';
import '../../features/meta/presentation/meta_world_screen.dart';
import '../../features/shop/application/starter_pack_provider.dart';
import '../../shared/widgets/starter_pack_sheet.dart';

class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  int _selectedIndex = 0;
  bool _starterPackOffered = false;

  static const _screens = [
    HomeScreen(),
    DiscoverScreen(),
    MyListScreen(),
    RewardsScreen(),
    MetaWorldScreen(),
  ];

  static const _tabs = [
    _TabItem(icon: '🏠', label: 'Home'),
    _TabItem(icon: '🔍', label: 'Discover'),
    _TabItem(icon: '📋', label: 'My List'),
    _TabItem(icon: '🎁', label: 'Rewards'),
    _TabItem(icon: '🌟', label: 'Meta'),
  ];

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(profileProvider).valueOrNull;

    if (profile != null && !_starterPackOffered) {
      _starterPackOffered = true;
      if (profile.starterPackPurchasedAt == null) {
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          final service = ref.read(starterPackServiceProvider);
          if (!await service.isDismissed() && mounted) {
            await StarterPackSheet.show(context, ref);
          }
        });
      }
    }

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
