import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myoffgridai_client/core/api/providers.dart';

/// Orange/amber banner displayed when the MyOffGridAI server is unreachable.
///
/// Listens to [connectionStatusProvider] and auto-dismisses when
/// the connection is restored. Polls the server every 10 seconds.
class ConnectionLostBanner extends ConsumerWidget {
  /// Creates a [ConnectionLostBanner].
  const ConnectionLostBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connectionAsync = ref.watch(connectionStatusProvider);

    return connectionAsync.when(
      data: (connected) {
        if (connected) return const SizedBox.shrink();
        return MaterialBanner(
          content: const Text(
            'Cannot reach MyOffGrid AI \u2014 check your network connection',
          ),
          backgroundColor: Colors.amber.shade800,
          contentTextStyle: const TextStyle(color: Colors.white),
          actions: const [SizedBox.shrink()],
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}
