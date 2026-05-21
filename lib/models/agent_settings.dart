import 'package:flutter/foundation.dart';

@immutable
class AgentSettings {
  const AgentSettings({
    required this.whatsappBusinessNumber,
    required this.agentPrompt,
    required this.greeting,
    required this.useDarkMode,
  });

  final String whatsappBusinessNumber;
  final String agentPrompt;
  final String greeting;
  final bool useDarkMode;

  AgentSettings copyWith({
    String? whatsappBusinessNumber,
    String? agentPrompt,
    String? greeting,
    bool? useDarkMode,
  }) {
    return AgentSettings(
      whatsappBusinessNumber:
          whatsappBusinessNumber ?? this.whatsappBusinessNumber,
      agentPrompt: agentPrompt ?? this.agentPrompt,
      greeting: greeting ?? this.greeting,
      useDarkMode: useDarkMode ?? this.useDarkMode,
    );
  }

  static const AgentSettings demo = AgentSettings(
    whatsappBusinessNumber: '+1 415 555 0142',
    greeting:
        'Hi, thanks for calling Northbay Dental. This is Aria, the AI receptionist. How can I help today?',
    agentPrompt:
        'You are Aria, the front desk receptionist for Northbay Dental. '
        'Book appointments, answer pricing questions, and escalate emergencies '
        'to the on-call dentist. Keep replies under 2 sentences.',
    useDarkMode: true,
  );
}
