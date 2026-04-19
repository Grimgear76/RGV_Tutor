import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_state.dart';

class CustomSubjectProgressScreen extends StatelessWidget {
  const CustomSubjectProgressScreen({super.key, required this.categoryId});

  final String categoryId;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final category = state.personalCategories.where((c) => c.id == categoryId).firstOrNull;

    if (category == null) {
      return const Scaffold(body: SafeArea(child: Center(child: Text('Subject not found.'))));
    }

    final overall = state.combinedCompletionForPersonalCategory(categoryId);

    return Scaffold(
      appBar: AppBar(
        title: Text('${category.name} progress'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(18),
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Overall',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      value: overall,
                      minHeight: 10,
                      backgroundColor: Theme.of(context).colorScheme.surface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${(overall * 100).round()}% complete',
                    style: Theme.of(context)
                        .textTheme
                        .labelLarge
                        ?.copyWith(fontWeight: FontWeight.w700, color: Theme.of(context).colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            for (final section in category.sections) ...[
              _SectionProgressRow(
                title: section.name,
                value: state.combinedCompletionForPersonalSection(categoryId: category.id, sectionId: section.id),
                quizAnswered: state.quizStatsForSection(section.id).$1,
                quizCorrect: state.quizStatsForSection(section.id).$2,
                flashSeen: state.flashcardsSeenForSection(section.id),
                total: section.questions.length,
              ),
              const SizedBox(height: 12),
            ],
          ],
        ),
      ),
    );
  }
}

class _SectionProgressRow extends StatelessWidget {
  const _SectionProgressRow({
    required this.title,
    required this.value,
    required this.quizAnswered,
    required this.quizCorrect,
    required this.flashSeen,
    required this.total,
  });

  final String title;
  final double value;
  final int quizAnswered;
  final int quizCorrect;
  final int flashSeen;
  final int total;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final v = value.clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                ),
              ),
              Text(
                '${(v * 100).round()}%',
                style: Theme.of(context)
                    .textTheme
                    .labelLarge
                    ?.copyWith(fontWeight: FontWeight.w700, color: colorScheme.onSurfaceVariant),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: v,
              minHeight: 10,
              backgroundColor: colorScheme.surface,
              valueColor: AlwaysStoppedAnimation(colorScheme.tertiary),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Quiz: $quizCorrect/$quizAnswered correct',
            style: Theme.of(context)
                .textTheme
                .labelLarge
                ?.copyWith(fontWeight: FontWeight.w700, color: colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 4),
          Text(
            'Flashcards: $flashSeen/$total seen',
            style: Theme.of(context)
                .textTheme
                .labelLarge
                ?.copyWith(fontWeight: FontWeight.w700, color: colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}
