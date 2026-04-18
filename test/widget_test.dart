import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:rgv_math_tutor/app_state.dart';
import 'package:rgv_math_tutor/main.dart';
import 'package:rgv_math_tutor/recommendation/recommender.dart';

void main() {
  testWidgets('Home screen renders', (WidgetTester tester) async {
    final state = AppState(problems: const [], recommender: const Recommender());

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: state,
        child: const App(),
      ),
    );

    expect(find.text('RGV Math Coach'), findsOneWidget);
    expect(find.text('Continue math'), findsOneWidget);
    expect(find.byIcon(Icons.insights_rounded), findsOneWidget);
    expect(find.text('Personal\nQuestions'), findsOneWidget);
  });
}
