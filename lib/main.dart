import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:paisa_khai/blocs/category/category_bloc.dart';
import 'package:paisa_khai/blocs/settings/settings_bloc.dart';
import 'package:paisa_khai/blocs/source/source_bloc.dart';
import 'package:paisa_khai/blocs/transaction/transaction_bloc.dart';
import 'package:paisa_khai/hive/hive_service.dart';
import 'package:paisa_khai/router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  usePathUrlStrategy();
  await HiveService.init();
  runApp(
    MultiBlocProvider(
      providers: [
        BlocProvider(create: (context) => CategoryBloc()),
        BlocProvider(create: (context) => SourceBloc()),
        BlocProvider(create: (context) => TransactionBloc()),
        BlocProvider(create: (context) => SettingsBloc()),
      ],
      child: const ExpenseTrackerApp(),
    ),
  );
}

class ExpenseTrackerApp extends StatelessWidget {
  const ExpenseTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    const Color primaryBlack = Color(0xFF0C0D0F);
    const Color surfaceWhite = Color(0xFFF8F9FA);

    return BlocBuilder<SettingsBloc, SettingsState>(
      builder: (context, state) {
        return MaterialApp.router(
          routerConfig: appRouter,
          title: 'paisa khai',
          debugShowCheckedModeBanner: false,
          themeMode: state.themeMode,
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
                    textStyle: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      color: primaryBlack,
                    ),
                  ),
                  bodyLarge: GoogleFonts.outfit(
                    textStyle: TextStyle(
                      fontSize: 16,
                      color: primaryBlack.withValues(alpha: 0.8),
                    ),
                  ),
                  labelLarge: GoogleFonts.outfit(
                    textStyle: const TextStyle(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            appBarTheme: AppBarTheme(
              backgroundColor: Colors.transparent,
              elevation: 0,
              centerTitle: false,
              titleTextStyle: GoogleFonts.outfit(
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
                textStyle: GoogleFonts.outfit(
                  textStyle: const TextStyle(
                    fontWeight: FontWeight.w700,
                  ),
                ),
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
                    textStyle: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                  bodyLarge: GoogleFonts.outfit(
                    textStyle: TextStyle(
                      fontSize: 16,
                      color: Colors.white.withValues(alpha: 0.7),
                    ),
                  ),
                  labelLarge: GoogleFonts.outfit(
                    textStyle: const TextStyle(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            appBarTheme: AppBarTheme(
              backgroundColor: Colors.transparent,
              elevation: 0,
              centerTitle: false,
              titleTextStyle: GoogleFonts.outfit(
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
              hintStyle: GoogleFonts.outfit(
                textStyle: const TextStyle(
                  color: Colors.white38,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
