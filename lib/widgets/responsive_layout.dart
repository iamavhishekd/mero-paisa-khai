import 'package:flutter/material.dart';
import 'package:paisa_khai/screens/categories_screen.dart';
import 'package:paisa_khai/screens/dashboard_screen.dart';
import 'package:paisa_khai/screens/settings_screen.dart';
import 'package:paisa_khai/screens/sources_screen.dart';
import 'package:paisa_khai/screens/transaction_history_screen.dart';

class ResponsiveLayout extends StatefulWidget {
  const ResponsiveLayout({super.key});

  @override
  State<ResponsiveLayout> createState() => _ResponsiveLayoutState();
}

class _ResponsiveLayoutState extends State<ResponsiveLayout> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const DashboardScreen(),
    const CategoriesScreen(),
    const SourcesScreen(),
    const TransactionHistoryScreen(),
    const SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth > 900) {
          return Scaffold(
            body: Row(
              children: [
                _buildNavigationRail(),
                const VerticalDivider(thickness: 1, width: 1),
                Expanded(
                  child: _screens[_selectedIndex],
                ),
              ],
            ),
          );
        }

        return Scaffold(
          body: _screens[_selectedIndex],
          bottomNavigationBar: _buildBottomNavigationBar(),
        );
      },
    );
  }

  Widget _buildNavigationRail() {
    final theme = Theme.of(context);

    return Container(
      width: 280,
      color: theme.scaffoldBackgroundColor,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'PAISA KHAI',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w900,
                letterSpacing: -0.5,
                fontSize: 24,
              ),
            ),
          ),
          const SizedBox(height: 60),
          _buildSidebarItem(
            index: 0,
            icon: Icons.grid_view_outlined,
            selectedIcon: Icons.grid_view_rounded,
            label: 'DASHBOARD',
          ),
          const SizedBox(height: 8),
          _buildSidebarItem(
            index: 1,
            icon: Icons.local_offer_outlined,
            selectedIcon: Icons.local_offer_rounded,
            label: 'TAGS',
          ),
          const SizedBox(height: 8),
          _buildSidebarItem(
            index: 2,
            icon: Icons.account_balance_wallet_outlined,
            selectedIcon: Icons.account_balance_wallet_rounded,
            label: 'SOURCES',
          ),
          const SizedBox(height: 8),
          _buildSidebarItem(
            index: 3,
            icon: Icons.update_outlined,
            selectedIcon: Icons.update_rounded,
            label: 'HISTORY',
          ),
          const SizedBox(height: 8),
          _buildSidebarItem(
            index: 4,
            icon: Icons.settings_outlined,
            selectedIcon: Icons.settings_rounded,
            label: 'SETTINGS',
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarItem({
    required int index,
    required IconData icon,
    required IconData selectedIcon,
    required String label,
  }) {
    final isSelected = _selectedIndex == index;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return InkWell(
      onTap: () => setState(() => _selectedIndex = index),
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark
                    ? Colors.white.withValues(alpha: 0.05)
                    : Colors.black.withValues(alpha: 0.05))
              : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? selectedIcon : icon,
              size: 20,
              color: isSelected
                  ? theme.colorScheme.onSurface
                  : theme.colorScheme.onSurface.withValues(alpha: 0.4),
            ),
            const SizedBox(width: 16),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700,
                letterSpacing: 1,
                color: isSelected
                    ? theme.colorScheme.onSurface
                    : theme.colorScheme.onSurface.withValues(alpha: 0.4),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavigationBar() {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        border: Border(
          top: BorderSide(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.05),
          ),
        ),
      ),
      child: BottomNavigationBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        currentIndex: _selectedIndex,
        selectedItemColor: theme.colorScheme.onSurface,
        unselectedItemColor: theme.colorScheme.onSurface.withValues(alpha: 0.2),
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w900,
          fontSize: 10,
          letterSpacing: 0.5,
        ),
        unselectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 10,
          letterSpacing: 0.5,
        ),
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Padding(
              padding: EdgeInsets.only(bottom: 4),
              child: Icon(Icons.grid_view_outlined, size: 20),
            ),
            activeIcon: Padding(
              padding: EdgeInsets.only(bottom: 4),
              child: Icon(Icons.grid_view_rounded, size: 20),
            ),
            label: 'HOME',
          ),
          BottomNavigationBarItem(
            icon: Padding(
              padding: EdgeInsets.only(bottom: 4),
              child: Icon(Icons.local_offer_outlined, size: 20),
            ),
            activeIcon: Padding(
              padding: EdgeInsets.only(bottom: 4),
              child: Icon(Icons.local_offer_rounded, size: 20),
            ),
            label: 'TAGS',
          ),
          BottomNavigationBarItem(
            icon: Padding(
              padding: EdgeInsets.only(bottom: 4),
              child: Icon(Icons.account_balance_wallet_outlined, size: 20),
            ),
            activeIcon: Padding(
              padding: EdgeInsets.only(bottom: 4),
              child: Icon(Icons.account_balance_wallet_rounded, size: 20),
            ),
            label: 'SOURCES',
          ),
          BottomNavigationBarItem(
            icon: Padding(
              padding: EdgeInsets.only(bottom: 4),
              child: Icon(Icons.update_outlined, size: 20),
            ),
            activeIcon: Padding(
              padding: EdgeInsets.only(bottom: 4),
              child: Icon(Icons.update_rounded, size: 20),
            ),
            label: 'HISTORY',
          ),
          BottomNavigationBarItem(
            icon: Padding(
              padding: EdgeInsets.only(bottom: 4),
              child: Icon(Icons.settings_outlined, size: 20),
            ),
            activeIcon: Padding(
              padding: EdgeInsets.only(bottom: 4),
              child: Icon(Icons.settings_rounded, size: 20),
            ),
            label: 'SETTINGS',
          ),
        ],
      ),
    );
  }
}
