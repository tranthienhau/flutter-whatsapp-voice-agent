import 'dart:async';

/// Abstraction over Meta's WhatsApp Business Calling API.
///
/// Real wiring would call the Graph API (`/v22.0/PHONE_NUMBER_ID/calls`)
/// to accept, route, or terminate a call, and verify webhook signatures
/// using the app secret. This POC keeps the contract and returns mocks.
abstract class WhatsAppService {
  Future<bool> acceptCall(String callId);
  Future<bool> rejectCall(String callId, {String? reason});
  Future<void> sendFollowupMessage({
    required String toNumber,
    required String body,
  });
}

class MockWhatsAppService implements WhatsAppService {
  final List<MockMessage> sent = <MockMessage>[];

  @override
  Future<bool> acceptCall(String callId) async {
    // MOCK: real call would be POST /v22.0/{phone_number_id}/calls
    // with { action: "accept", call_id: callId, session: {...} }
    await Future<void>.delayed(const Duration(milliseconds: 200));
    return true;
  }

  @override
  Future<bool> rejectCall(String callId, {String? reason}) async {
    // MOCK: real call would be POST /v22.0/{phone_number_id}/calls
    // with { action: "terminate", call_id: callId }
    await Future<void>.delayed(const Duration(milliseconds: 150));
    return true;
  }

  @override
  Future<void> sendFollowupMessage({
    required String toNumber,
    required String body,
  }) async {
    // MOCK: real call would be POST /v22.0/{phone_number_id}/messages
    // with a text template body. Useful after a call to send the booking
    // confirmation, payment link, or action item summary back to the caller.
    await Future<void>.delayed(const Duration(milliseconds: 250));
    sent.add(MockMessage(to: toNumber, body: body, sentAt: DateTime.now()));
  }
}

class MockMessage {
  MockMessage({required this.to, required this.body, required this.sentAt});

  final String to;
  final String body;
  final DateTime sentAt;
}
