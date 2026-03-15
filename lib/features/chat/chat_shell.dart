import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myoffgridai_client/config/constants.dart';
import 'package:myoffgridai_client/features/chat/widgets/chat_sidebar.dart';

/// Layout shell that wraps chat routes with a conversation sidebar.
///
/// On desktop (>= 600px) renders the sidebar alongside the content in a
/// [Row]. On mobile (< 600px) the sidebar is accessible via a [Drawer]
/// button in the app bar.
class ChatShell extends ConsumerWidget {
  /// The child widget from GoRouter's nested ShellRoute.
  final Widget child;

  /// Creates a [ChatShell] wrapping the given [child].
  const ChatShell({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final width = MediaQuery.sizeOf(context).width;
    final isMobile = width < AppConstants.mobileBreakpoint;

    if (isMobile) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Chat'),
          leading: Builder(
            builder: (ctx) => IconButton(
              icon: const Icon(Icons.menu),
              tooltip: 'Conversations',
              onPressed: () => Scaffold.of(ctx).openDrawer(),
            ),
          ),
        ),
        drawer: const Drawer(child: ChatSidebar()),
        body: child,
      );
    }

    // Desktop / tablet — sidebar + content side by side
    return Row(
      children: [
        const ChatSidebar(),
        const VerticalDivider(thickness: 1, width: 1),
        Expanded(child: child),
      ],
    );
  }
}
