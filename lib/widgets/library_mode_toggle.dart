import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../book_library_state.dart';

class LibraryModeToggle extends StatelessWidget {
  const LibraryModeToggle({super.key, this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<BookLibraryState>();
    final mode = state.mode;
    final next = mode == LibraryMode.online ? LibraryMode.offline : LibraryMode.online;
    final label = mode == LibraryMode.online ? 'Online' : 'Offline';
    final icon = mode == LibraryMode.online ? Icons.wifi_rounded : Icons.wifi_off_rounded;

    return FilledButton.tonalIcon(
      onPressed: () => context.read<BookLibraryState>().setMode(next),
      icon: Icon(icon, size: compact ? 18 : null),
      label: Text(label),
      style: FilledButton.styleFrom(
        visualDensity: compact ? VisualDensity.compact : null,
        padding: compact ? const EdgeInsets.symmetric(horizontal: 12, vertical: 10) : null,
      ),
    );
  }
}

