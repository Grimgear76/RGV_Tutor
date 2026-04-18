import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';

import 'app_state.dart';
import 'data/problem_bank.dart';
import 'recommendation/recommender.dart';
import 'screens/home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();

  final problems = await const ProblemBank().load();
  final state = AppState(problems: problems, recommender: const Recommender());
  await state.init();

  runApp(
    ChangeNotifierProvider.value(
      value: state,
      child: const App(),
    ),
  );
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF6D5EF6),
        brightness: Brightness.light,
      ).copyWith(
        primary: const Color(0xFF6D5EF6),
        secondary: const Color(0xFF2EC4B6),
        tertiary: const Color(0xFFFFB703),
        surface: const Color(0xFFF7F7FB),
      ),
    );

    final textTheme = GoogleFonts.plusJakartaSansTextTheme(base.textTheme).copyWith(
      headlineSmall: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w900),
      titleLarge: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w900),
      titleMedium: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800),
    );

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'RGV Math Coach',
      theme: base.copyWith(
        textTheme: textTheme,
        appBarTheme: AppBarTheme(
          centerTitle: false,
          titleTextStyle: textTheme.titleLarge?.copyWith(
            color: base.colorScheme.onSurface,
            fontWeight: FontWeight.w900,
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            textStyle: textTheme.titleMedium,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        ),
      ),
      home: const HomeScreen(),
    );
  }
}
