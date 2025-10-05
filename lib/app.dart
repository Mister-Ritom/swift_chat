import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:swift_chat/pages/auth/login_page.dart';
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

    // Pages for bottom navigation
    final pages = [
      const HomePage(),
      const DiscoverPage(),
      const NotificationsPage(),
      const MenuPage(),
    ];

    return Scaffold(
      body: AnimatedSwitcher(
        duration: 200.ms,
        transitionBuilder: (child, animation) {
          // fade + slight slide animation
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.05, 0), // slight slide from right
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
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: selectedIndex,
        onTap:
            (index) => ref.read(_selectedIndexProvider.notifier).state = index,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.explore_rounded),
            label: 'Discover',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications_rounded),
            label: 'Notifications',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.menu_rounded),
            label: 'Menu',
          ),
        ],
      ),
    );
  }
}
