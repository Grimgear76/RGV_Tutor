import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_state.dart';
import '../widgets/feedback_burst.dart';
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
    _autoNext = Timer(const Duration(milliseconds: 900), () {
      if (!mounted) return;
      if (state.lastCorrect == true) {
        setState(() {
          _selected = null;
          _showSteps = false;
        });
        state.next();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final problem = state.current;

    if (problem == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final correct = state.lastCorrect == true;
    final answered = state.lastCorrect != null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Practice'),
      ),
      body: SafeArea(
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
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
                          'Difficulty ${problem.difficulty}',
                          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                      ),
                    ],
                  ),
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
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: Text(
                        problem.question,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w900,
                            ),
                      ),
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
                                  child: Text(
                                    problem.choices[idx],
                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                          fontWeight: FontWeight.w800,
                                          color: fg,
                                        ),
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
                          child: Text(_showSteps ? 'Hide steps' : 'Show steps'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      FilledButton(
                        onPressed: answered ? () {
                          setState(() {
                            _selected = null;
                            _showSteps = false;
                          });
                          state.next();
                        } : null,
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
                            'Steps',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w900,
                                ),
                          ),
                          const SizedBox(height: 8),
                          for (final s in problem.steps)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 6),
                              child: Text(
                                '• $s',
                                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                            )
                        ],
                      ),
                    ),
                  ]
                ],
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
