import 'dart:async';
import 'dart:math';

import '../models/call.dart';

/// Streams partial then final transcripts for a call.
///
/// Production options: Vapi/Retell already include STT; alternatives are
/// Deepgram, AssemblyAI, OpenAI Whisper, or Google Speech-to-Text.
abstract class TranscriptionService {
  Stream<TranscriptTurn> streamTranscript(String callId);
  Future<List<TranscriptTurn>> getFinalTranscript(String callId);
}

class MockTranscriptionService implements TranscriptionService {
  final Random _rng = Random();

  static const List<List<String>> _scripts = <List<String>>[
    <String>[
      'Hi, I would like to book a cleaning for next week if possible.',
      'Of course. We have Tuesday at 10am or Thursday at 2pm. Which works?',
      'Thursday at 2pm sounds good.',
      'Booked. I will send you a WhatsApp confirmation in a moment.',
    ],
    <String>[
      'Hey, my crown fell out last night. Can someone see me today?',
      'That sounds urgent. I can fit you in at 4pm with Dr. Chen.',
      'Yes please, I will be there.',
      'Great, see you at 4. I will text the address now.',
    ],
    <String>[
      'How much is a teeth whitening session?',
      'Our in-clinic whitening starts at 320 dollars and takes about an hour.',
      'Okay, can I think about it?',
      'Absolutely, I will message you the package details.',
    ],
  ];

  @override
  Stream<TranscriptTurn> streamTranscript(String callId) async* {
    // MOCK: real impl would subscribe to Vapi's partial transcript events.
    final List<String> script = _scripts[_rng.nextInt(_scripts.length)];
    int offset = 800;
    for (int i = 0; i < script.length; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 1200));
      yield TranscriptTurn(
        speaker: i.isEven ? Speaker.caller : Speaker.agent,
        text: script[i],
        offsetMs: offset,
      );
      offset += 2200 + _rng.nextInt(1800);
    }
  }

  @override
  Future<List<TranscriptTurn>> getFinalTranscript(String callId) async {
    // MOCK: return a deterministic transcript for replay in call detail view.
    await Future<void>.delayed(const Duration(milliseconds: 300));
    final List<String> script = _scripts[callId.hashCode.abs() % _scripts.length];
    int offset = 800;
    final List<TranscriptTurn> turns = <TranscriptTurn>[];
    for (int i = 0; i < script.length; i++) {
      turns.add(TranscriptTurn(
        speaker: i.isEven ? Speaker.caller : Speaker.agent,
        text: script[i],
        offsetMs: offset,
      ));
      offset += 2400;
    }
    return turns;
  }
}
