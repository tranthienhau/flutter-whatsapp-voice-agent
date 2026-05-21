import 'dart:async';

import '../models/call.dart';

/// Generates a structured summary + action items from a finished transcript.
///
/// Production: send the transcript to Anthropic Claude (Haiku for cost,
/// Sonnet for quality) with a JSON-mode prompt that returns
/// `{ headline, action_items, sentiment }`. Persist to Supabase.
abstract class SummaryService {
  Future<CallSummary> summarize(List<TranscriptTurn> transcript);
}

class MockSummaryService implements SummaryService {
  @override
  Future<CallSummary> summarize(List<TranscriptTurn> transcript) async {
    // MOCK: in production we'd call Anthropic's Messages API. The logic
    // below uses simple heuristics so tests can assert on it deterministically.
    await Future<void>.delayed(const Duration(milliseconds: 400));
    return generateMockSummary(transcript);
  }
}

/// Deterministic summary generator extracted so it can be unit tested
/// without spinning up a service or fake clock.
CallSummary generateMockSummary(List<TranscriptTurn> transcript) {
  if (transcript.isEmpty) {
    return const CallSummary(
      headline: 'Empty call',
      actionItems: <String>[],
      sentiment: 'neutral',
    );
  }

  final String joined =
      transcript.map((TranscriptTurn t) => t.text.toLowerCase()).join(' ');

  final List<String> actions = <String>[];
  if (joined.contains('book') || joined.contains('appointment')) {
    actions.add('Confirm appointment slot via WhatsApp');
  }
  if (joined.contains('urgent') ||
      joined.contains('emergency') ||
      joined.contains('crown fell')) {
    actions.add('Flag as urgent and notify on-call dentist');
  }
  if (joined.contains('price') ||
      joined.contains('cost') ||
      joined.contains('how much') ||
      joined.contains('dollars')) {
    actions.add('Send pricing sheet over WhatsApp');
  }
  if (joined.contains('think about it') || joined.contains('let me')) {
    actions.add('Schedule a follow-up reminder in 48 hours');
  }
  if (actions.isEmpty) {
    actions.add('No action required, archive transcript');
  }

  String headline;
  if (joined.contains('urgent') || joined.contains('emergency')) {
    headline = 'Urgent dental request, same-day slot offered';
  } else if (joined.contains('book') || joined.contains('appointment')) {
    headline = 'New appointment booking request';
  } else if (joined.contains('price') || joined.contains('how much')) {
    headline = 'Pricing enquiry, lead captured';
  } else {
    headline = 'General enquiry handled by AI receptionist';
  }

  String sentiment;
  if (joined.contains('great') ||
      joined.contains('thanks') ||
      joined.contains('sounds good')) {
    sentiment = 'positive';
  } else if (joined.contains('urgent') || joined.contains('emergency')) {
    sentiment = 'concerned';
  } else {
    sentiment = 'neutral';
  }

  return CallSummary(
    headline: headline,
    actionItems: actions,
    sentiment: sentiment,
  );
}
