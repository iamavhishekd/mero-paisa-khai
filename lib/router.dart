import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:paisa_khai/hive/hive_service.dart';
import 'package:paisa_khai/models/transaction.dart';
import 'package:paisa_khai/screens/add_transaction_screen.dart';
import 'package:paisa_khai/screens/categories_screen.dart';
import 'package:paisa_khai/screens/dashboard_screen.dart';
import 'package:paisa_khai/screens/settings_screen.dart';
import 'package:paisa_khai/screens/sources_screen.dart';
import 'package:paisa_khai/screens/transaction_detail_screen.dart';
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
    GoRoute(
      path: '/add',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final editId = state.uri.queryParameters['editId'];
        Transaction? transactionToEdit;
        if (editId != null) {
          transactionToEdit = HiveService.transactionsBoxInstance.get(editId);
        }
        return AddTransactionScreen(transactionToEdit: transactionToEdit);
      },
    ),
    GoRoute(
      path: '/transaction/:id',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final id = state.pathParameters['id'];
        final transaction = HiveService.transactionsBoxInstance.get(id);

        if (transaction == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(child: Text('Transaction not found')),
          );
        }

        return TransactionDetailScreen(transaction: transaction);
      },
    ),
  ],
);
