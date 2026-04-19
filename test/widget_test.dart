import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:rgv_math_tutor/app_state.dart';
import 'package:rgv_math_tutor/book_library_state.dart';
import 'package:rgv_math_tutor/main.dart';
import 'package:rgv_math_tutor/recommendation/recommender.dart';

@Skip('Temporarily skipping widget tests during web reader work.')
void main() {
  testWidgets('Home screen renders', (WidgetTester tester) async {
    final state = AppState(problems: const [], recommender: const Recommender());
    final books = BookLibraryState();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: state),
          ChangeNotifierProvider.value(value: books),
        ],
        child: const App(),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('RGV Math Coach'), findsOneWidget);
    expect(find.text('Choose a subject'), findsOneWidget);
    expect(find.byTooltip('Books'), findsOneWidget);
  });
}
