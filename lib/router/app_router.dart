import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../screens/call_detail_screen.dart';
import '../screens/dashboard_screen.dart';
import '../screens/settings_screen.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  routes: <RouteBase>[
    GoRoute(
      path: '/',
      builder: (BuildContext context, GoRouterState state) =>
          const DashboardScreen(),
      routes: <RouteBase>[
        GoRoute(
          path: 'calls/:id',
          builder: (BuildContext context, GoRouterState state) =>
              CallDetailScreen(callId: state.pathParameters['id']!),
        ),
        GoRoute(
          path: 'settings',
          builder: (BuildContext context, GoRouterState state) =>
              const SettingsScreen(),
        ),
      ],
    ),
  ],
);
