import 'dart:async';
import 'dart:math';

import 'package:uuid/uuid.dart';

/// Abstraction over Vapi.ai / Retell AI inbound call orchestration.
///
/// In production this would open a websocket to Vapi or Retell, receive
/// call events (ringing, answered, ended), and stream partial transcripts.
/// For the POC every event is faked via [Future.delayed] + [StreamController].
abstract class VapiService {
  Stream<VapiEvent> get events;

  /// Simulates a WhatsApp Business call routed to the AI receptionist.
  Future<String> triggerIncomingCall({
    required String fromNumber,
    required String fromName,
  });

  Future<void> dispose();
}

class VapiEvent {
  VapiEvent({
    required this.callId,
    required this.type,
    this.payload,
  });

  final String callId;
  final VapiEventType type;
  final Map<String, Object?>? payload;
}

enum VapiEventType {
  ringing,
  answered,
  callEnded,
  error,
}

class MockVapiService implements VapiService {
  MockVapiService();

  final StreamController<VapiEvent> _controller =
      StreamController<VapiEvent>.broadcast();
  final Uuid _uuid = const Uuid();
  final Random _rng = Random();

  @override
  Stream<VapiEvent> get events => _controller.stream;

  @override
  Future<String> triggerIncomingCall({
    required String fromNumber,
    required String fromName,
  }) async {
    // MOCK: in production we'd POST to Vapi's `/call/phone` endpoint or
    // accept a webhook from Vapi. Here we synthesize the lifecycle.
    final String callId = _uuid.v4();

    unawaited(_simulateLifecycle(callId, fromNumber, fromName));
    return callId;
  }

  Future<void> _simulateLifecycle(
    String callId,
    String fromNumber,
    String fromName,
  ) async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    _controller.add(VapiEvent(
      callId: callId,
      type: VapiEventType.ringing,
      payload: <String, Object?>{
        'fromNumber': fromNumber,
        'fromName': fromName,
      },
    ));

    await Future<void>.delayed(const Duration(milliseconds: 1500));
    _controller.add(VapiEvent(callId: callId, type: VapiEventType.answered));

    // Simulated 12-25 second conversation window.
    final int seconds = 12 + _rng.nextInt(14);
    await Future<void>.delayed(Duration(seconds: seconds));
    _controller.add(VapiEvent(
      callId: callId,
      type: VapiEventType.callEnded,
      payload: <String, Object?>{'durationSeconds': seconds},
    ));
  }

  @override
  Future<void> dispose() async {
    await _controller.close();
  }
}
