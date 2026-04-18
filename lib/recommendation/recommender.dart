import '../models/problem.dart';

class Recommender {
  const Recommender({
    this.learnRate = 0.20,
    this.slipRate = 0.15,
  });

  final double learnRate;
  final double slipRate;

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
  }) {
    final skills = all.map((p) => p.skill).toSet().toList()..sort();

    final targetSkill = forcedSkill ?? _pickTargetSkill(skills, masteryBySkill);
    final targetMastery = (masteryBySkill[targetSkill] ?? 0.35).clamp(0.0, 1.0);
    final desiredDifficulty = (1 + (targetMastery * 4)).round().clamp(1, 5);

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
