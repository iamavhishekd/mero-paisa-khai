import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:paisa_khai/hive/hive_service.dart';
import 'package:paisa_khai/router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
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
    HiveService.settingsBoxInstance.put('theme_mode_index', mode.index);
  }
}

class ExpenseTrackerApp extends StatelessWidget {
  const ExpenseTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    const Color primaryBlack = Color(0xFF0C0D0F);
    const Color surfaceWhite = Color(0xFFF8F9FA);
    const Color accentGold = Color(0xFFE2C08D);

    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeManager.themeMode,
      builder: (context, currentMode, _) {
        return MaterialApp.router(
          routerConfig: appRouter,
          title: 'Paisa Khai',
          debugShowCheckedModeBanner: false,
          themeMode: currentMode,
          theme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.light,
            scaffoldBackgroundColor: surfaceWhite,
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.black,
              primary: Colors.black,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
            textTheme: GoogleFonts.soraTextTheme(ThemeData.light().textTheme)
                .copyWith(
                  displayLarge: GoogleFonts.sora(
                    fontSize: 34,
                    fontWeight: FontWeight.w900,
                    color: Colors.black,
                    letterSpacing: -1.5,
                  ),
                  titleLarge: GoogleFonts.sora(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Colors.black,
                    letterSpacing: -0.5,
                  ),
                ),
            appBarTheme: AppBarTheme(
              backgroundColor: Colors.transparent,
              elevation: 0,
              centerTitle: false,
              titleTextStyle: GoogleFonts.sora(
                color: Colors.black,
                fontSize: 26,
                fontWeight: FontWeight.w900,
                letterSpacing: -1,
              ),
            ),
            cardTheme: CardThemeData(
              color: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
                side: BorderSide(color: Colors.black.withValues(alpha: 0.05)),
              ),
            ),
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  vertical: 20,
                  horizontal: 28,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                textStyle: GoogleFonts.sora(fontWeight: FontWeight.w800),
              ),
            ),
          ),
          darkTheme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.dark,
            scaffoldBackgroundColor: primaryBlack,
            textTheme: GoogleFonts.soraTextTheme(ThemeData.dark().textTheme)
                .copyWith(
                  displayLarge: GoogleFonts.sora(
                    fontSize: 34,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: -1.5,
                  ),
                  titleLarge: GoogleFonts.sora(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: -0.5,
                  ),
                ),
            colorScheme: const ColorScheme.dark(
              primary: Colors.white,
              secondary: accentGold,
              surface: Color(0xFF16181D),
              surfaceContainerHighest: Color(0xFF23262D),
            ),
            appBarTheme: AppBarTheme(
              backgroundColor: Colors.transparent,
              elevation: 0,
              centerTitle: false,
              titleTextStyle: GoogleFonts.sora(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.w900,
                letterSpacing: -1,
              ),
            ),
            cardTheme: CardThemeData(
              color: const Color(0xFF16181D),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
                side: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
              ),
            ),
            floatingActionButtonTheme: FloatingActionButtonThemeData(
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 4,
            ),
            bottomNavigationBarTheme: const BottomNavigationBarThemeData(
              backgroundColor: primaryBlack,
              selectedItemColor: Colors.white,
              unselectedItemColor: Color(0xFF4B535D),
              type: BottomNavigationBarType.fixed,
              showSelectedLabels: true,
              showUnselectedLabels: false,
            ),
            inputDecorationTheme: InputDecorationTheme(
              filled: true,
              fillColor: const Color(0xFF16181D),
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
                borderSide: const BorderSide(color: Colors.white, width: 2),
              ),
              labelStyle: GoogleFonts.sora(
                color: Colors.white.withValues(alpha: 0.5),
              ),
              hintStyle: GoogleFonts.sora(
                color: Colors.white.withValues(alpha: 0.3),
              ),
            ),
          ),
        );
      },
    );
  }
}
