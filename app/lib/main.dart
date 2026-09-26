import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'screens/login_screen.dart';
import 'screens/main_screen.dart';
import 'theme/theme_manager.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ThemeManager.loadTheme();
  runApp(const NrApp());
}

class NrApp extends StatelessWidget {
  const NrApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeManager.themeMode,
      builder: (context, themeMode, child) {
        return ValueListenableBuilder<MaterialColor>(
          valueListenable: ThemeManager.primarySwatch,
          builder: (context, swatch, child) {
            return MaterialApp(
              title: 'NR',
              debugShowCheckedModeBanner: false,
              theme: ThemeData(
                primarySwatch: swatch,
                textTheme: GoogleFonts.poppinsTextTheme(
                  ThemeData.light().textTheme,
                ),
                useMaterial3: true,
                colorScheme: ColorScheme.fromSeed(
                  seedColor: swatch,
                  brightness: Brightness.light,
                ),
                scaffoldBackgroundColor: ColorScheme.fromSeed(
                  seedColor: swatch,
                  brightness: Brightness.light,
                ).surface,
                appBarTheme: AppBarTheme(
                  backgroundColor: swatch,
                  foregroundColor: Colors.white,
                  elevation: 0,
                ),
                inputDecorationTheme: InputDecorationTheme(
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                elevatedButtonTheme: ElevatedButtonThemeData(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: swatch,
                    foregroundColor: Colors.white,
                    textStyle: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.2,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                floatingActionButtonTheme: FloatingActionButtonThemeData(
                  backgroundColor: swatch,
                  foregroundColor: Colors.white,
                ),
                bottomNavigationBarTheme: BottomNavigationBarThemeData(
                  selectedItemColor: swatch,
                  unselectedItemColor: Colors.grey[600],
                  backgroundColor: Colors.white,
                ),
                cardTheme: const CardThemeData(
                  color: Colors.white,
                  elevation: 2,
                  margin: EdgeInsets.zero,
                ),
              ),
              darkTheme: ThemeData(
                brightness: Brightness.dark,
                primarySwatch: swatch,
                textTheme: GoogleFonts.poppinsTextTheme(
                  ThemeData.dark().textTheme,
                ),
                useMaterial3: true,
                colorScheme: ColorScheme.fromSeed(
                  seedColor: swatch,
                  brightness: Brightness.dark,
                ),
                scaffoldBackgroundColor: ColorScheme.fromSeed(
                  seedColor: swatch,
                  brightness: Brightness.dark,
                ).surface,
                appBarTheme: AppBarTheme(
                  backgroundColor: swatch.shade800,
                  foregroundColor: Colors.white,
                  elevation: 0,
                ),
                inputDecorationTheme: InputDecorationTheme(
                  filled: true,
                  fillColor: const Color(0xFF1F2937),
                  labelStyle: TextStyle(color: Colors.grey),
                  hintStyle: TextStyle(color: Colors.grey),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                elevatedButtonTheme: ElevatedButtonThemeData(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: swatch,
                    foregroundColor: Colors.white,
                    textStyle: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.2,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                floatingActionButtonTheme: FloatingActionButtonThemeData(
                  backgroundColor: swatch,
                  foregroundColor: Colors.white,
                ),
                bottomNavigationBarTheme: BottomNavigationBarThemeData(
                  selectedItemColor: swatch,
                  unselectedItemColor: Colors.grey[400],
                  backgroundColor: const Color(0xFF111827),
                ),
                cardTheme: const CardThemeData(
                  color: Color(0xFF111827),
                  elevation: 2,
                  margin: EdgeInsets.zero,
                ),
              ),
              themeMode: themeMode,
              localizationsDelegates: GlobalMaterialLocalizations.delegates,
              supportedLocales: const [Locale('pt', 'BR')],
              initialRoute: '/login',
              routes: {
                '/login': (context) => LoginScreen(),
                '/home': (context) => const MainScreen(),
              },
            );
          },
        );
      },
    );
  }
}
