import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_state.dart';
import '../models/personal_bank.dart';
import 'personal_practice_screen.dart';

class PersonalQuestionsScreen extends StatelessWidget {
  const PersonalQuestionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final categories = state.personalCategories;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Personal Questions'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateCategoryDialog(context),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Category'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your categories',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: categories.isEmpty
                  ? _EmptyState(
                      title: 'No personal categories yet',
                      subtitle: 'Tap “Category” to create your first one.',
                      icon: Icons.auto_awesome_rounded,
                    )
                  : GridView.count(
                      crossAxisCount: 2,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 1.05,
                      children: [
                        for (final category in categories)
                          _CategoryCard(
                            category: category,
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => PersonalCategoryScreen(categoryId: category.id),
                                ),
                              );
                            },
                          ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class PersonalCategoryScreen extends StatelessWidget {
  const PersonalCategoryScreen({super.key, required this.categoryId});

  final String categoryId;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final category = state.personalCategories.where((c) => c.id == categoryId).firstOrNull;

    if (category == null) {
      return const Scaffold(
        body: SafeArea(
          child: Center(child: Text('Category not found.')),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(category.name),
        actions: [
          IconButton(
            tooltip: 'Practice',
            onPressed: category.questions.isEmpty
                ? null
                : () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => PersonalPracticeScreen(categoryId: category.id),
                      ),
                    );
                  },
            icon: const Icon(Icons.play_arrow_rounded),
          ),
          IconButton(
            tooltip: 'Rename',
            onPressed: () => _showRenameCategoryDialog(context, category),
            icon: const Icon(Icons.edit_rounded),
          ),
          IconButton(
            tooltip: 'Delete',
            onPressed: () => _confirmDeleteCategory(context, category),
            icon: const Icon(Icons.delete_outline_rounded),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateQuestionDialog(context, categoryId: category.id),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Question'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(18),
        child: category.questions.isEmpty
            ? _EmptyState(
                title: 'No questions yet',
                subtitle: 'Tap “Question” to add one.',
                icon: Icons.quiz_rounded,
              )
            : ListView.separated(
                itemCount: category.questions.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final question = category.questions[index];
                  return _QuestionTile(
                    question: question,
                    onTap: () => _showEditQuestionDialog(context, categoryId: category.id, question: question),
                    onDelete: () => _confirmDeleteQuestion(context, categoryId: category.id, question: question),
                  );
                },
              ),
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({required this.category, required this.onTap});

  final PersonalCategory category;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: colorScheme.surfaceContainerHighest,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
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
                  color: colorScheme.primary.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(Icons.folder_rounded, color: colorScheme.primary),
              ),
              const Spacer(),
              Text(
                category.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 6),
              Text(
                '${category.questions.length} question${category.questions.length == 1 ? '' : 's'}',
                style: Theme.of(context)
                    .textTheme
                    .labelLarge
                    ?.copyWith(color: colorScheme.onSurfaceVariant, fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuestionTile extends StatelessWidget {
  const _QuestionTile({required this.question, required this.onTap, required this.onDelete});

  final PersonalQuestion question;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: colorScheme.surfaceContainerHighest,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      child: ListTile(
        onTap: onTap,
        title: Text(
          question.question,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
        ),
        subtitle: question.answer.isEmpty
            ? null
            : Text(
                'Answer: ${question.answer}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
        trailing: IconButton(
          tooltip: 'Delete',
          onPressed: onDelete,
          icon: const Icon(Icons.delete_outline_rounded),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.title, required this.subtitle, required this.icon});

  final String title;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: colorScheme.primary.withOpacity(0.14),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(icon, color: colorScheme.primary),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: Theme.of(context)
                .textTheme
                .bodyLarge
                ?.copyWith(color: colorScheme.onSurfaceVariant, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

Future<void> _showCreateCategoryDialog(BuildContext context) async {
  final controller = TextEditingController();
  final result = await showDialog<String>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text('New category'),
        content: TextField(
          controller: controller,
          autofocus: true,
          textInputAction: TextInputAction.done,
          decoration: const InputDecoration(labelText: 'Category name'),
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
  context.read<AppState>().createPersonalCategory(trimmed);
}

Future<void> _showRenameCategoryDialog(BuildContext context, PersonalCategory category) async {
  final controller = TextEditingController(text: category.name);
  final result = await showDialog<String>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text('Rename category'),
        content: TextField(
          controller: controller,
          autofocus: true,
          textInputAction: TextInputAction.done,
          decoration: const InputDecoration(labelText: 'Category name'),
          onSubmitted: (value) => Navigator.of(context).pop(value),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(controller.text),
            child: const Text('Save'),
          ),
        ],
      );
    },
  );

  if (result == null) return;
  final trimmed = result.trim();
  if (trimmed.isEmpty) return;
  context.read<AppState>().renamePersonalCategory(categoryId: category.id, name: trimmed);
}

Future<void> _confirmDeleteCategory(BuildContext context, PersonalCategory category) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text('Delete category?'),
        content: Text('Delete “${category.name}” and its questions?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      );
    },
  );
  if (result != true) return;
  context.read<AppState>().deletePersonalCategory(category.id);
  if (context.mounted) Navigator.of(context).pop();
}

Future<void> _showCreateQuestionDialog(BuildContext context, {required String categoryId}) async {
  final questionController = TextEditingController();
  final answerController = TextEditingController();
  final incorrect1Controller = TextEditingController();
  final incorrect2Controller = TextEditingController();
  final incorrect3Controller = TextEditingController();
  final explanationController = TextEditingController();

  final result = await showDialog<bool>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text('New question'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: questionController,
                autofocus: true,
                decoration: const InputDecoration(labelText: 'Question'),
                minLines: 2,
                maxLines: 4,
              ),
              const SizedBox(height: 10),
              TextField(
                controller: answerController,
                decoration: const InputDecoration(labelText: 'Correct answer'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: incorrect1Controller,
                decoration: const InputDecoration(labelText: 'Incorrect answer 1 (optional)'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: incorrect2Controller,
                decoration: const InputDecoration(labelText: 'Incorrect answer 2 (optional)'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: incorrect3Controller,
                decoration: const InputDecoration(labelText: 'Incorrect answer 3 (optional)'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: explanationController,
                decoration: const InputDecoration(labelText: 'Explanation (optional)'),
                minLines: 2,
                maxLines: 4,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Create'),
          ),
        ],
      );
    },
  );

  if (result != true) return;
  final incorrect = [
    incorrect1Controller.text,
    incorrect2Controller.text,
    incorrect3Controller.text,
  ];
  context.read<AppState>().createPersonalQuestion(
        categoryId: categoryId,
        question: questionController.text,
        answer: answerController.text,
        explanation: explanationController.text,
        incorrectAnswers: incorrect,
      );
}

Future<void> _showEditQuestionDialog(
  BuildContext context, {
  required String categoryId,
  required PersonalQuestion question,
}) async {
  final questionController = TextEditingController(text: question.question);
  final answerController = TextEditingController(text: question.answer);
  final explanationController = TextEditingController(text: question.explanation);
  final incorrect1Controller = TextEditingController(text: question.incorrectAnswers.length > 0 ? question.incorrectAnswers[0] : '');
  final incorrect2Controller = TextEditingController(text: question.incorrectAnswers.length > 1 ? question.incorrectAnswers[1] : '');
  final incorrect3Controller = TextEditingController(text: question.incorrectAnswers.length > 2 ? question.incorrectAnswers[2] : '');

  final result = await showDialog<bool>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text('Edit question'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: questionController,
                autofocus: true,
                decoration: const InputDecoration(labelText: 'Question'),
                minLines: 2,
                maxLines: 4,
              ),
              const SizedBox(height: 10),
              TextField(
                controller: answerController,
                decoration: const InputDecoration(labelText: 'Correct answer'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: incorrect1Controller,
                decoration: const InputDecoration(labelText: 'Incorrect answer 1 (optional)'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: incorrect2Controller,
                decoration: const InputDecoration(labelText: 'Incorrect answer 2 (optional)'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: incorrect3Controller,
                decoration: const InputDecoration(labelText: 'Incorrect answer 3 (optional)'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: explanationController,
                decoration: const InputDecoration(labelText: 'Explanation (optional)'),
                minLines: 2,
                maxLines: 4,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Save'),
          ),
        ],
      );
    },
  );

  if (result != true) return;
  final incorrect = [
    incorrect1Controller.text,
    incorrect2Controller.text,
    incorrect3Controller.text,
  ];
  context.read<AppState>().updatePersonalQuestion(
        categoryId: categoryId,
        questionId: question.id,
        question: questionController.text,
        answer: answerController.text,
        explanation: explanationController.text,
        incorrectAnswers: incorrect,
      );
}

Future<void> _confirmDeleteQuestion(
  BuildContext context, {
  required String categoryId,
  required PersonalQuestion question,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text('Delete question?'),
        content: const Text('This can’t be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      );
    },
  );
  if (result != true) return;
  context.read<AppState>().deletePersonalQuestion(categoryId: categoryId, questionId: question.id);
}

extension<T> on Iterable<T> {
  T? get firstOrNull {
    final iterator = this.iterator;
    if (!iterator.moveNext()) return null;
    return iterator.current;
  }
}
