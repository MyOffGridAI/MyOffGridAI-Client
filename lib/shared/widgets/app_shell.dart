import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:myoffgridai_client/config/constants.dart';
import 'package:myoffgridai_client/shared/widgets/connection_lost_banner.dart';
import 'package:myoffgridai_client/shared/widgets/navigation_panel.dart';
import 'package:myoffgridai_client/shared/widgets/system_status_bar.dart';

/// Responsive scaffold with adaptive navigation for MyOffGridAI.
///
/// Uses [BottomNavigationBar] on mobile (< 600px) and [NavigationPanel]
/// on desktop (>= 600px). Includes [SystemStatusBar] at the top
/// and [ConnectionLostBanner] when the server is unreachable.
class AppShell extends ConsumerStatefulWidget {
  /// The child widget rendered in the content area (from GoRouter).
  final Widget child;

  /// Creates an [AppShell] wrapping the given [child].
  const AppShell({super.key, required this.child});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  int _selectedIndex = 0;

  static const _primaryDestinations = [
    AppConstants.routeHome,
    AppConstants.routeMemory,
    AppConstants.routeKnowledge,
    AppConstants.routeSensors,
  ];

  void _onDestinationSelected(int index) {
    if (index < _primaryDestinations.length) {
      setState(() => _selectedIndex = index);
      context.go(_primaryDestinations[index]);
    } else {
      // "More" tab — open the drawer
      Scaffold.of(context).openEndDrawer();
    }
  }

  int _calculateSelectedIndex() {
    final location = GoRouterState.of(context).matchedLocation;
    for (int i = 0; i < _primaryDestinations.length; i++) {
      if (location == _primaryDestinations[i] ||
          (i == 0 && location.startsWith('/chat'))) {
        return i;
      }
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isMobile = width < AppConstants.mobileBreakpoint;
    _selectedIndex = _calculateSelectedIndex();

    return Scaffold(
      endDrawer: _buildDrawer(context),
      body: Column(
        children: [
          const ConnectionLostBanner(),
          const SystemStatusBar(),
          Expanded(
            child: isMobile
                ? widget.child
                : Row(
                    children: [
                      NavigationPanel(
                        onOpenMoreDrawer: () =>
                            Scaffold.of(context).openEndDrawer(),
                      ),
                      Expanded(child: widget.child),
                    ],
                  ),
          ),
        ],
      ),
      bottomNavigationBar: isMobile
          ? BottomNavigationBar(
              currentIndex: _selectedIndex,
              onTap: _onDestinationSelected,
              type: BottomNavigationBarType.fixed,
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.chat_bubble_outline),
                  activeIcon: Icon(Icons.chat_bubble),
                  label: 'Chat',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.psychology_outlined),
                  activeIcon: Icon(Icons.psychology),
                  label: 'Memory',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.library_books_outlined),
                  activeIcon: Icon(Icons.library_books),
                  label: 'Knowledge',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.sensors),
                  activeIcon: Icon(Icons.sensors),
                  label: 'Sensors',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.more_horiz),
                  activeIcon: Icon(Icons.more_horiz),
                  label: 'More',
                ),
              ],
            )
          : null,
    );
  }

  Drawer _buildDrawer(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const DrawerHeader(
            child: Text(
              'MyOffGrid AI',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.auto_fix_high),
            title: const Text('Skills'),
            onTap: () {
              Navigator.pop(context);
              context.go(AppConstants.routeSkills);
            },
          ),
          ListTile(
            leading: const Icon(Icons.inventory_2_outlined),
            title: const Text('Inventory'),
            onTap: () {
              Navigator.pop(context);
              context.go(AppConstants.routeInventory);
            },
          ),
          ListTile(
            leading: const Icon(Icons.insights),
            title: const Text('Insights'),
            onTap: () {
              Navigator.pop(context);
              context.go(AppConstants.routeInsights);
            },
          ),
          ListTile(
            leading: const Icon(Icons.shield_outlined),
            title: const Text('Privacy'),
            onTap: () {
              Navigator.pop(context);
              context.go(AppConstants.routePrivacy);
            },
          ),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('System'),
            onTap: () {
              Navigator.pop(context);
              context.go(AppConstants.routeSystem);
            },
          ),
          ListTile(
            leading: const Icon(Icons.people),
            title: const Text('Users'),
            onTap: () {
              Navigator.pop(context);
              context.go(AppConstants.routeUsers);
            },
          ),
        ],
      ),
    );
  }
}
