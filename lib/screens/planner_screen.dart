import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_state.dart';

class PlannerScreen extends StatefulWidget {
  const PlannerScreen({super.key});

  @override
  State<PlannerScreen> createState() => _PlannerScreenState();
}

class _PlannerScreenState extends State<PlannerScreen> {
  late DateTime _visibleMonth;
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _visibleMonth = DateTime(now.year, now.month);
    _selectedDate = DateTime(now.year, now.month, now.day);
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final colorScheme = Theme.of(context).colorScheme;
    final today = DateTime.now();
    final selectedItems = state.plannerItemsForDate(_selectedDate);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Planner'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(18),
          children: [
            _MonthHeader(
              month: _visibleMonth,
              onPrev: () => setState(() => _visibleMonth = DateTime(_visibleMonth.year, _visibleMonth.month - 1)),
              onNext: () => setState(() => _visibleMonth = DateTime(_visibleMonth.year, _visibleMonth.month + 1)),
            ),
            const SizedBox(height: 12),
            _WeekdayRow(colorScheme: colorScheme),
            const SizedBox(height: 8),
            _MonthGrid(
              month: _visibleMonth,
              selectedDate: _selectedDate,
              today: today,
              countForDate: state.plannerCountForDate,
              onSelect: (date) => setState(() => _selectedDate = date),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: Text(
                    _formatSelectedDate(_selectedDate),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
                  ),
                ),
                IconButton.filled(
                  tooltip: 'Add',
                  onPressed: () => _showAddDialog(context, date: _selectedDate),
                  icon: const Icon(Icons.add_rounded),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (selectedItems.isEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Text(
                  'No plans yet. Tap + to add one.',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              )
            else
              for (final item in selectedItems)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Dismissible(
                    key: ValueKey(item['id']),
                    background: Container(
                      decoration: BoxDecoration(
                        color: colorScheme.errorContainer,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Icon(Icons.delete_rounded, color: colorScheme.onErrorContainer),
                    ),
                    direction: DismissDirection.endToStart,
                    onDismissed: (_) => context.read<AppState>().deletePlannerItem(item['id'] as String),
                    child: Material(
                      color: _plannerTileColor(context, item) ?? colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(18),
                      clipBehavior: Clip.antiAlias,
                      child: ListTile(
                        dense: true,
                        leading: Checkbox(
                          value: (item['done'] as bool?) ?? false,
                          onChanged: (value) {
                            context.read<AppState>().togglePlannerItemDone(
                                  itemId: item['id'] as String,
                                  done: value ?? false,
                                );
                          },
                        ),
                        title: Text(
                          (item['title'] as String?) ?? '',
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        subtitle: _plannerSubtitle(context, item),
                        trailing: IconButton(
                          tooltip: 'Delete',
                          onPressed: () => context.read<AppState>().deletePlannerItem(item['id'] as String),
                          icon: const Icon(Icons.delete_outline_rounded),
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

  Future<void> _showAddDialog(BuildContext context, {required DateTime date}) async {
    final controller = TextEditingController();
    TimeOfDay? selectedTime;
    Color? selectedColor;

    final result = await showDialog<_PlannerDraft>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Add plan'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: controller,
                    autofocus: true,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (value) => Navigator.of(context).pop(
                      _PlannerDraft(title: value, time: selectedTime, color: selectedColor),
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Title',
                      hintText: 'e.g. Study fractions',
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            final picked = await showTimePicker(
                              context: context,
                              initialTime: selectedTime ?? TimeOfDay.now(),
                            );
                            if (picked == null) return;
                            setDialogState(() => selectedTime = picked);
                          },
                          icon: const Icon(Icons.schedule_rounded),
                          label: Text(selectedTime == null ? 'Add time' : selectedTime!.format(context)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            final picked = await _pickPlannerColor(context, selectedColor);
                            if (picked == null) return;
                            setDialogState(() => selectedColor = picked);
                          },
                          icon: const Icon(Icons.palette_outlined),
                          label: Text(selectedColor == null ? 'Add color' : _colorLabel(selectedColor!)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
                FilledButton(
                  onPressed: () => Navigator.of(context).pop(
                    _PlannerDraft(title: controller.text, time: selectedTime, color: selectedColor),
                  ),
                  child: const Text('Add'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result == null) return;
    if (!context.mounted) return;

    context.read<AppState>().addPlannerItem(
          date: date,
          title: result.title,
          timeMinutes: result.time == null ? null : (result.time!.hour * 60 + result.time!.minute),
          colorValue: result.color?.value,
        );
  }

  String _formatSelectedDate(DateTime date) {
    final monthName = _monthNames[date.month - 1];
    return '$monthName ${date.day}, ${date.year}';
  }
}

class _PlannerDraft {
  const _PlannerDraft({required this.title, required this.time, required this.color});

  final String title;
  final TimeOfDay? time;
  final Color? color;
}

Widget? _plannerSubtitle(BuildContext context, Map<String, dynamic> item) {
  final minutes = item['timeMinutes'] as int?;
  if (minutes == null) return null;
  final t = TimeOfDay(hour: minutes ~/ 60, minute: minutes % 60);
  return Text(
    t.format(context),
    style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
  );
}

Color? _plannerTileColor(BuildContext context, Map<String, dynamic> item) {
  final raw = item['colorValue'];
  if (raw is! int) return null;
  final base = Color(raw);
  final bg = base.withOpacity(0.18);
  final blend = Theme.of(context).colorScheme.surfaceContainerHighest;
  return Color.alphaBlend(bg, blend);
}

String _colorLabel(Color color) => '#${color.value.toRadixString(16).padLeft(8, '0').toUpperCase()}';

Future<Color?> _pickPlannerColor(BuildContext context, Color? current) async {
  const swatches = <Color>[
    Color(0xFF3B82F6),
    Color(0xFF10B981),
    Color(0xFFF59E0B),
    Color(0xFFEF4444),
    Color(0xFF8B5CF6),
    Color(0xFF06B6D4),
    Color(0xFFEC4899),
    Color(0xFF64748B),
  ];

  return showDialog<Color>(
    context: context,
    builder: (context) {
      return SimpleDialog(
        title: const Text('Pick a color'),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                for (final color in swatches)
                  InkWell(
                    onTap: () => Navigator.of(context).pop(color),
                    borderRadius: BorderRadius.circular(999),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: Border.all(
                          width: 3,
                          color: current?.value == color.value
                              ? Theme.of(context).colorScheme.onSurface
                              : Colors.transparent,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          SimpleDialogOption(
            onPressed: () async {
              final picked = await _pickCustomHexColor(context, current);
              if (!context.mounted) return;
              Navigator.of(context).pop(picked);
            },
            child: const Text('Custom hex…'),
          ),
          if (current != null)
            SimpleDialogOption(
              onPressed: () => Navigator.of(context).pop(null),
              child: const Text('Clear color'),
            ),
        ],
      );
    },
  );
}

Future<Color?> _pickCustomHexColor(BuildContext context, Color? current) async {
  final controller = TextEditingController(text: current == null ? '' : _colorLabel(current));
  return showDialog<Color>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text('Custom color'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Hex (e.g. #FF3B82F6 or #3B82F6)'),
          textInputAction: TextInputAction.done,
          onSubmitted: (value) => Navigator.of(context).pop(_parseHexColor(value)),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(_parseHexColor(controller.text)),
            child: const Text('Use'),
          ),
        ],
      );
    },
  );
}

Color? _parseHexColor(String input) {
  final raw = input.trim().replaceFirst('#', '');
  if (raw.length != 6 && raw.length != 8) return null;
  final value = int.tryParse(raw, radix: 16);
  if (value == null) return null;
  if (raw.length == 6) return Color(0xFF000000 | value);
  return Color(value);
}

class _MonthHeader extends StatelessWidget {
  const _MonthHeader({required this.month, required this.onPrev, required this.onNext});

  final DateTime month;
  final VoidCallback onPrev;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final title = '${_monthNames[month.month - 1]} ${month.year}';

    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
          ),
        ),
        IconButton(
          tooltip: 'Previous month',
          onPressed: onPrev,
          icon: const Icon(Icons.chevron_left_rounded),
        ),
        IconButton(
          tooltip: 'Next month',
          onPressed: onNext,
          icon: const Icon(Icons.chevron_right_rounded),
        ),
      ],
    );
  }
}

class _WeekdayRow extends StatelessWidget {
  const _WeekdayRow({required this.colorScheme});

  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    const labels = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];
    return Row(
      children: [
        for (final label in labels)
          Expanded(
            child: Center(
              child: Text(
                label,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w800,
                    ),
              ),
            ),
          ),
      ],
    );
  }
}

class _MonthGrid extends StatelessWidget {
  const _MonthGrid({
    required this.month,
    required this.selectedDate,
    required this.today,
    required this.countForDate,
    required this.onSelect,
  });

  final DateTime month;
  final DateTime selectedDate;
  final DateTime today;
  final int Function(DateTime date) countForDate;
  final ValueChanged<DateTime> onSelect;

  @override
  Widget build(BuildContext context) {
    final first = DateTime(month.year, month.month, 1);
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final leading = first.weekday % 7;

    final cells = <DateTime?>[for (var i = 0; i < leading; i++) null];
    for (var day = 1; day <= daysInMonth; day++) {
      cells.add(DateTime(month.year, month.month, day));
    }
    while (cells.length % 7 != 0) {
      cells.add(null);
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        mainAxisSpacing: 6,
        crossAxisSpacing: 6,
      ),
      itemCount: cells.length,
      itemBuilder: (context, index) {
        final date = cells[index];
        if (date == null) return const SizedBox.shrink();

        final isSelected = _isSameDate(date, selectedDate);
        final isToday = _isSameDate(date, today);
        final count = countForDate(date);

        final colorScheme = Theme.of(context).colorScheme;
        final bg = isSelected
            ? colorScheme.primary
            : isToday
                ? colorScheme.primary.withOpacity(0.16)
                : colorScheme.surfaceContainerHighest;
        final fg = isSelected ? colorScheme.onPrimary : colorScheme.onSurface;

        return Material(
          color: bg,
          borderRadius: BorderRadius.circular(12),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => onSelect(date),
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: Column(
                children: [
                  Text(
                    '${date.day}',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w900, color: fg),
                  ),
                  const Spacer(),
                  if (count > 0)
                    Container(
                      width: 18,
                      height: 6,
                      decoration: BoxDecoration(
                        color: isSelected ? fg.withOpacity(0.9) : colorScheme.tertiary,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

bool _isSameDate(DateTime a, DateTime b) {
  return a.year == b.year && a.month == b.month && a.day == b.day;
}

const _monthNames = <String>[
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
];
