import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../models/call.dart';
import '../providers/calls_provider.dart';
import '../widgets/state_chip.dart';

class CallDetailScreen extends ConsumerStatefulWidget {
  const CallDetailScreen({super.key, required this.callId});

  final String callId;

  @override
  ConsumerState<CallDetailScreen> createState() => _CallDetailScreenState();
}

class _CallDetailScreenState extends ConsumerState<CallDetailScreen> {
  bool _playing = false;
  double _progress = 0.0;

  @override
  Widget build(BuildContext context) {
    final CallRecord? call = ref.watch(callByIdProvider(widget.callId));
    if (call == null) {
      return Scaffold(
        appBar: AppBar(
          leading: BackButton(onPressed: () => context.go('/')),
        ),
        body: const Center(child: Text('Call not found')),
      );
    }
    final String when = DateFormat('EEE MMM d, HH:mm').format(call.startedAt);

    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => context.go('/')),
        title: Text(call.callerName),
        actions: <Widget>[
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Center(child: CallStateChip(state: call.state)),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          _MetaCard(call: call, when: when),
          const SizedBox(height: 16),
          _PlayerCard(
            playing: _playing,
            progress: _progress,
            durationSeconds: call.durationSeconds,
            onPlayPause: () => setState(() => _playing = !_playing),
            onSeek: (double v) => setState(() => _progress = v),
          ),
          const SizedBox(height: 16),
          _SummaryCard(summary: call.summary, state: call.state),
          const SizedBox(height: 16),
          _TranscriptCard(transcript: call.transcript),
        ],
      ),
    );
  }
}

class _MetaCard extends StatelessWidget {
  const _MetaCard({required this.call, required this.when});

  final CallRecord call;
  final String when;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Card(
      elevation: 0,
      color: scheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(call.callerNumber,
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(when, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 4),
            Text('Duration ${call.durationSeconds}s',
                style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}

class _PlayerCard extends StatelessWidget {
  const _PlayerCard({
    required this.playing,
    required this.progress,
    required this.durationSeconds,
    required this.onPlayPause,
    required this.onSeek,
  });

  final bool playing;
  final double progress;
  final int durationSeconds;
  final VoidCallback onPlayPause;
  final ValueChanged<double> onSeek;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final int elapsed = (durationSeconds * progress).round();
    return Card(
      elevation: 0,
      color: scheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: <Widget>[
            IconButton.filled(
              onPressed: onPlayPause,
              icon: Icon(playing ? Icons.pause : Icons.play_arrow),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text('Recording (mock playback)',
                      style: Theme.of(context).textTheme.labelLarge),
                  Slider(
                    value: progress.clamp(0.0, 1.0),
                    onChanged: onSeek,
                  ),
                  Text('${elapsed}s / ${durationSeconds}s',
                      style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.summary, required this.state});

  final CallSummary? summary;
  final CallState state;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    if (summary == null) {
      return Card(
        elevation: 0,
        color: scheme.surfaceContainerHighest,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: <Widget>[
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              const SizedBox(width: 12),
              Text(state == CallState.summarizing
                  ? 'Generating Claude summary...'
                  : state == CallState.transcribing
                      ? 'Transcribing call...'
                      : 'Awaiting completion...'),
            ],
          ),
        ),
      );
    }
    final CallSummary s = summary!;
    return Card(
      elevation: 0,
      color: scheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text('AI summary',
                style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 4),
            Text(s.headline,
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text('Sentiment: ${s.sentiment}',
                style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 12),
            Text('Action items',
                style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 4),
            ...s.actionItems.map((String a) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      const Text('-  '),
                      Expanded(child: Text(a)),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }
}

class _TranscriptCard extends StatelessWidget {
  const _TranscriptCard({required this.transcript});

  final List<TranscriptTurn> transcript;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    if (transcript.isEmpty) {
      return Card(
        elevation: 0,
        color: scheme.surfaceContainerHighest,
        child: const Padding(
          padding: EdgeInsets.all(16),
          child: Text('Transcript will appear here once the call ends.'),
        ),
      );
    }
    return Card(
      elevation: 0,
      color: scheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text('Transcript',
                style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 8),
            for (final TranscriptTurn t in transcript)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _TurnBubble(turn: t),
              ),
          ],
        ),
      ),
    );
  }
}

class _TurnBubble extends StatelessWidget {
  const _TurnBubble({required this.turn});

  final TranscriptTurn turn;

  @override
  Widget build(BuildContext context) {
    final bool isAgent = turn.speaker == Speaker.agent;
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Align(
      alignment: isAgent ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isAgent ? scheme.primaryContainer : scheme.secondaryContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                isAgent ? 'Agent' : 'Caller',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 2),
              Text(turn.text,
                  style: Theme.of(context).textTheme.bodyMedium),
            ],
          ),
        ),
      ),
    );
  }
}
