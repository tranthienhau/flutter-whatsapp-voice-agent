import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_whatsapp_voice_agent/models/call.dart';
import 'package:flutter_whatsapp_voice_agent/services/summary_service.dart';

void main() {
  group('generateMockSummary', () {
    test('returns empty-call summary for no transcript', () {
      final CallSummary s = generateMockSummary(const <TranscriptTurn>[]);
      expect(s.headline, 'Empty call');
      expect(s.actionItems, isEmpty);
      expect(s.sentiment, 'neutral');
    });

    test('detects booking intent', () {
      final CallSummary s = generateMockSummary(const <TranscriptTurn>[
        TranscriptTurn(
            speaker: Speaker.caller,
            text: 'I want to book an appointment for next week',
            offsetMs: 0),
        TranscriptTurn(
            speaker: Speaker.agent,
            text: 'Sure, sounds good, I have Tuesday open',
            offsetMs: 1000),
      ]);
      expect(s.headline, contains('appointment'));
      expect(s.actionItems,
          contains('Confirm appointment slot via WhatsApp'));
      expect(s.sentiment, 'positive');
    });

    test('flags urgent / emergency wording', () {
      final CallSummary s = generateMockSummary(const <TranscriptTurn>[
        TranscriptTurn(
            speaker: Speaker.caller,
            text: 'This is urgent, my crown fell out',
            offsetMs: 0),
      ]);
      expect(s.headline.toLowerCase(), contains('urgent'));
      expect(
        s.actionItems,
        contains('Flag as urgent and notify on-call dentist'),
      );
      expect(s.sentiment, 'concerned');
    });

    test('detects pricing enquiry', () {
      final CallSummary s = generateMockSummary(const <TranscriptTurn>[
        TranscriptTurn(
            speaker: Speaker.caller,
            text: 'How much is a whitening session?',
            offsetMs: 0),
        TranscriptTurn(
            speaker: Speaker.agent,
            text: 'It is 320 dollars.',
            offsetMs: 1000),
      ]);
      expect(s.headline.toLowerCase(), contains('pricing'));
      expect(s.actionItems, contains('Send pricing sheet over WhatsApp'));
    });

    test('falls back to general enquiry', () {
      final CallSummary s = generateMockSummary(const <TranscriptTurn>[
        TranscriptTurn(
            speaker: Speaker.caller,
            text: 'Hi, just wondering about your hours',
            offsetMs: 0),
      ]);
      expect(s.headline, contains('General enquiry'));
      expect(s.actionItems, isNotEmpty);
    });
  });
}
