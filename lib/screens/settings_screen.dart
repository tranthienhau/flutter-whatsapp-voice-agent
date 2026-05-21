import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/agent_settings.dart';
import '../providers/settings_provider.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  late final TextEditingController _numberCtrl;
  late final TextEditingController _greetingCtrl;
  late final TextEditingController _promptCtrl;

  @override
  void initState() {
    super.initState();
    final AgentSettings s = ref.read(settingsProvider);
    _numberCtrl = TextEditingController(text: s.whatsappBusinessNumber);
    _greetingCtrl = TextEditingController(text: s.greeting);
    _promptCtrl = TextEditingController(text: s.agentPrompt);
  }

  @override
  void dispose() {
    _numberCtrl.dispose();
    _greetingCtrl.dispose();
    _promptCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AgentSettings s = ref.watch(settingsProvider);
    final SettingsNotifier notifier = ref.read(settingsProvider.notifier);
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => context.go('/')),
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          Text('Channel',
              style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 8),
          TextField(
            controller: _numberCtrl,
            decoration: const InputDecoration(
              labelText: 'WhatsApp Business number',
              border: OutlineInputBorder(),
            ),
            onChanged: notifier.updateNumber,
          ),
          const SizedBox(height: 20),
          Text('Greeting',
              style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 8),
          TextField(
            controller: _greetingCtrl,
            minLines: 2,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Spoken greeting',
              border: OutlineInputBorder(),
            ),
            onChanged: notifier.updateGreeting,
          ),
          const SizedBox(height: 20),
          Text('Agent system prompt',
              style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 8),
          TextField(
            controller: _promptCtrl,
            minLines: 5,
            maxLines: 10,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
            ),
            onChanged: notifier.updatePrompt,
          ),
          const SizedBox(height: 20),
          SwitchListTile(
            value: s.useDarkMode,
            onChanged: notifier.toggleDarkMode,
            title: const Text('Dark mode'),
            subtitle: const Text('Toggle Material 3 dark theme'),
          ),
          const SizedBox(height: 16),
          Card(
            elevation: 0,
            color: Theme.of(context).colorScheme.tertiaryContainer,
            child: const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Portfolio POC notice: every external service (Vapi.ai, Retell AI, WhatsApp Business Calling API, Anthropic Claude, Supabase) is mocked. See README for production wiring.',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
