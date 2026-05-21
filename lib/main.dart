import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'providers/settings_provider.dart';
import 'router/app_router.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const ProviderScope(child: WhatsAppVoiceAgentApp()));
}

class WhatsAppVoiceAgentApp extends ConsumerWidget {
  const WhatsAppVoiceAgentApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool dark = ref.watch(settingsProvider).useDarkMode;
    return MaterialApp.router(
      title: 'WhatsApp AI Receptionist',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: dark ? ThemeMode.dark : ThemeMode.light,
      routerConfig: appRouter,
    );
  }
}
