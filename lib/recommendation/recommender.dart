import 'dart:math';

import '../models/problem.dart';
import '../models/subject.dart';

class Recommender {
  Recommender({
    this.learnRate = 0.20,
    this.slipRate = 0.15,
    Random? random,
  }) : _random = random ?? Random();

  final double learnRate;
  final double slipRate;
  final Random _random;

  double updateMastery({required double mastery, required bool correct}) {
    final m = mastery.clamp(0.0, 1.0);
    if (correct) {
      return (m + (1 - m) * learnRate).clamp(0.0, 1.0);
    }
    return (m - m * slipRate).clamp(0.0, 1.0);
  }

  Problem recommend({
    required List<Problem> all,
    required Map<String, double> masteryBySkill,
    required Set<String> seenProblemIds,
    String? forcedSkill,
    int? forcedDifficulty,
  }) {
    final skills = all.map((p) => p.skill).toSet().toList()..sort();

    String pickSkill() {
      if (forcedSkill != null) return forcedSkill;

      final skillsWithUnseen = skills
          .where((skill) => all.any((p) => p.skill == skill && !seenProblemIds.contains(p.id)))
          .toList(growable: false);

      if (skillsWithUnseen.isEmpty) {
        return _pickTargetSkill(skills, masteryBySkill);
      }

      return _pickTargetSkill(skillsWithUnseen, masteryBySkill);
    }

    final targetSkill = pickSkill();
    final targetMastery = (masteryBySkill[targetSkill] ?? 0.35).clamp(0.0, 1.0);
    final desiredDifficulty = (forcedDifficulty ?? (1 + (targetMastery * 4)).round()).clamp(1, 5);

    if (targetSkill == 'Equations' && desiredDifficulty <= 2) {
      return _generateEquationProblem(difficulty: desiredDifficulty);
    }

    final candidates = all
        .where((p) => p.skill == targetSkill)
        .where((p) => !seenProblemIds.contains(p.id))
        .toList();

    if (candidates.isEmpty) {
      final fallback = all.where((p) => p.skill == targetSkill).toList();
      fallback.sort((a, b) => (a.difficulty - desiredDifficulty).abs().compareTo(
            (b.difficulty - desiredDifficulty).abs(),
          ));
      return fallback.first;
    }

    candidates.sort((a, b) => (a.difficulty - desiredDifficulty).abs().compareTo(
          (b.difficulty - desiredDifficulty).abs(),
        ));

    return candidates.first;
  }

  Problem _generateEquationProblem({required int difficulty}) {
    final id = 'gen_eq_${DateTime.now().microsecondsSinceEpoch}_${_random.nextInt(1 << 32)}';

    final a = difficulty == 1 ? 1 : _random.nextInt(4) + 2;
    final x = _random.nextInt(11) - 5;
    final b = _random.nextInt(13) - 6;
    final c = a * x + b;

    final question = a == 1 ? 'Solve for x: x + $b = $c' : 'Solve for x: ${a}x + $b = $c';

    final choiceSet = <int>{x};
    while (choiceSet.length < 4) {
      final delta = _random.nextInt(9) - 4;
      final candidate = x + (delta == 0 ? 2 : delta);
      choiceSet.add(candidate);
    }

    final choices = choiceSet.toList()..shuffle(_random);
    final answerIndex = choices.indexOf(x);

    final steps = <String>[
      'Subtract $b from both sides: ${a == 1 ? 'x' : '${a}x'} = ${c - b}.',
      if (a != 1) 'Divide both sides by $a: x = $x.' else 'So x = $x.',
    ];

    return Problem(
      id: id,
      subject: Subject.math,
      skill: 'Equations',
      difficulty: difficulty,
      question: question,
      choices: choices.map((v) => '$v').toList(growable: false),
      answerIndex: answerIndex,
      steps: steps,
    );
  }

  String _pickTargetSkill(List<String> skills, Map<String, double> masteryBySkill) {
    var bestSkill = skills.first;
    var bestMastery = (masteryBySkill[bestSkill] ?? 0.35);

    for (final skill in skills) {
      final m = masteryBySkill[skill] ?? 0.35;
      if (m < bestMastery) {
        bestMastery = m;
        bestSkill = skill;
      }
    }

    return bestSkill;
  }
}
