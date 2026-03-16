import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:myoffgridai_client/config/constants.dart';
import 'package:myoffgridai_client/core/api/providers.dart';
import 'package:myoffgridai_client/shared/widgets/connection_lost_banner.dart';
import 'package:myoffgridai_client/shared/widgets/navigation_panel.dart';
import 'package:myoffgridai_client/shared/widgets/notification_badge.dart';
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
    AppConstants.routeNotifications,
  ];

  void _onDestinationSelected(int index) {
    if (index < _primaryDestinations.length) {
      setState(() => _selectedIndex = index);
      context.go(_primaryDestinations[index]);
    }
  }

  int _calculateSelectedIndex() {
    final location = GoRouterState.of(context).matchedLocation;
    for (int i = 0; i < _primaryDestinations.length; i++) {
      if (location == _primaryDestinations[i] ||
          (i == 0 && location.startsWith('/chat')) ||
          (i == 4 && location.startsWith('/notifications'))) {
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
      body: Column(
        children: [
          const ConnectionLostBanner(),
          const SystemStatusBar(),
          Expanded(
            child: isMobile
                ? widget.child
                : Row(
                    children: [
                      const NavigationPanel(),
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
                  icon: _AlertsIcon(),
                  activeIcon: _AlertsIcon(selected: true),
                  label: 'Alerts',
                ),
              ],
            )
          : null,
    );
  }
}

class _AlertsIcon extends ConsumerWidget {
  final bool selected;

  const _AlertsIcon({this.selected = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unreadAsync = ref.watch(unreadCountProvider);
    final count = unreadAsync.valueOrNull ?? 0;
    final icon = selected
        ? const Icon(Icons.notifications)
        : const Icon(Icons.notifications_outlined);

    if (count == 0) return icon;

    return NotificationBadge(count: count, child: icon);
  }
}
