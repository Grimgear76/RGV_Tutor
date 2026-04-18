import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'models/problem.dart';
import 'recommendation/recommender.dart';

class AppState extends ChangeNotifier {
  AppState({required this.problems, required this.recommender});

  final List<Problem> problems;
  final Recommender recommender;

  static const _boxName = 'rgv_math_tutor';
  static const _masteryKey = 'masteryBySkill';
  static const _seenKey = 'seenProblemIds';
  static const _xpKey = 'xp';
  static const _streakKey = 'streak';
  static const _wrongStreakBySkillKey = 'wrongStreakBySkill';

  late final Box _box;

  Map<String, double> masteryBySkill = {};
  Set<String> seenProblemIds = {};
  int xp = 0;
  int streak = 0;
  Map<String, int> wrongStreakBySkill = {};

  Problem? current;
  bool? lastCorrect;

  Future<void> init() async {
    _box = await Hive.openBox(_boxName);

    masteryBySkill = Map<String, double>.from(_box.get(_masteryKey, defaultValue: <String, double>{}));
    seenProblemIds = Set<String>.from(_box.get(_seenKey, defaultValue: <String>[]));
    wrongStreakBySkill = Map<String, int>.from(_box.get(_wrongStreakBySkillKey, defaultValue: <String, int>{}));

    xp = (_box.get(_xpKey, defaultValue: 0) as int);
    streak = (_box.get(_streakKey, defaultValue: 0) as int);

    current = recommender.recommend(
      all: problems,
      masteryBySkill: masteryBySkill,
      seenProblemIds: seenProblemIds,
    );

    notifyListeners();
  }

  List<String> get skills => problems.map((p) => p.skill).toSet().toList()..sort();

  double masteryFor(String skill) => (masteryBySkill[skill] ?? 0.35).clamp(0.0, 1.0);

  int get level => (xp / 100).floor() + 1;

  double get levelProgress => (xp % 100) / 100.0;

  void startSkill(String skill) {
    current = recommender.recommend(
      all: problems,
      masteryBySkill: masteryBySkill,
      seenProblemIds: seenProblemIds,
      forcedSkill: skill,
    );
    lastCorrect = null;
    notifyListeners();
  }

  void answer(int choiceIndex) {
    final problem = current;
    if (problem == null) return;

    final correct = choiceIndex == problem.answerIndex;
    lastCorrect = correct;

    final prevMastery = masteryFor(problem.skill);
    masteryBySkill[problem.skill] = recommender.updateMastery(mastery: prevMastery, correct: correct);

    seenProblemIds.add(problem.id);

    if (correct) {
      wrongStreakBySkill[problem.skill] = 0;
      streak += 1;
      xp += _xpGain(problem: problem, masteryBefore: prevMastery);
    } else {
      wrongStreakBySkill[problem.skill] = (wrongStreakBySkill[problem.skill] ?? 0) + 1;
      streak = 0;
      xp += 5;
    }

    _persist();
    notifyListeners();
  }

  void next() {
    final problem = current;
    if (problem == null) return;

    final wrongStreak = wrongStreakBySkill[problem.skill] ?? 0;
    final forcedSkill = wrongStreak >= 2 ? _prereqSkill(problem.skill) : null;

    current = recommender.recommend(
      all: problems,
      masteryBySkill: masteryBySkill,
      seenProblemIds: seenProblemIds,
      forcedSkill: forcedSkill,
    );
    lastCorrect = null;
    notifyListeners();
  }

  int _xpGain({required Problem problem, required double masteryBefore}) {
    final base = 10 + (problem.difficulty - 1) * 4;
    final productiveZone = masteryBefore >= 0.40 && masteryBefore <= 0.70;
    final bonus = productiveZone ? 8 : 0;
    final streakBonus = (streak.clamp(0, 5)) * 2;
    return base + bonus + streakBonus;
  }

  String? _prereqSkill(String skill) {
    if (skill == 'Equations') return 'Expressions';
    if (skill == 'Ratios & Proportions') return 'Fractions';
    return null;
  }

  Future<void> reset() async {
    masteryBySkill.clear();
    seenProblemIds.clear();
    wrongStreakBySkill.clear();
    xp = 0;
    streak = 0;
    lastCorrect = null;

    await _box.clear();

    current = recommender.recommend(
      all: problems,
      masteryBySkill: masteryBySkill,
      seenProblemIds: seenProblemIds,
    );

    notifyListeners();
  }

  void _persist() {
    _box.put(_masteryKey, masteryBySkill);
    _box.put(_seenKey, seenProblemIds.toList());
    _box.put(_wrongStreakBySkillKey, wrongStreakBySkill);
    _box.put(_xpKey, xp);
    _box.put(_streakKey, streak);
  }
}
