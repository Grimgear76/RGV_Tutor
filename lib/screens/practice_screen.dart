import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_state.dart';
import '../models/subject.dart';
import '../widgets/feedback_burst.dart';
import '../widgets/quiz_card.dart';
import '../widgets/xp_bar.dart';

class PracticeScreen extends StatefulWidget {
  const PracticeScreen({super.key});

  @override
  State<PracticeScreen> createState() => _PracticeScreenState();
}

class _PracticeScreenState extends State<PracticeScreen> with SingleTickerProviderStateMixin {
  int? _selected;
  bool _showSteps = false;
  Timer? _autoNext;

  late final AnimationController _shake;
  late final Animation<double> _shakeAnim;

  @override
  void initState() {
    super.initState();
    _shake = AnimationController(vsync: this, duration: const Duration(milliseconds: 420));
    _shakeAnim = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0, end: -10), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -10, end: 10), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 10, end: -8), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -8, end: 8), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 8, end: 0), weight: 1),
    ]).animate(CurvedAnimation(parent: _shake, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _autoNext?.cancel();
    _shake.dispose();
    super.dispose();
  }

  void _onChoiceTap(AppState state, int idx) {
    if (state.lastCorrect != null) return;

    setState(() {
      _selected = idx;
      _showSteps = false;
    });

    state.answer(idx);

    if (state.lastCorrect == false) {
      _shake.forward(from: 0);
    }

    _autoNext?.cancel();
  }

  bool _looksLikeMath(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return false;

    final hasMathSymbols = RegExp(r'[=+\-*/^()\[\]{}<>√×÷]').hasMatch(trimmed);
    final hasDigit = RegExp(r'\d').hasMatch(trimmed);
    final hasWord = RegExp(r'[A-Za-z]{2,}').hasMatch(trimmed);
    final isSingleLetterVariable = RegExp(r'^[A-Za-z]$').hasMatch(trimmed);

    return hasMathSymbols || (hasDigit && (!hasWord || isSingleLetterVariable));
  }

  TextStyle _problemTextStyle(BuildContext context, String text) {
    final base = Theme.of(context).textTheme.bodyLarge ?? const TextStyle(fontSize: 16);
    if (_looksLikeMath(text)) {
      return (Theme.of(context).textTheme.titleLarge ?? base).copyWith(height: 1.1);
    }
    return base.copyWith(height: 1.15);
  }

  TextStyle _fitSingleLine(
    BuildContext context, {
    required String text,
    required TextStyle style,
    required double maxWidth,
    double minFontSize = 12,
  }) {
    final textDirection = Directionality.of(context);

    var fontSize = (style.fontSize ?? 16).toDouble();
    if (fontSize < minFontSize) fontSize = minFontSize;

    for (var size = fontSize; size >= minFontSize; size -= 1) {
      final candidate = style.copyWith(fontSize: size);
      final painter = TextPainter(
        text: TextSpan(text: text, style: candidate),
        maxLines: 1,
        textDirection: textDirection,
      )..layout(maxWidth: maxWidth);

      if (!painter.didExceedMaxLines && painter.width <= maxWidth) {
        return candidate;
      }
    }

    return style.copyWith(fontSize: minFontSize);
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final problem = state.current;
    final isHistory = state.subject == Subject.history;
    final usesExplanation = isHistory || state.subject == Subject.reading || state.subject == Subject.science;

    if (problem == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final correct = state.lastCorrect == true;
    final answered = state.lastCorrect != null;
    final questionsLeft = state.questionsLeftInDifficulty;
    final difficultyProgress = state.difficultyProgress;
    final displayDifficulty = state.practiceDifficulty ?? problem.difficulty;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Practice'),
      ),
      body: SafeArea(
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(18),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final maxQuestionHeight = (constraints.maxHeight * 0.30).clamp(140.0, 240.0);

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      XpBar(value: state.levelProgress, level: state.level),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              problem.skill,
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w800,
                                  ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(999),
                              color: Theme.of(context).colorScheme.secondaryContainer,
                            ),
                            child: Text(
                              'Difficulty $displayDifficulty',
                              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                    fontWeight: FontWeight.w800,
                                  ),
                            ),
                          ),
                        ],
                      ),
                      if (difficultyProgress != null && questionsLeft != null) ...[
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(999),
                                child: LinearProgressIndicator(
                                  value: difficultyProgress,
                                  minHeight: 10,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              '$questionsLeft left',
                              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                    fontWeight: FontWeight.w800,
                                  ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 14),
                      AnimatedBuilder(
                        animation: _shakeAnim,
                        builder: (context, child) {
                          return Transform.translate(
                            offset: Offset(_shakeAnim.value, 0),
                            child: child,
                          );
                        },
                        child: Container(
                          width: double.infinity,
                          constraints: BoxConstraints(maxHeight: maxQuestionHeight),
                          child: QuizCard(text: problem.question, maxHeight: maxQuestionHeight),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Expanded(
                        child: ListView.separated(
                          itemCount: problem.choices.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder: (context, idx) {
                            final selected = _selected == idx;
                            final isCorrectChoice = idx == problem.answerIndex;
                            final showCorrect = answered && isCorrectChoice;
                            final showWrong = answered && selected && !isCorrectChoice;

                            Color? bg;
                            Color? fg;
                            if (showCorrect) {
                              bg = Theme.of(context).colorScheme.primaryContainer;
                              fg = Theme.of(context).colorScheme.onPrimaryContainer;
                            } else if (showWrong) {
                              bg = Theme.of(context).colorScheme.errorContainer;
                              fg = Theme.of(context).colorScheme.onErrorContainer;
                            } else if (selected) {
                              bg = Theme.of(context).colorScheme.secondaryContainer;
                              fg = Theme.of(context).colorScheme.onSecondaryContainer;
                            }

                            final choice = problem.choices[idx];
                            final choiceStyle = _problemTextStyle(context, choice);

                            return InkWell(
                              borderRadius: BorderRadius.circular(18),
                              onTap: () => _onChoiceTap(state, idx),
                              child: Ink(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: bg ?? Theme.of(context).colorScheme.surfaceContainerHighest,
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(
                                    color: selected
                                        ? Theme.of(context).colorScheme.primary.withOpacity(0.4)
                                        : Colors.transparent,
                                  ),
                                ),
                                 child: Row(
                                   children: [
                                     Expanded(
                                       child: LayoutBuilder(
                                         builder: (context, box) {
                                           if (_looksLikeMath(choice)) {
                                             final fitted = _fitSingleLine(
                                               context,
                                               text: choice,
                                               style: choiceStyle.copyWith(
                                                 fontWeight: FontWeight.w800,
                                                 color: fg,
                                               ),
                                               maxWidth: box.maxWidth,
                                               minFontSize: 14,
                                             );

                                             return SingleChildScrollView(
                                               scrollDirection: Axis.horizontal,
                                               child: ConstrainedBox(
                                                 constraints: BoxConstraints(minWidth: box.maxWidth),
                                                 child: Text(
                                                   choice,
                                                   maxLines: 1,
                                                   softWrap: false,
                                                   style: fitted,
                                                 ),
                                               ),
                                             );
                                           }

                                           return Text(
                                             choice,
                                             maxLines: 2,
                                             overflow: TextOverflow.ellipsis,
                                             style: choiceStyle.copyWith(
                                               fontWeight: FontWeight.w800,
                                               color: fg,
                                             ),
                                           );
                                         },
                                       ),
                                     ),
                                     if (showCorrect)
                                       Icon(Icons.check_circle, color: fg)
                                     else if (showWrong)
                                       Icon(Icons.cancel, color: fg)
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: FilledButton.tonal(
                              onPressed: answered ? () => setState(() => _showSteps = !_showSteps) : null,
                              child: Text(
                                _showSteps
                                    ? (usesExplanation ? 'Hide Explanation' : 'Hide steps')
                                    : (usesExplanation ? 'Show Explanation' : 'Show steps'),
                              ),
                            ),
                          ),
                          if (answered && !correct) ...[
                            const SizedBox(width: 12),
                            FilledButton.tonal(
                              onPressed: () {
                                _autoNext?.cancel();
                                setState(() {
                                  _selected = null;
                                  _showSteps = false;
                                });
                                state.retry();
                              },
                              child: const Text('Retry'),
                            ),
                          ],
                          const SizedBox(width: 12),
                          FilledButton(
                            onPressed: answered
                                ? () {
                                    setState(() {
                                      _selected = null;
                                      _showSteps = false;
                                    });
                                    state.next();
                                  }
                                : null,
                            child: const Text('Next'),
                          ),
                        ],
                      ),
                      if (_showSteps) ...[
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                usesExplanation ? 'Explanation' : 'Steps',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.w900,
                                    ),
                              ),
                              const SizedBox(height: 8),
                              for (final s in problem.steps)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 6),
                                  child: Text(
                                    usesExplanation ? s : '• $s',
                                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                          fontWeight: FontWeight.w600,
                                          height: 1.25,
                                        ),
                                  ),
                                )
                            ],
                          ),
                        ),
                      ]
                    ],
                  );
                },
              ),
            ),
            FeedbackBurst(
              correct: correct,
              visible: answered,
            ),
          ],
        ),
      ),
    );
  }
}
