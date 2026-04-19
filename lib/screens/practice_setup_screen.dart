import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_state.dart';
import '../models/subject.dart';
import 'practice_screen.dart';

class PracticeSetupScreen extends StatefulWidget {
  const PracticeSetupScreen({super.key});

  @override
  State<PracticeSetupScreen> createState() => _PracticeSetupScreenState();
}

class _PracticeSetupScreenState extends State<PracticeSetupScreen> {
  String? _selectedSkill;
  int _selectedDifficulty = 1;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final skills = state.skills;

    return Scaffold(
      appBar: AppBar(
        title: Text('${state.subject.label} setup'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Choose a category and difficulty',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ScrollConfiguration(
                  behavior: const _NoIndicatorScrollBehavior(),
                  child: ClipRect(
                    child: ListView.separated(
                      padding: EdgeInsets.zero,
                      physics: const ClampingScrollPhysics(),
                      clipBehavior: Clip.hardEdge,
                      itemCount: skills.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final skill = skills[index];
                        final selected = skill == _selectedSkill;

                        return _CategoryRow(
                          label: skill,
                          selected: selected,
                          difficulty: selected ? _selectedDifficulty : null,
                          progressByDifficulty: {
                            for (final d in const [1, 2, 3]) d: state.progressForSkillDifficulty(skill, d),
                          },
                          onTap: () {
                            setState(() {
                              _selectedSkill = skill;
                            });
                          },
                          onDifficultyTap: selected
                              ? (value) {
                                  setState(() {
                                    _selectedDifficulty = value;
                                  });
                                }
                              : null,
                        );
                      },
                    ),
                  ),
                )
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _selectedSkill == null
                      ? null
                      : () {
                          state.startPractice(skill: _selectedSkill, difficulty: _selectedDifficulty);
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const PracticeScreen()),
                          );
                        },
                  child: const Text('Continue'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryRow extends StatelessWidget {
  const _CategoryRow({
    required this.label,
    required this.selected,
    required this.difficulty,
    required this.progressByDifficulty,
    required this.onTap,
    required this.onDifficultyTap,
  });

  final String label;
  final bool selected;
  final int? difficulty;
  final Map<int, double> progressByDifficulty;
  final VoidCallback onTap;
  final ValueChanged<int>? onDifficultyTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: onTap,
      child: Ink(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: selected ? colorScheme.primary.withOpacity(0.10) : colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(22),
          border: selected ? Border.all(color: colorScheme.primary.withOpacity(0.45), width: 2) : null,
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
              ),
            ),
            const SizedBox(width: 12),
            Row(
              children: [
                for (final value in const [1, 2, 3]) ...[
                  _DifficultySquare(
                    value: value,
                    selected: selected && difficulty == value,
                    enabled: selected,
                    progress: progressByDifficulty[value] ?? 0.0,
                    onTap: () => onDifficultyTap?.call(value),
                  ),
                  if (value != 3) const SizedBox(width: 8),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DifficultySquare extends StatelessWidget {
  const _DifficultySquare({
    required this.value,
    required this.selected,
    required this.enabled,
    required this.progress,
    required this.onTap,
  });

  final int value;
  final bool selected;
  final bool enabled;
  final double progress;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        width: 36,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Ink(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: selected
                    ? colorScheme.primary
                    : enabled
                        ? colorScheme.surface
                        : colorScheme.surface.withOpacity(0.5),
                border: Border.all(
                  color: selected ? colorScheme.primary : colorScheme.outline.withOpacity(0.4),
                ),
              ),
              child: Center(
                child: Text(
                  '$value',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: selected
                            ? colorScheme.onPrimary
                            : enabled
                                ? colorScheme.onSurface
                                : colorScheme.onSurface.withOpacity(0.5),
                      ),
                ),
              ),
            ),
            const SizedBox(height: 4),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: progress.clamp(0.0, 1.0),
                minHeight: 5,
                backgroundColor: colorScheme.surface.withOpacity(0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NoIndicatorScrollBehavior extends MaterialScrollBehavior {
  const _NoIndicatorScrollBehavior();

  @override
  Widget buildOverscrollIndicator(BuildContext context, Widget child, ScrollableDetails details) {
    return child;
  }

  @override
  Widget buildScrollbar(BuildContext context, Widget child, ScrollableDetails details) {
    return child;
  }
}
