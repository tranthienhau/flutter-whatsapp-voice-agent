import 'package:flutter/material.dart';

import '../models/call.dart';

class CallStateChip extends StatelessWidget {
  const CallStateChip({super.key, required this.state});

  final CallState state;

  Color _bg(ColorScheme scheme) {
    switch (state) {
      case CallState.completed:
        return scheme.primaryContainer;
      case CallState.failed:
        return scheme.errorContainer;
      case CallState.ringing:
      case CallState.inProgress:
      case CallState.transcribing:
      case CallState.summarizing:
        return scheme.tertiaryContainer;
      case CallState.idle:
        return scheme.surfaceContainerHighest;
    }
  }

  Color _fg(ColorScheme scheme) {
    switch (state) {
      case CallState.completed:
        return scheme.onPrimaryContainer;
      case CallState.failed:
        return scheme.onErrorContainer;
      case CallState.ringing:
      case CallState.inProgress:
      case CallState.transcribing:
      case CallState.summarizing:
        return scheme.onTertiaryContainer;
      case CallState.idle:
        return scheme.onSurfaceVariant;
    }
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _bg(scheme),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        state.label,
        style: Theme.of(context)
            .textTheme
            .labelSmall
            ?.copyWith(color: _fg(scheme), fontWeight: FontWeight.w600),
      ),
    );
  }
}
