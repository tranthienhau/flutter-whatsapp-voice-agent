import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../models/call.dart';
import '../providers/calls_provider.dart';
import '../widgets/state_chip.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final CallsState state = ref.watch(callsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('WhatsApp AI Receptionist'),
        actions: <Widget>[
          IconButton(
            tooltip: 'Settings',
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.go('/settings'),
          ),
        ],
      ),
      body: Column(
        children: <Widget>[
          _SummaryStrip(calls: state.calls),
          const Divider(height: 1),
          Expanded(
            child: state.calls.isEmpty
                ? const _EmptyState()
                : ListView.separated(
                    itemCount: state.calls.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (BuildContext context, int index) {
                      final CallRecord c = state.calls[index];
                      return _CallTile(call: c);
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () =>
            ref.read(callsProvider.notifier).simulateIncomingCall(),
        icon: const Icon(Icons.call),
        label: const Text('Fake incoming call'),
      ),
    );
  }
}

class _SummaryStrip extends StatelessWidget {
  const _SummaryStrip({required this.calls});

  final List<CallRecord> calls;

  @override
  Widget build(BuildContext context) {
    final int total = calls.length;
    final int booked = calls
        .where((CallRecord c) =>
            c.summary?.headline.toLowerCase().contains('appointment') ?? false)
        .length;
    final int urgent = calls
        .where((CallRecord c) =>
            c.summary?.headline.toLowerCase().contains('urgent') ?? false)
        .length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Row(
        children: <Widget>[
          _StatTile(label: 'Calls', value: '$total'),
          const SizedBox(width: 12),
          _StatTile(label: 'Bookings', value: '$booked'),
          const SizedBox(width: 12),
          _StatTile(label: 'Urgent', value: '$urgent'),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(value,
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(fontWeight: FontWeight.w700)),
            Text(label,
                style: Theme.of(context)
                    .textTheme
                    .labelMedium
                    ?.copyWith(color: scheme.onSurfaceVariant)),
          ],
        ),
      ),
    );
  }
}

class _CallTile extends StatelessWidget {
  const _CallTile({required this.call});

  final CallRecord call;

  String _fmtDuration(int seconds) {
    final int m = seconds ~/ 60;
    final int s = seconds % 60;
    return '${m}m ${s.toString().padLeft(2, '0')}s';
  }

  @override
  Widget build(BuildContext context) {
    final String when = DateFormat('MMM d, HH:mm').format(call.startedAt);
    return ListTile(
      onTap: () => context.go('/calls/${call.id}'),
      leading: CircleAvatar(
        backgroundColor:
            Theme.of(context).colorScheme.primaryContainer,
        child: Text(call.callerName.isNotEmpty ? call.callerName[0] : '?'),
      ),
      title: Text(call.callerName),
      subtitle: Text('${call.callerNumber}  -  $when  -  ${_fmtDuration(call.durationSeconds)}'),
      trailing: CallStateChip(state: call.state),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Icon(Icons.support_agent, size: 64),
            const SizedBox(height: 12),
            Text(
              'No calls yet. Tap "Fake incoming call" to simulate one.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ],
        ),
      ),
    );
  }
}
