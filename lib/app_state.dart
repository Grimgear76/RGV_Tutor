import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'models/problem.dart';
import 'models/user.dart';
import 'models/subject.dart';
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
  static const _subjectKey = 'subject';
  static const _usersKey = 'users';
  static const _currentUserKey = 'currentUser';
  static const _guestUsername = '__guest__';

  late final Box _box;

  Map<String, double> masteryBySkill = {};
  Set<String> seenProblemIds = {};
  int xp = 0;
  int streak = 0;
  Map<String, int> wrongStreakBySkill = {};

  Problem? current;
  bool? lastCorrect;

  Subject subject = Subject.math;

  List<AppUser> users = const [];
  AppUser? currentUser;

  bool get isSignedIn => currentUser != null;

  Future<void> init() async {
    _box = await Hive.openBox(_boxName);

    users = (_box.get(_usersKey, defaultValue: const <dynamic>[]) as List)
        .map((row) => AppUser.fromMap(Map<String, dynamic>.from(row as Map)))
        .toList(growable: false);
    final currentUsername = _box.get(_currentUserKey) as String?;
    if (currentUsername != null) {
      if (currentUsername == _guestUsername) {
        currentUser = AppUser.guest();
      } else {
        currentUser = users.where((u) => u.username == currentUsername).firstOrNull;
      }
    }

    subject = SubjectX.fromId(_box.get(_subjectKey, defaultValue: Subject.math.id) as String);

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

  String? signUp({
    required String name,
    required String username,
    required String password,
    required int age,
    required String gradeLevel,
  }) {
    final trimmedUsername = username.trim();
    if (trimmedUsername.isEmpty) return 'Username is required.';
    if (users.any((u) => u.username.toLowerCase() == trimmedUsername.toLowerCase())) {
      return 'That username is already taken.';
    }

    final user = AppUser(
      name: name.trim(),
      username: trimmedUsername,
      password: password,
      age: age,
      gradeLevel: gradeLevel.trim(),
      isGuest: false,
    );

    users = [...users, user];
    currentUser = user;
    _persistUsers();
    _box.put(_currentUserKey, user.username);
    notifyListeners();
    return null;
  }

  String? signIn({required String username, required String password}) {
    final trimmedUsername = username.trim();
    if (trimmedUsername == _guestUsername) return 'Pick a different username.';
    final user = users.where((u) => u.username == trimmedUsername).firstOrNull;
    if (user == null) return 'Account not found.';
    if (user.password != password) return 'Wrong password.';

    currentUser = user;
    _box.put(_currentUserKey, user.username);
    notifyListeners();
    return null;
  }

  void signInAsGuest() {
    currentUser = AppUser.guest();
    _box.put(_currentUserKey, _guestUsername);
    notifyListeners();
  }

  void signOut() {
    currentUser = null;
    _box.delete(_currentUserKey);
    notifyListeners();
  }

  void setSubject(Subject next) {
    if (subject == next) return;
    subject = next;
    _box.put(_subjectKey, subject.id);
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

  void startPractice({String? skill, int? difficulty}) {
    current = recommender.recommend(
      all: problems,
      masteryBySkill: masteryBySkill,
      seenProblemIds: seenProblemIds,
      forcedSkill: skill,
      forcedDifficulty: difficulty,
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

    subject = Subject.math;
    users = const [];
    currentUser = null;

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

  void _persistUsers() {
    _box.put(_usersKey, users.map((u) => u.toMap()).toList(growable: false));
  }
}

extension<T> on Iterable<T> {
  T? get firstOrNull {
    final iterator = this.iterator;
    if (!iterator.moveNext()) return null;
    return iterator.current;
  }
}
