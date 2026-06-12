import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:flutter_whatsapp_voice_agent/router/app_router.dart';
import 'package:flutter_whatsapp_voice_agent/theme/app_theme.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  Future<void> shoot(WidgetTester tester, String name) async {
    await binding.convertFlutterSurfaceToImage();
    await tester.pumpAndSettle();
    await binding.takeScreenshot(name);
  }

  testWidgets('capture receptionist flow', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp.router(
          title: 'WhatsApp AI Receptionist',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light(),
          routerConfig: appRouter,
        ),
      ),
    );
    await tester.pumpAndSettle();

    // 01 - Dashboard with seeded call history + stats strip.
    await shoot(tester, '01-dashboard');

    // 02 - Call detail: tap the first seeded call (Marta Reyes).
    await tester.tap(find.text('Marta Reyes'));
    await tester.pumpAndSettle();
    await shoot(tester, '02-call-detail');

    // Back to the dashboard.
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();

    // 03 - Settings: tap the settings action in the app bar.
    await tester.tap(find.byTooltip('Settings'));
    await tester.pumpAndSettle();
    await shoot(tester, '03-settings');
  });
}
