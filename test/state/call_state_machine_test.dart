import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_whatsapp_voice_agent/models/call.dart';

void main() {
  group('CallState machine', () {
    test('happy path drives idle -> completed', () {
      CallState s = CallState.idle;
      s = s.next(CallTrigger.incomingCall)!;
      expect(s, CallState.ringing);
      s = s.next(CallTrigger.agentAnswered)!;
      expect(s, CallState.inProgress);
      s = s.next(CallTrigger.callEnded)!;
      expect(s, CallState.transcribing);
      s = s.next(CallTrigger.transcriptReady)!;
      expect(s, CallState.summarizing);
      s = s.next(CallTrigger.summaryReady)!;
      expect(s, CallState.completed);
    });

    test('missed call moves ringing -> failed', () {
      final CallState? s =
          CallState.ringing.next(CallTrigger.missed);
      expect(s, CallState.failed);
    });

    test('illegal transitions return null', () {
      expect(CallState.idle.next(CallTrigger.summaryReady), isNull);
      expect(CallState.inProgress.next(CallTrigger.incomingCall), isNull);
      expect(CallState.completed.next(CallTrigger.callEnded), isNull);
    });

    test('error during inProgress moves to failed', () {
      expect(CallState.inProgress.next(CallTrigger.error), CallState.failed);
    });

    test('reset returns terminal states to idle', () {
      expect(CallState.completed.next(CallTrigger.reset), CallState.idle);
      expect(CallState.failed.next(CallTrigger.reset), CallState.idle);
    });

    test('labels are human readable', () {
      expect(CallState.ringing.label, 'Ringing');
      expect(CallState.summarizing.label, 'Summarizing');
    });
  });
}
