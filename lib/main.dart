import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';

import 'app_state.dart';
import 'book_library_state.dart';
import 'data/problem_bank.dart';
import 'recommendation/recommender.dart';
import 'screens/home_screen.dart';
import 'app_navigator.dart';
import 'widgets/helper_bot.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();

  final problems = await const ProblemBank().load();
  final state = AppState(problems: problems, recommender: Recommender());
  await state.init();

  final books = BookLibraryState();
  await books.init();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: state),
        ChangeNotifierProvider.value(value: books),
      ],
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

    final textTheme = base.textTheme.copyWith(
      headlineSmall: base.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
      titleLarge: base.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
      titleMedium: base.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
    );

    return MaterialApp(
      navigatorKey: appNavigatorKey,
      debugShowCheckedModeBanner: false,
      title: 'RGV Tutor',
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
        cardTheme: CardTheme(
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        ),
      ),
      builder: (context, child) {
        final content = child ?? const SizedBox.shrink();
        return Stack(
          children: [
            content,
            const HelperBotLauncher(),
          ],
        );
      },
      home: const HomeScreen(),
    );
  }
}
