import 'package:flutter/foundation.dart';

/// State machine for an inbound WhatsApp Business voice call routed
/// through Vapi.ai / Retell AI to an AI receptionist.
enum CallState {
  idle,
  ringing,
  inProgress,
  transcribing,
  summarizing,
  completed,
  failed,
}

extension CallStateX on CallState {
  /// Returns the next valid state given a [trigger], or `null` if the
  /// transition is illegal. The state machine is intentionally strict
  /// so the UI cannot show inconsistent statuses.
  CallState? next(CallTrigger trigger) {
    switch (this) {
      case CallState.idle:
        if (trigger == CallTrigger.incomingCall) return CallState.ringing;
        break;
      case CallState.ringing:
        if (trigger == CallTrigger.agentAnswered) return CallState.inProgress;
        if (trigger == CallTrigger.missed) return CallState.failed;
        break;
      case CallState.inProgress:
        if (trigger == CallTrigger.callEnded) return CallState.transcribing;
        if (trigger == CallTrigger.error) return CallState.failed;
        break;
      case CallState.transcribing:
        if (trigger == CallTrigger.transcriptReady) {
          return CallState.summarizing;
        }
        if (trigger == CallTrigger.error) return CallState.failed;
        break;
      case CallState.summarizing:
        if (trigger == CallTrigger.summaryReady) return CallState.completed;
        if (trigger == CallTrigger.error) return CallState.failed;
        break;
      case CallState.completed:
      case CallState.failed:
        if (trigger == CallTrigger.reset) return CallState.idle;
        break;
    }
    return null;
  }

  String get label {
    switch (this) {
      case CallState.idle:
        return 'Idle';
      case CallState.ringing:
        return 'Ringing';
      case CallState.inProgress:
        return 'In progress';
      case CallState.transcribing:
        return 'Transcribing';
      case CallState.summarizing:
        return 'Summarizing';
      case CallState.completed:
        return 'Completed';
      case CallState.failed:
        return 'Failed';
    }
  }
}

enum CallTrigger {
  incomingCall,
  agentAnswered,
  missed,
  callEnded,
  transcriptReady,
  summaryReady,
  error,
  reset,
}

@immutable
class TranscriptTurn {
  const TranscriptTurn({
    required this.speaker,
    required this.text,
    required this.offsetMs,
  });

  final Speaker speaker;
  final String text;
  final int offsetMs;
}

enum Speaker { caller, agent }

@immutable
class CallSummary {
  const CallSummary({
    required this.headline,
    required this.actionItems,
    required this.sentiment,
  });

  final String headline;
  final List<String> actionItems;
  final String sentiment;
}

@immutable
class CallRecord {
  const CallRecord({
    required this.id,
    required this.callerNumber,
    required this.callerName,
    required this.startedAt,
    required this.durationSeconds,
    required this.state,
    required this.transcript,
    required this.summary,
    required this.audioUrl,
  });

  final String id;
  final String callerNumber;
  final String callerName;
  final DateTime startedAt;
  final int durationSeconds;
  final CallState state;
  final List<TranscriptTurn> transcript;
  final CallSummary? summary;
  final String audioUrl;

  CallRecord copyWith({
    CallState? state,
    List<TranscriptTurn>? transcript,
    CallSummary? summary,
    int? durationSeconds,
  }) {
    return CallRecord(
      id: id,
      callerNumber: callerNumber,
      callerName: callerName,
      startedAt: startedAt,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      state: state ?? this.state,
      transcript: transcript ?? this.transcript,
      summary: summary ?? this.summary,
      audioUrl: audioUrl,
    );
  }
}
