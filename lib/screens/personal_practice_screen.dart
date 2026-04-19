import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_state.dart';
import '../models/personal_bank.dart';
import '../widgets/quiz_card.dart';

class PersonalPracticeScreen extends StatefulWidget {
  const PersonalPracticeScreen({
    super.key,
    required this.categoryId,
    this.sectionId,
    this.sectionName,
    this.initialMode = PersonalPracticeMode.quiz,
  });

  final String categoryId;
  final String? sectionId;
  final String? sectionName;
  final PersonalPracticeMode initialMode;

  @override
  State<PersonalPracticeScreen> createState() => _PersonalPracticeScreenState();
}

class _PersonalPracticeScreenState extends State<PersonalPracticeScreen> {
  int _index = 0;
  int? _selected;
  bool? _correct;
  late PersonalPracticeMode _mode;
  bool _flipped = false;
  bool _showExplanation = false;
  int _quizAnswered = 0;
  int _quizCorrect = 0;

  @override
  void initState() {
    super.initState();
    _mode = widget.initialMode;
  }

  void _next(List<PersonalQuestion> questions) {
    if (questions.isEmpty) return;
    final last = _index >= questions.length - 1;
    if (last) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => PersonalPracticeFinishScreen(
            categoryId: widget.categoryId,
            sectionId: widget.sectionId,
            sectionName: widget.sectionName,
            mode: _mode,
            total: questions.length,
            quizAnswered: _quizAnswered,
            quizCorrect: _quizCorrect,
            flashcardsReviewed: _index + 1,
          ),
        ),
      );
      return;
    }

    setState(() {
      _index = (_index + 1).clamp(0, questions.length - 1);
      _selected = null;
      _correct = null;
      _flipped = false;
      _showExplanation = false;
    });
  }

  void _setMode(PersonalPracticeMode next) {
    if (_mode == next) return;
    setState(() {
      _mode = next;
      _selected = null;
      _correct = null;
      _flipped = false;
      _showExplanation = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final category = state.personalCategories.where((c) => c.id == widget.categoryId).firstOrNull;

    if (category == null) {
      return const Scaffold(body: SafeArea(child: Center(child: Text('Category not found.'))));
    }

    final questionRefs = widget.sectionId == null
        ? [
            for (final section in category.sections)
              for (final q in section.questions)
                (section.id, section.name, q),
          ]
        : [
            for (final section in category.sections.where((s) => s.id == widget.sectionId))
              for (final q in section.questions)
                (section.id, section.name, q),
          ];

    final questions = questionRefs.map((r) => r.$3).toList(growable: false);
    if (questions.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.sectionName == null ? category.name : '${category.name} • ${widget.sectionName}')),
        body: const SafeArea(child: Center(child: Text('No questions in this category yet.'))),
      );
    }

    final ref = questionRefs[_index.clamp(0, questionRefs.length - 1)];
    final sectionId = ref.$1;
    final question = ref.$3;
    final options = <String>{question.answer, ...question.incorrectAnswers}
        .where((row) => row.trim().isNotEmpty)
        .toList(growable: false);
    options.shuffle(Random(question.id.hashCode));
    final hasExplanation = question.explanation.trim().isNotEmpty;
    final correctIndex = options.indexWhere((row) => row.toLowerCase() == question.answer.toLowerCase());

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.sectionName == null ? category.name : '${category.name} • ${widget.sectionName}'),
      ),
      body: SafeArea(
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 90),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Question ${_index + 1} of ${questions.length}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final maxQuestionHeight = (constraints.maxHeight * 0.32).clamp(140.0, 240.0);
                        final answered = _correct != null;
                        final scheme = Theme.of(context).colorScheme;

                        return Column(
                          children: [
                        if (_mode == PersonalPracticeMode.quiz) ...[
                          QuizCard(text: question.question, maxHeight: maxQuestionHeight),
                          const SizedBox(height: 14),
                          Expanded(
                            child: options.length < 2
                                ? Center(
                                    child: FilledButton(
                                      onPressed: answered
                                          ? null
                                          : () {
                                              setState(() {
                                                _correct = true;
                                                _quizAnswered += 1;
                                                _quizCorrect += 1;
                                              });
                                              state.markPersonalQuestionSeen(question.id);
                                              state.markPersonalQuizAnswered(sectionId: sectionId, questionId: question.id, correct: true);
                                            },
                                      child: const Text('Reveal answer'),
                                    ),
                                  )
                                : ListView.separated(
                                    itemCount: options.length,
                                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                                    itemBuilder: (context, idx) {
                                      final option = options[idx];
                                      final isSelected = _selected == idx;
                                      final isCorrect = idx == correctIndex;

                                      Color? tileColor;
                                      Color? textColor;
                                      if (answered) {
                                        if (isCorrect) {
                                          tileColor = scheme.primaryContainer;
                                          textColor = scheme.onPrimaryContainer;
                                        } else if (isSelected) {
                                          tileColor = scheme.errorContainer;
                                          textColor = scheme.onErrorContainer;
                                        }
                                      } else if (isSelected) {
                                        tileColor = scheme.secondaryContainer;
                                        textColor = scheme.onSecondaryContainer;
                                      }

                                      final letter = String.fromCharCode('A'.codeUnitAt(0) + idx);

                                      return Material(
                                        color: tileColor ?? scheme.surfaceContainerHighest,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                                        clipBehavior: Clip.antiAlias,
                                        child: InkWell(
                                          onTap: answered
                                              ? null
                                              : () {
                                                  setState(() {
                                                    _selected = idx;
                                                  });
                                                },
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                                            child: Row(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Container(
                                                  width: 34,
                                                  height: 34,
                                                  decoration: BoxDecoration(
                                                    color: (textColor ?? scheme.onSurface).withOpacity(0.10),
                                                    borderRadius: BorderRadius.circular(12),
                                                  ),
                                                  child: Center(
                                                    child: Text(
                                                      letter,
                                                      style: Theme.of(context)
                                                          .textTheme
                                                          .labelLarge
                                                          ?.copyWith(fontWeight: FontWeight.w900, color: textColor),
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 12),
                                                Expanded(
                                                  child: Text(
                                                    option,
                                                    style: Theme.of(context)
                                                        .textTheme
                                                        .titleMedium
                                                        ?.copyWith(fontWeight: FontWeight.w800, color: textColor),
                                                  ),
                                                ),
                                                if (answered && isCorrect)
                                                  Icon(Icons.check_circle_rounded, color: textColor)
                                                else if (answered && isSelected && !isCorrect)
                                                  Icon(Icons.cancel_rounded, color: textColor),
                                              ],
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton(
                              onPressed: answered || options.length < 2
                                  ? null
                                  : () {
                                      if (_selected == null) return;
                                      setState(() {
                                        final isCorrect = _selected == correctIndex;
                                        _correct = isCorrect;
                                        _quizAnswered += 1;
                                        if (isCorrect) _quizCorrect += 1;
                                      });
                                      state.markPersonalQuestionSeen(question.id);
                                      state.markPersonalQuizAnswered(sectionId: sectionId, questionId: question.id, correct: _correct == true);
                                    },
                              child: const Text('Submit'),
                            ),
                          ),
                          if (answered) ...[
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
                        ] else ...[
                          Expanded(
                            child: Center(
                              child: AspectRatio(
                                aspectRatio: 4 / 3,
                                child: Material(
                                  elevation: 0,
                                  color: scheme.surfaceContainerHighest,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(22),
                                    side: BorderSide(color: scheme.outline.withOpacity(0.25)),
                                  ),
                                  clipBehavior: Clip.antiAlias,
                                  child: InkWell(
                                    onTap: () {
                                      setState(() {
                                        _flipped = !_flipped;
                                        if (!_flipped) _showExplanation = false;
                                      });
                                      if (!_flipped) return;
                                      state.markPersonalQuestionSeen(question.id);
                                      state.markPersonalFlashcardSeen(sectionId: sectionId, questionId: question.id);
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.all(18),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                                decoration: BoxDecoration(
                                                  color: scheme.secondaryContainer,
                                                  borderRadius: BorderRadius.circular(999),
                                                ),
                                                child: Text(
                                                  _flipped ? 'Back' : 'Front',
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .labelLarge
                                                      ?.copyWith(fontWeight: FontWeight.w800),
                                                ),
                                              ),
                                              const Spacer(),
                                              Icon(
                                                Icons.touch_app_rounded,
                                                color: scheme.onSurfaceVariant,
                                                size: 20,
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 14),
                                          Expanded(
                                            child: Center(
                                              child: Text(
                                                _flipped
                                                    ? (question.answer.trim().isEmpty
                                                        ? 'No answer saved'
                                                        : question.answer)
                                                    : question.question,
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .titleLarge
                                                    ?.copyWith(fontWeight: FontWeight.w900, height: 1.25),
                                                textAlign: TextAlign.center,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          if (_flipped && question.explanation.trim().isNotEmpty) ...[
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: FilledButton.tonal(
                                onPressed: () => setState(() => _showExplanation = !_showExplanation),
                                child: Text(_showExplanation ? 'Hide Explanation' : 'Show Explanation'),
                              ),
                            ),
                          ],
                          if (_flipped && _showExplanation && question.explanation.trim().isNotEmpty) ...[
                            const SizedBox(height: 12),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: scheme.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(18),
                              ),
                              child: Text(
                                question.explanation,
                                style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
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
            Align(
              alignment: Alignment.bottomCenter,
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 10, 18, 18),
                    child: Material(
                      color: Theme.of(context).colorScheme.surface,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                      child: Padding(
                        padding: const EdgeInsets.all(6),
                        child: Row(
                          children: [
                            Expanded(
                              child: SegmentedButton<PersonalPracticeMode>(
                                segments: const [
                                  ButtonSegment(
                                    value: PersonalPracticeMode.quiz,
                                    label: Text('Quiz'),
                                    icon: Icon(Icons.quiz_rounded),
                                  ),
                                  ButtonSegment(
                                    value: PersonalPracticeMode.flashcards,
                                    label: Text('Flashcards'),
                                    icon: Icon(Icons.style_rounded),
                                  ),
                                ],
                                selected: {_mode},
                                onSelectionChanged: (selection) {
                                  final next = selection.first;
                                  _setMode(next);
                                },
                              ),
                            ),
                            if (_mode == PersonalPracticeMode.flashcards)
                              IconButton(
                                tooltip: 'Show explanation',
                                onPressed: hasExplanation
                                    ? () {
                                        setState(() {
                                          _flipped = true;
                                          _showExplanation = true;
                                        });
                                        state.markPersonalQuestionSeen(question.id);
                                        state.markPersonalFlashcardSeen(sectionId: sectionId, questionId: question.id);
                                      }
                                    : null,
                                icon: const Icon(Icons.info_outline_rounded),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

enum PersonalPracticeMode {
  quiz,
  flashcards,
}

class PersonalPracticeFinishScreen extends StatelessWidget {
  const PersonalPracticeFinishScreen({
    super.key,
    required this.categoryId,
    required this.sectionId,
    required this.sectionName,
    required this.mode,
    required this.total,
    required this.quizAnswered,
    required this.quizCorrect,
    required this.flashcardsReviewed,
  });

  final String categoryId;
  final String? sectionId;
  final String? sectionName;
  final PersonalPracticeMode mode;
  final int total;
  final int quizAnswered;
  final int quizCorrect;
  final int flashcardsReviewed;

  @override
  Widget build(BuildContext context) {
    final nextMode = mode == PersonalPracticeMode.quiz ? PersonalPracticeMode.flashcards : PersonalPracticeMode.quiz;
    final nextLabel = mode == PersonalPracticeMode.quiz ? 'Switch to flashcards' : 'Switch to quiz';
    final subtitle = mode == PersonalPracticeMode.quiz
        ? 'Score: $quizCorrect/$quizAnswered correct'
        : 'Reviewed: $flashcardsReviewed/$total cards';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Finished'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Nice work!',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                style: Theme.of(context)
                    .textTheme
                    .bodyLarge
                    ?.copyWith(fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (_) => PersonalPracticeScreen(
                          categoryId: categoryId,
                          sectionId: sectionId,
                          sectionName: sectionName,
                          initialMode: mode,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Restart'),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton.tonal(
                  onPressed: () {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (_) => PersonalPracticeScreen(
                          categoryId: categoryId,
                          sectionId: sectionId,
                          sectionName: sectionName,
                          initialMode: nextMode,
                        ),
                      ),
                    );
                  },
                  child: Text(nextLabel),
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
                  icon: const Icon(Icons.home_rounded),
                  label: const Text('Return to subjects'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
