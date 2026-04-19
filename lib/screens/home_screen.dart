import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_state.dart';
import '../book_library_state.dart';
import '../models/subject.dart';
import '../widgets/library_mode_toggle.dart';
import '../widgets/rgv_logo.dart';
import '../widgets/helper_bot.dart';
import 'book_hub_screen.dart';
import 'practice_screen.dart';
import 'practice_setup_screen.dart';
import 'progress_screen.dart';
import 'personal_questions_screen.dart';
import 'personal_practice_screen.dart';
import 'subject_import_screen.dart';
import 'custom_subject_progress_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    context.watch<BookLibraryState>();
    final subject = state.subject;
    final selectedCustom = state.selectedCustomSubject;
    final usingCustom = selectedCustom != null;
    final practiceEnabled =
        usingCustom || subject == Subject.math || subject == Subject.reading || subject == Subject.science || subject == Subject.history;
    final currentUser = state.currentUser;
    final customSubjects = [...state.personalCategories]..sort((a, b) => a.name.compareTo(b.name));
    final displayLabel = usingCustom ? selectedCustom.name : subject.label;

    return HelperBotPlacement(
      corner: HelperBotCorner.bottomLeft,
      child: Scaffold(
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
                            'RGV Tutor',
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
                        for (final category in customSubjects)
                          _CustomSubjectCard(
                            title: category.name,
                            subtitle: '${(category.questions.length + category.sections.fold<int>(0, (sum, s) => sum + s.questions.length))} card${(category.questions.length + category.sections.fold<int>(0, (sum, s) => sum + s.questions.length)) == 1 ? '' : 's'}',
                            onTap: () {
                              state.setCustomSubject(category.id);
                            },
                            selected: usingCustom && selectedCustom.id == category.id,
                          ),
                        _ImportSubjectCard(
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => const SubjectImportScreen()),
                            );
                          },
                        ),
                        _CreateSubjectCard(
                          onTap: () => _showCreateSubjectDialog(context),
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
                                    if (usingCustom) {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (_) => PersonalCategoryScreen(categoryId: selectedCustom.id),
                                        ),
                                      );
                                    } else {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(builder: (_) => const PracticeSetupScreen()),
                                      );
                                    }
                                  }
                                : null,
                            child: Text(practiceEnabled ? 'Continue ${displayLabel.toLowerCase()}' : 'Coming soon'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        IconButton.filledTonal(
                          onPressed: practiceEnabled
                              ? () {
                                  if (usingCustom) {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) => CustomSubjectProgressScreen(categoryId: selectedCustom.id),
                                      ),
                                    );
                                  } else {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(builder: (_) => const ProgressScreen()),
                                    );
                                  }
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
                        usingCustom ? 'Pick a section' : 'Pick a ${subject.label.toLowerCase()} skill',
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
                          if (usingCustom)
                            for (final section in selectedCustom.sections)
                              _SkillCard(
                                skill: section.name,
                                completion: state.combinedCompletionForPersonalSection(
                                  categoryId: selectedCustom.id,
                                  sectionId: section.id,
                                ),
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => PersonalPracticeScreen(
                                        categoryId: selectedCustom.id,
                                        sectionId: section.id,
                                        sectionName: section.name,
                                      ),
                                    ),
                                  );
                                },
                              )
                          else
                            for (final skill in state.skills)
                              _SkillCard(
                                skill: skill,
                                completion: state.completionForSkill(skill),
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

Future<void> _showCreateSubjectDialog(BuildContext context) async {
  final controller = TextEditingController();
  final result = await showDialog<String>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text('Create subject'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Subject name',
            hintText: 'e.g. Biology',
          ),
          textInputAction: TextInputAction.done,
          autofocus: true,
          onSubmitted: (value) => Navigator.of(context).pop(value),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(controller.text),
            child: const Text('Create'),
          ),
        ],
      );
    },
  );

  if (result == null) return;
  final trimmed = result.trim();
  if (trimmed.isEmpty) return;

  if (!context.mounted) return;
  final state = context.read<AppState>();
  final id = state.createPersonalCategory(trimmed);
  if (id == null) return;

  Navigator.of(context).push(
    MaterialPageRoute(builder: (_) => PersonalCategoryScreen(categoryId: id)),
  );
}

class _CreateSubjectCard extends StatelessWidget {
  const _CreateSubjectCard({required this.onTap});

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
                child: Icon(Icons.add_rounded, color: accent),
              ),
              const Spacer(),
              Text(
                'Create\nSubject',
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

class _ImportSubjectCard extends StatelessWidget {
  const _ImportSubjectCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final accent = const Color(0xFF06B6D4);

    return Material(
      color: accent.withOpacity(0.12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: BorderSide(color: accent.withOpacity(0.45), width: 2),
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
                child: Icon(Icons.qr_code_scanner_rounded, color: accent),
              ),
              const Spacer(),
              Text(
                'Import\nSubject',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
              ),
              const SizedBox(height: 6),
              Text(
                'Scan a QR',
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

class _CustomSubjectCard extends StatelessWidget {
  const _CustomSubjectCard({required this.title, required this.subtitle, required this.onTap, required this.selected});

  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final accent = const Color(0xFF8B5CF6);

    final bg = selected ? accent.withOpacity(0.16) : accent.withOpacity(0.12);
    final side = BorderSide(color: accent.withOpacity(selected ? 0.65 : 0.45), width: 2);

    return Material(
      color: bg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: side,
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
                child: Icon(Icons.auto_awesome_rounded, color: accent),
              ),
              const Spacer(),
              Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
              ),
              const SizedBox(height: 6),
              Text(
                subtitle,
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
  const _SkillCard({required this.skill, required this.completion, required this.onTap});

  final String skill;
  final double completion;
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
                  value: completion.clamp(0.0, 1.0),
                  minHeight: 10,
                  backgroundColor: colorScheme.surface,
                  valueColor: AlwaysStoppedAnimation(colorScheme.tertiary),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${(completion * 100).round()}% complete',
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
