import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:swift_chat/pages/auth/login_page.dart';
import 'package:swift_chat/pages/desktop_home_page.dart';
import 'package:swift_chat/providers/user_provider.dart';
import 'package:swift_chat/pages/screns/home_page.dart';
import 'package:swift_chat/pages/screns/discover_page.dart';
import 'package:swift_chat/pages/screns/notifications_page.dart';
import 'package:swift_chat/pages/screns/menu_page.dart';

final _selectedIndexProvider = StateProvider<int>((ref) => 0);

class App extends ConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userProvider);
    final selectedIndex = ref.watch(_selectedIndexProvider);

    if (user == null) return const LoginPage();
    final pages = [
      const HomePage(),
      const DiscoverPage(),
      const NotificationsPage(),
      const MenuPage(),
    ];

    final navIconList = [
      _NavIcon(
        icon: Icons.home_rounded,
        index: 0,
        selectedIndex: selectedIndex,
        onTap: () => ref.read(_selectedIndexProvider.notifier).state = 0,
      ),
      _NavIcon(
        icon: Icons.explore_rounded,
        index: 1,
        selectedIndex: selectedIndex,
        onTap: () => ref.read(_selectedIndexProvider.notifier).state = 1,
      ),
      _NavIcon(
        icon: Icons.notifications_rounded,
        index: 2,
        selectedIndex: selectedIndex,
        onTap: () => ref.read(_selectedIndexProvider.notifier).state = 2,
      ),
      _NavIcon(
        icon: Icons.menu_rounded,
        index: 3,
        selectedIndex: selectedIndex,
        onTap: () => ref.read(_selectedIndexProvider.notifier).state = 3,
      ),
    ];

    final size = MediaQuery.of(context).size;

    if (size.width > size.height) {
      return DesktopHomePage(
        iconList: navIconList,
        selectedPage: selectedIndex,
      );
    }

    return Scaffold(
      extendBody: true, // important for floating bar
      body: Stack(
        children: [
          // The active page with animation
          AnimatedSwitcher(
            duration: 250.ms,
            transitionBuilder: (child, animation) {
              return FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0.05, 0),
                    end: Offset.zero,
                  ).animate(animation),
                  child: child,
                ),
              );
            },
            child: KeyedSubtree(
              key: ValueKey(selectedIndex),
              child: pages[selectedIndex],
            ),
          ),

          // Floating dock-style nav bar
          Positioned(
            left: 20,
            right: 20,
            bottom: 25,
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.inversePrimary.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 20,
                    offset: const Offset(3, 2),
                  ),
                ],
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: navIconList,
              ),
            ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.2, end: 0),
          ),
        ],
      ),
    );
  }
}

class _NavIcon extends StatelessWidget {
  final IconData icon;
  final int index;
  final int selectedIndex;
  final VoidCallback onTap;

  const _NavIcon({
    required this.icon,
    required this.index,
    required this.selectedIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = selectedIndex == index;
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: 200.ms,
        curve: Curves.easeOut,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color:
              isSelected
                  ? colorScheme.brightness == Brightness.dark
                      ? colorScheme.inverseSurface.withValues(alpha: 0.3)
                      : colorScheme.primary.withValues(alpha: 0.15)
                  : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Icon(
          icon,
          size: isSelected ? 28 : 26,
          color:
              isSelected
                  ? colorScheme.brightness == Brightness.dark
                      ? colorScheme.inverseSurface
                      : colorScheme.primary
                  : colorScheme.onSurface.withValues(alpha: 0.6),
        ),
      ),
    );
  }
}
