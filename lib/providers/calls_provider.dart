import 'dart:async';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../models/call.dart';
import '../services/summary_service.dart';
import '../services/transcription_service.dart';
import '../services/vapi_service.dart';
import '../services/whatsapp_service.dart';
import 'services.dart';

/// Holds the in-memory list of calls + currently active call.
class CallsState {
  CallsState({required this.calls, this.activeCallId});

  final List<CallRecord> calls;
  final String? activeCallId;

  CallsState copyWith({List<CallRecord>? calls, String? activeCallId}) {
    return CallsState(
      calls: calls ?? this.calls,
      activeCallId: activeCallId ?? this.activeCallId,
    );
  }

  CallRecord? get activeCall {
    if (activeCallId == null) return null;
    for (final CallRecord c in calls) {
      if (c.id == activeCallId) return c;
    }
    return null;
  }

  CallRecord? byId(String id) {
    for (final CallRecord c in calls) {
      if (c.id == id) return c;
    }
    return null;
  }
}

class CallsController extends StateNotifier<CallsState> {
  CallsController({
    required this.vapi,
    required this.whatsapp,
    required this.transcription,
    required this.summary,
  }) : super(CallsState(calls: _seed())) {
    _eventSub = vapi.events.listen(_onVapiEvent);
  }

  final VapiService vapi;
  final WhatsAppService whatsapp;
  final TranscriptionService transcription;
  final SummaryService summary;

  StreamSubscription<VapiEvent>? _eventSub;
  final Uuid _uuid = const Uuid();
  final Random _rng = Random();

  static List<CallRecord> _seed() {
    final DateTime now = DateTime.now();
    return <CallRecord>[
      CallRecord(
        id: 'seed-1',
        callerNumber: '+1 415 555 8821',
        callerName: 'Marta Reyes',
        startedAt: now.subtract(const Duration(hours: 2, minutes: 14)),
        durationSeconds: 92,
        state: CallState.completed,
        transcript: const <TranscriptTurn>[
          TranscriptTurn(
              speaker: Speaker.caller,
              text: 'Hi, I would like to book a cleaning for next week.',
              offsetMs: 800),
          TranscriptTurn(
              speaker: Speaker.agent,
              text:
                  'Of course, we have Tuesday at 10am or Thursday at 2pm. Which works?',
              offsetMs: 3200),
          TranscriptTurn(
              speaker: Speaker.caller,
              text: 'Thursday at 2pm sounds good.',
              offsetMs: 6800),
          TranscriptTurn(
              speaker: Speaker.agent,
              text: 'Booked, I will send a WhatsApp confirmation shortly.',
              offsetMs: 9100),
        ],
        summary: const CallSummary(
          headline: 'New appointment booking request',
          actionItems: <String>[
            'Confirm appointment slot via WhatsApp',
            'Add Marta to Thursday 2pm cleaning slot',
          ],
          sentiment: 'positive',
        ),
        audioUrl: 'mock://audio/seed-1.m4a',
      ),
      CallRecord(
        id: 'seed-2',
        callerNumber: '+1 628 555 0199',
        callerName: 'Devon Park',
        startedAt: now.subtract(const Duration(days: 1, hours: 4)),
        durationSeconds: 48,
        state: CallState.completed,
        transcript: const <TranscriptTurn>[
          TranscriptTurn(
              speaker: Speaker.caller,
              text: 'How much is a whitening session?',
              offsetMs: 800),
          TranscriptTurn(
              speaker: Speaker.agent,
              text: 'In-clinic whitening starts at 320 dollars.',
              offsetMs: 2900),
        ],
        summary: const CallSummary(
          headline: 'Pricing enquiry, lead captured',
          actionItems: <String>['Send pricing sheet over WhatsApp'],
          sentiment: 'neutral',
        ),
        audioUrl: 'mock://audio/seed-2.m4a',
      ),
    ];
  }

  static const List<List<String>> _mockCallers = <List<String>>[
    <String>['+1 415 555 0143', 'Sam Patel'],
    <String>['+1 628 555 7732', 'Lina Ortiz'],
    <String>['+1 510 555 9006', 'Jamal Brooks'],
    <String>['+44 20 7946 0019', 'Eve Whitman'],
  ];

  /// User-facing trigger from the dashboard "fake incoming call" button.
  Future<void> simulateIncomingCall() async {
    final List<String> caller = _mockCallers[_rng.nextInt(_mockCallers.length)];
    final String tempId = _uuid.v4();
    // Optimistically insert a record so the UI updates immediately.
    final CallRecord record = CallRecord(
      id: tempId,
      callerNumber: caller[0],
      callerName: caller[1],
      startedAt: DateTime.now(),
      durationSeconds: 0,
      state: CallState.ringing,
      transcript: const <TranscriptTurn>[],
      summary: null,
      audioUrl: 'mock://audio/$tempId.m4a',
    );
    state = state.copyWith(
      calls: <CallRecord>[record, ...state.calls],
      activeCallId: tempId,
    );

    // Tell the WhatsApp Business API we accept the inbound call (mock).
    await whatsapp.acceptCall(tempId);

    // Kick off the Vapi/Retell lifecycle (mock).
    await vapi.triggerIncomingCall(
      fromNumber: caller[0],
      fromName: caller[1],
    );
  }

  void _onVapiEvent(VapiEvent event) {
    final CallRecord? active = state.activeCall;
    if (active == null) return;

    switch (event.type) {
      case VapiEventType.ringing:
        _replace(active.copyWith(state: CallState.ringing));
        break;
      case VapiEventType.answered:
        _replace(active.copyWith(state: CallState.inProgress));
        break;
      case VapiEventType.callEnded:
        final int duration =
            (event.payload?['durationSeconds'] as int?) ?? active.durationSeconds;
        _replace(active.copyWith(
          state: CallState.transcribing,
          durationSeconds: duration,
        ));
        unawaited(_finalizeCall(active.id));
        break;
      case VapiEventType.error:
        _replace(active.copyWith(state: CallState.failed));
        break;
    }
  }

  Future<void> _finalizeCall(String callId) async {
    final List<TranscriptTurn> transcript =
        await transcription.getFinalTranscript(callId);
    CallRecord? current = state.byId(callId);
    if (current == null) return;
    _replace(current.copyWith(
      state: CallState.summarizing,
      transcript: transcript,
    ));

    final CallSummary result = await summary.summarize(transcript);
    current = state.byId(callId);
    if (current == null) return;
    _replace(current.copyWith(
      state: CallState.completed,
      summary: result,
    ));

    // Send a WhatsApp follow-up containing the headline + action items.
    final String firstAction =
        result.actionItems.isNotEmpty ? result.actionItems.first : 'No action';
    final String body = '${result.headline}. Next: $firstAction.';
    await whatsapp.sendFollowupMessage(
      toNumber: current.callerNumber,
      body: body,
    );
  }

  void _replace(CallRecord updated) {
    final List<CallRecord> next = state.calls
        .map((CallRecord c) => c.id == updated.id ? updated : c)
        .toList();
    state = state.copyWith(calls: next);
  }

  @override
  void dispose() {
    _eventSub?.cancel();
    super.dispose();
  }
}

final StateNotifierProvider<CallsController, CallsState> callsProvider =
    StateNotifierProvider<CallsController, CallsState>((Ref ref) {
  return CallsController(
    vapi: ref.watch(vapiServiceProvider),
    whatsapp: ref.watch(whatsappServiceProvider),
    transcription: ref.watch(transcriptionServiceProvider),
    summary: ref.watch(summaryServiceProvider),
  );
});

final ProviderFamily<CallRecord?, String> callByIdProvider =
    Provider.family<CallRecord?, String>((Ref ref, String id) {
  return ref.watch(callsProvider).byId(id);
});
