import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/agent_settings.dart';

class SettingsNotifier extends StateNotifier<AgentSettings> {
  SettingsNotifier() : super(AgentSettings.demo);

  void updateNumber(String value) =>
      state = state.copyWith(whatsappBusinessNumber: value);

  void updatePrompt(String value) => state = state.copyWith(agentPrompt: value);

  void updateGreeting(String value) => state = state.copyWith(greeting: value);

  void toggleDarkMode(bool value) =>
      state = state.copyWith(useDarkMode: value);
}

final StateNotifierProvider<SettingsNotifier, AgentSettings> settingsProvider =
    StateNotifierProvider<SettingsNotifier, AgentSettings>(
        (Ref ref) => SettingsNotifier());
