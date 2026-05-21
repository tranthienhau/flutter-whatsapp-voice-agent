import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/summary_service.dart';
import '../services/transcription_service.dart';
import '../services/vapi_service.dart';
import '../services/whatsapp_service.dart';

/// Service-locator style providers. Swap the mock for a real impl by
/// overriding these in `ProviderScope` (e.g. in a flavored entrypoint).
final Provider<VapiService> vapiServiceProvider = Provider<VapiService>((Ref ref) {
  final MockVapiService service = MockVapiService();
  ref.onDispose(service.dispose);
  return service;
});

final Provider<WhatsAppService> whatsappServiceProvider =
    Provider<WhatsAppService>((Ref ref) => MockWhatsAppService());

final Provider<TranscriptionService> transcriptionServiceProvider =
    Provider<TranscriptionService>((Ref ref) => MockTranscriptionService());

final Provider<SummaryService> summaryServiceProvider =
    Provider<SummaryService>((Ref ref) => MockSummaryService());
