import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:paisa_khai/hive/hive_service.dart';
import 'package:paisa_khai/router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  usePathUrlStrategy();
  await HiveService.init();
  ThemeManager.init();
  runApp(const ExpenseTrackerApp());
}

class ThemeManager {
  static final ValueNotifier<ThemeMode> themeMode = ValueNotifier(
    ThemeMode.system,
  );

  static void init() {
    final box = HiveService.settingsBoxInstance;
    final savedIndex = box.get('theme_mode_index', defaultValue: 0) as int;
    themeMode.value = ThemeMode.values[savedIndex];
  }

  static void setThemeMode(ThemeMode mode) {
    themeMode.value = mode;
    unawaited(
      HiveService.settingsBoxInstance.put('theme_mode_index', mode.index),
    );
  }
}

class ExpenseTrackerApp extends StatelessWidget {
  const ExpenseTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    const Color primaryBlack = Color(0xFF0C0D0F);
    const Color surfaceWhite = Color(0xFFF8F9FA);

    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeManager.themeMode,
      builder: (context, currentMode, _) {
        return MaterialApp.router(
          routerConfig: appRouter,
          title: 'paisa khai',
          debugShowCheckedModeBanner: false,
          themeMode: currentMode,
          // Light Theme
          theme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.light,
            colorScheme: ColorScheme.fromSeed(
              seedColor: primaryBlack,
              primary: primaryBlack,
              secondary: surfaceWhite,
              surface: surfaceWhite,
            ),
            scaffoldBackgroundColor: surfaceWhite,
            textTheme: GoogleFonts.outfitTextTheme(ThemeData.light().textTheme)
                .copyWith(
                  displayLarge: GoogleFonts.outfit(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    color: primaryBlack,
                  ),
                  bodyLarge: GoogleFonts.outfit(
                    fontSize: 16,
                    color: primaryBlack.withValues(alpha: 0.8),
                  ),
                ),
            appBarTheme: const AppBarTheme(
              backgroundColor: Colors.transparent,
              elevation: 0,
              centerTitle: false,
              titleTextStyle: TextStyle(
                color: primaryBlack,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            cardTheme: CardThemeData(
              color: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(color: Colors.grey.withValues(alpha: 0.1)),
              ),
            ),
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryBlack,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                textStyle: GoogleFonts.outfit(fontWeight: FontWeight.w700),
              ),
            ),
          ),
          // Dark Theme
          darkTheme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.dark,
            colorScheme: ColorScheme.fromSeed(
              seedColor: surfaceWhite,
              brightness: Brightness.dark,
              primary: surfaceWhite,
              onPrimary: primaryBlack,
              secondary: surfaceWhite,
              surface: primaryBlack,
              onSurface: Colors.white,
              surfaceContainerLowest: const Color(0xFF16181D),
            ),
            scaffoldBackgroundColor: primaryBlack,
            textTheme: GoogleFonts.outfitTextTheme(ThemeData.dark().textTheme)
                .copyWith(
                  displayLarge: GoogleFonts.outfit(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                  bodyLarge: GoogleFonts.outfit(
                    fontSize: 16,
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                ),
            appBarTheme: const AppBarTheme(
              backgroundColor: Colors.transparent,
              elevation: 0,
              centerTitle: false,
              titleTextStyle: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            cardTheme: CardThemeData(
              color: const Color(0xFF1C1F26),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
              ),
            ),
            floatingActionButtonTheme: const FloatingActionButtonThemeData(
              backgroundColor: Color(0xFFE2C08D),
              foregroundColor: Color(0xFF0C0D0F),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(16)),
              ),
            ),
            bottomNavigationBarTheme: const BottomNavigationBarThemeData(
              backgroundColor: Color(0xFF16181D),
              selectedItemColor: Color(0xFFE2C08D),
              unselectedItemColor: Colors.white54,
              type: BottomNavigationBarType.fixed,
              elevation: 0,
            ),
            inputDecorationTheme: InputDecorationTheme(
              filled: true,
              fillColor: const Color(0xFF1C1F26),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 16,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: Colors.white.withValues(alpha: 0.1),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: Colors.white.withValues(alpha: 0.1),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(
                  color: Color(0xFFE2C08D),
                  width: 2,
                ),
              ),
              hintStyle: GoogleFonts.outfit(color: Colors.white38),
            ),
          ),
        );
      },
    );
  }
}
