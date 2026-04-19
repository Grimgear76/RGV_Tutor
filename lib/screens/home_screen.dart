import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_state.dart';
import '../book_library_state.dart';
import '../models/subject.dart';
import '../widgets/library_mode_toggle.dart';
import '../widgets/rgv_logo.dart';
import 'book_hub_screen.dart';
import 'practice_screen.dart';
import 'practice_setup_screen.dart';
import 'progress_screen.dart';
import 'personal_questions_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final bookState = context.watch<BookLibraryState>();
    final colorScheme = Theme.of(context).colorScheme;
    final subject = state.subject;
    final practiceEnabled =
        subject == Subject.math || subject == Subject.reading || subject == Subject.science || subject == Subject.history;
    final currentUser = state.currentUser;

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.all(18),
              sliver: SliverList(
                delegate: SliverChildListDelegate(
                  [
                    Row(
                      children: [
                        const RgvTutorLogo(size: 40),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'RGV Math Coach',
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.w900,
                                ),
                          ),
                        ),
                        IconButton(
                          tooltip: 'Books',
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => const BookHubScreen()),
                            );
                          },
                          icon: const Icon(Icons.library_books_rounded),
                        ),
                        IconButton(
                          tooltip: 'Sign out',
                          onPressed: () => context.read<AppState>().signOut(),
                          icon: const Icon(Icons.logout_rounded),
                        ),
                        const LibraryModeToggle(compact: true),
                      ],
                    ),
                    const SizedBox(height: 14),
                    if (currentUser != null) ...[
                      Text(
                        currentUser.isGuest
                            ? 'Hi Guest!'
                            : 'Hi ${currentUser.name.isEmpty ? currentUser.username : currentUser.name}!',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w900,
                            ),
                      ),
                      const SizedBox(height: 8),
                    ],
                    Text(
                      'Pick a subject and practice ${bookState.mode == LibraryMode.online ? 'online' : 'offline'}.',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'Choose a subject',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 10),
                    GridView.count(
                      shrinkWrap: true,
                      crossAxisCount: 2,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 1.2,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        for (final s in Subject.values)
                          _SubjectCard(
                            subject: s,
                            selected: s == subject,
                            onTap: () => state.setSubject(s),
                          ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Expanded(
                          child: FilledButton(
                            onPressed: practiceEnabled
                                ? () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(builder: (_) => const PracticeSetupScreen()),
                                    );
                                  }
                                : null,
                            child: Text(practiceEnabled ? 'Continue ${subject.label.toLowerCase()}' : 'Coming soon'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        IconButton.filledTonal(
                          onPressed: practiceEnabled
                              ? () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(builder: (_) => const ProgressScreen()),
                                  );
                                }
                              : null,
                          icon: const Icon(Icons.insights_rounded),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    if (!practiceEnabled) _ComingSoon(subject: subject),
                    if (practiceEnabled) ...[
                      Text(
                        'Pick a ${subject.label.toLowerCase()} skill',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      const SizedBox(height: 10),
                      GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: 2,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: 1.15,
                        children: [
                          _PersonalQuestionsCard(
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(builder: (_) => const PersonalQuestionsScreen()),
                              );
                            },
                          ),
                          for (final skill in state.skills)
                            _SkillCard(
                              skill: skill,
                              mastery: state.masteryFor(skill),
                              onTap: () {
                                state.startSkill(skill);
                                Navigator.of(context).push(
                                  MaterialPageRoute(builder: (_) => const PracticeScreen()),
                                );
                              },
                            ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ComingSoon extends StatelessWidget {
  const _ComingSoon({required this.subject});

  final Subject subject;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Text(
        '${subject.label} practice is coming soon.\nPick Math, Reading / Writing, Science, or History to try it now.',
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: colorScheme.onSurfaceVariant,
            ),
      ),
    );
  }
}

class _SubjectCard extends StatelessWidget {
  const _SubjectCard({required this.subject, required this.selected, required this.onTap});

  final Subject subject;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final (icon, accent) = switch (subject) {
      Subject.math => (Icons.calculate_rounded, colorScheme.primary),
      Subject.reading => (Icons.menu_book_rounded, const Color(0xFF3B82F6)),
      Subject.science => (Icons.science_rounded, const Color(0xFF10B981)),
      Subject.history => (Icons.public_rounded, const Color(0xFFF59E0B)),
    };

    final backgroundColor = selected ? accent.withOpacity(0.12) : colorScheme.surfaceContainerHighest;
    final side = selected ? BorderSide(color: accent.withOpacity(0.55), width: 2) : BorderSide.none;

    return Material(
      color: backgroundColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22), side: side),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: accent.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: accent),
              ),
              const Spacer(),
              Text(
                subject.label,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
              ),
              const SizedBox(height: 6),
              Text(
                selected ? 'Selected' : 'Tap to choose',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PersonalQuestionsCard extends StatelessWidget {
  const _PersonalQuestionsCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final accent = colorScheme.tertiary;

    return Material(
      color: accent.withOpacity(0.14),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: BorderSide(color: accent.withOpacity(0.55), width: 2),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: accent.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(Icons.create_rounded, color: accent),
              ),
              const Spacer(),
              Text(
                'Personal\nQuestions',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
              ),
              const SizedBox(height: 6),
              Text(
                'Make your own',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SkillCard extends StatelessWidget {
  const _SkillCard({required this.skill, required this.mastery, required this.onTap});

  final String skill;
  final double mastery;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(22),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Align(
                  alignment: Alignment.topLeft,
                  child: Text(
                    skill,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: mastery.clamp(0.0, 1.0),
                  minHeight: 10,
                  backgroundColor: colorScheme.surface,
                  valueColor: AlwaysStoppedAnimation(colorScheme.tertiary),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${(mastery * 100).round()}% mastery',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
