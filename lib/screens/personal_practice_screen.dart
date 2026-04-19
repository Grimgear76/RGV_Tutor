import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_state.dart';
import '../models/personal_bank.dart';
import '../widgets/quiz_card.dart';

class PersonalPracticeScreen extends StatefulWidget {
  const PersonalPracticeScreen({super.key, required this.categoryId});

  final String categoryId;

  @override
  State<PersonalPracticeScreen> createState() => _PersonalPracticeScreenState();
}

class _PersonalPracticeScreenState extends State<PersonalPracticeScreen> {
  int _index = 0;
  int? _selected;
  bool? _correct;

  void _next(List<PersonalQuestion> questions) {
    if (questions.isEmpty) return;
    setState(() {
      _index = (_index + 1) % questions.length;
      _selected = null;
      _correct = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final category = state.personalCategories.where((c) => c.id == widget.categoryId).firstOrNull;

    if (category == null) {
      return const Scaffold(body: SafeArea(child: Center(child: Text('Category not found.'))));
    }

    final questions = category.questions;
    if (questions.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(category.name)),
        body: const SafeArea(child: Center(child: Text('No questions in this category yet.'))),
      );
    }

    final question = questions[_index.clamp(0, questions.length - 1)];
    final options = <String>{question.answer, ...question.incorrectAnswers}
        .where((row) => row.trim().isNotEmpty)
        .toList(growable: false);
    options.shuffle(Random(question.id.hashCode));
    final correctIndex = options.indexWhere((row) => row.toLowerCase() == question.answer.toLowerCase());

    return Scaffold(
      appBar: AppBar(
        title: Text(category.name),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Question ${_index + 1} / ${questions.length}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
                    ),
                  ),
                  if (_correct != null)
                    Icon(
                      _correct == true ? Icons.check_circle_rounded : Icons.cancel_rounded,
                      color: _correct == true
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.error,
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final maxQuestionHeight = (constraints.maxHeight * 0.32).clamp(140.0, 240.0);

                    return Column(
                      children: [
                        QuizCard(text: question.question, maxHeight: maxQuestionHeight),
                        const SizedBox(height: 14),
                        Expanded(
                          child: options.length < 2
                              ? Center(
                                  child: FilledButton(
                                    onPressed: _correct != null
                                        ? null
                                        : () {
                                            setState(() {
                                              _correct = true;
                                            });
                                          },
                                    child: const Text('Show answer'),
                                  ),
                                )
                              : ListView.separated(
                                  itemCount: options.length,
                                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                                  itemBuilder: (context, idx) {
                                    final option = options[idx];
                                    final selected = _selected == idx;
                                    final answered = _correct != null;
                                    final isCorrect = idx == correctIndex;
                                    final scheme = Theme.of(context).colorScheme;

                                    Color? background;
                                    Color? foreground;
                                    if (answered) {
                                      if (isCorrect) {
                                        background = scheme.primaryContainer;
                                        foreground = scheme.onPrimaryContainer;
                                      } else if (selected) {
                                        background = scheme.errorContainer;
                                        foreground = scheme.onErrorContainer;
                                      }
                                    }

                                    return FilledButton(
                                      style: FilledButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                                        backgroundColor: background,
                                        foregroundColor: foreground,
                                      ),
                                      onPressed: answered
                                          ? null
                                          : () {
                                              setState(() {
                                                _selected = idx;
                                                _correct = idx == correctIndex;
                                              });
                                            },
                                      child: Align(
                                        alignment: Alignment.centerLeft,
                                        child: Text(
                                          option,
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleMedium
                                              ?.copyWith(fontWeight: FontWeight.w800),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                        ),
                        if (_correct != null) ...[
                          const SizedBox(height: 12),
                          if (question.explanation.trim().isNotEmpty || options.length < 2)
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(18),
                              ),
                              child: Text(
                                [
                                  if (options.length < 2) 'Answer: ${question.answer}',
                                  if (question.explanation.trim().isNotEmpty) question.explanation,
                                ].join('\n\n'),
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyLarge
                                    ?.copyWith(fontWeight: FontWeight.w600),
                              ),
                            ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton.icon(
                              onPressed: () => _next(questions),
                              icon: const Icon(Icons.arrow_forward_rounded),
                              label: const Text('Next'),
                            ),
                          ),
                        ],
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
