import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:paisa_khai/screens/categories_screen.dart';
import 'package:paisa_khai/screens/dashboard_screen.dart';
import 'package:paisa_khai/screens/settings_screen.dart';
import 'package:paisa_khai/screens/sources_screen.dart';
import 'package:paisa_khai/screens/transaction_history_screen.dart';
import 'package:paisa_khai/widgets/responsive_layout.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();

final GoRouter appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/',
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return ResponsiveLayout(navigationShell: navigationShell);
      },
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/',
              builder: (context, state) => const DashboardScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/categories',
              builder: (context, state) => const CategoriesScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/sources',
              builder: (context, state) => const SourcesScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/history',
              builder: (context, state) => const TransactionHistoryScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/settings',
              builder: (context, state) => const SettingsScreen(),
            ),
          ],
        ),
      ],
    ),
  ],
);
