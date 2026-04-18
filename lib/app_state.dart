import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'models/problem.dart';
import 'models/user.dart';
import 'models/subject.dart';
import 'models/personal_bank.dart';
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
  static const _personalBankByUserKey = 'personalBankByUser';
  static const _guestUsername = '__guest__';

  late final Box _box;

  Map<String, double> masteryBySkill = {};
  Set<String> seenProblemIds = {};
  int xp = 0;
  int streak = 0;
  Map<String, int> wrongStreakBySkill = {};

  Problem? current;
  bool? lastCorrect;

  String? practiceSkill;
  int? practiceDifficulty;
  int practiceQuestionsDoneInDifficulty = 0;
  int practiceQuestionsPerDifficulty = 5;
  int practiceMaxDifficulty = 3;

  int _attemptsOnCurrentProblem = 0;

  Subject subject = Subject.math;

  List<AppUser> users = const [];
  AppUser? currentUser;

  Map<String, PersonalBank> personalBankByUser = {};

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

    personalBankByUser = _loadPersonalBanks(
      _box.get(_personalBankByUserKey, defaultValue: const <String, dynamic>{}),
    );

    xp = (_box.get(_xpKey, defaultValue: 0) as int);
    streak = (_box.get(_streakKey, defaultValue: 0) as int);

    current = recommender.recommend(
      all: problems,
      masteryBySkill: masteryBySkill,
      seenProblemIds: seenProblemIds,
    );

    notifyListeners();
  }

  PersonalBank get personalBank {
    final username = _activeUsername;
    return personalBankByUser[username] ?? const PersonalBank(categories: []);
  }

  List<PersonalCategory> get personalCategories => personalBank.categories;

  void createPersonalCategory(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;

    final category = PersonalCategory(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      name: trimmed,
      questions: const [],
    );

    _updatePersonalBank(
      personalBank.copyWith(categories: [...personalCategories, category]),
    );
  }

  void renamePersonalCategory({required String categoryId, required String name}) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;

    final categories = personalCategories
        .map((c) => c.id == categoryId ? c.copyWith(name: trimmed) : c)
        .toList(growable: false);
    _updatePersonalBank(personalBank.copyWith(categories: categories));
  }

  void deletePersonalCategory(String categoryId) {
    final categories = personalCategories.where((c) => c.id != categoryId).toList(growable: false);
    _updatePersonalBank(personalBank.copyWith(categories: categories));
  }

  void createPersonalQuestion({
    required String categoryId,
    required String question,
    required String answer,
    required String explanation,
    required List<String> incorrectAnswers,
  }) {
    final q = question.trim();
    final a = answer.trim();
    final e = explanation.trim();
    final incorrect = incorrectAnswers
        .map((row) => row.trim())
        .where((row) => row.isNotEmpty)
        .where((row) => row.toLowerCase() != a.toLowerCase())
        .toSet()
        .toList(growable: false)
        .take(3)
        .toList(growable: false);
    if (q.isEmpty || a.isEmpty) return;

    final next = PersonalQuestion(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      question: q,
      answer: a,
      explanation: e,
      incorrectAnswers: incorrect,
    );

    final categories = personalCategories.map((c) {
      if (c.id != categoryId) return c;
      return c.copyWith(questions: [...c.questions, next]);
    }).toList(growable: false);

    _updatePersonalBank(personalBank.copyWith(categories: categories));
  }

  void updatePersonalQuestion({
    required String categoryId,
    required String questionId,
    required String question,
    required String answer,
    required String explanation,
    required List<String> incorrectAnswers,
  }) {
    final q = question.trim();
    final a = answer.trim();
    final e = explanation.trim();
    final incorrect = incorrectAnswers
        .map((row) => row.trim())
        .where((row) => row.isNotEmpty)
        .where((row) => row.toLowerCase() != a.toLowerCase())
        .toSet()
        .toList(growable: false)
        .take(3)
        .toList(growable: false);
    if (q.isEmpty || a.isEmpty) return;

    final categories = personalCategories.map((c) {
      if (c.id != categoryId) return c;
      final questions = c.questions
          .map(
            (row) => row.id == questionId
                ? row.copyWith(
                    question: q,
                    answer: a,
                    explanation: e,
                    incorrectAnswers: incorrect,
                  )
                : row,
          )
          .toList(growable: false);
      return c.copyWith(questions: questions);
    }).toList(growable: false);

    _updatePersonalBank(personalBank.copyWith(categories: categories));
  }

  void deletePersonalQuestion({required String categoryId, required String questionId}) {
    final categories = personalCategories.map((c) {
      if (c.id != categoryId) return c;
      return c.copyWith(questions: c.questions.where((q) => q.id != questionId).toList(growable: false));
    }).toList(growable: false);

    _updatePersonalBank(personalBank.copyWith(categories: categories));
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

  String get _activeUsername {
    final user = currentUser;
    if (user == null) return _guestUsername;
    return user.isGuest ? _guestUsername : user.username;
  }

  void setSubject(Subject next) {
    if (subject == next) return;
    subject = next;
    _box.put(_subjectKey, subject.id);
    notifyListeners();
  }

  List<String> get skills => problems.map((p) => p.skill).toSet().toList()..sort();

  double masteryFor(String skill) => (masteryBySkill[skill] ?? 0.35).clamp(0.0, 1.0);

  double progressForSkillDifficulty(String skill, int difficulty) {
    final pool = problems.where((p) => p.skill == skill && p.difficulty == difficulty).toList(growable: false);
    if (pool.isEmpty) return 0.0;
    final seen = pool.where((p) => seenProblemIds.contains(p.id)).length;
    return (seen / pool.length).clamp(0.0, 1.0);
  }

  int get level => (xp / 100).floor() + 1;

  double get levelProgress => (xp % 100) / 100.0;

  void startSkill(String skill) {
    practiceSkill = null;
    practiceDifficulty = null;
    practiceQuestionsDoneInDifficulty = 0;
    current = recommender.recommend(
      all: problems,
      masteryBySkill: masteryBySkill,
      seenProblemIds: seenProblemIds,
      forcedSkill: skill,
    );
    lastCorrect = null;
    _attemptsOnCurrentProblem = 0;
    notifyListeners();
  }

  void startPractice({String? skill, int? difficulty}) {
    practiceSkill = skill;
    practiceDifficulty = difficulty;
    practiceQuestionsDoneInDifficulty = 0;
    current = recommender.recommend(
      all: problems,
      masteryBySkill: masteryBySkill,
      seenProblemIds: seenProblemIds,
      forcedSkill: skill,
      forcedDifficulty: difficulty,
    );
    lastCorrect = null;
    _attemptsOnCurrentProblem = 0;
    notifyListeners();
  }

  void answer(int choiceIndex) {
    final problem = current;
    if (problem == null) return;

    final correct = choiceIndex == problem.answerIndex;
    lastCorrect = correct;

    final prevMastery = masteryFor(problem.skill);
    masteryBySkill[problem.skill] = recommender.updateMastery(mastery: prevMastery, correct: correct);

    if (_attemptsOnCurrentProblem == 0) {
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
    } else {
      _box.put(_masteryKey, masteryBySkill);
    }

    _attemptsOnCurrentProblem += 1;
    notifyListeners();
  }

  void retry() {
    if (current == null) return;
    lastCorrect = null;
    notifyListeners();
  }

  void next() {
    final problem = current;
    if (problem == null) return;

    if (practiceDifficulty != null) {
      practiceQuestionsDoneInDifficulty += 1;
      if (practiceQuestionsDoneInDifficulty >= practiceQuestionsPerDifficulty) {
        practiceQuestionsDoneInDifficulty = 0;
        if (practiceDifficulty! < practiceMaxDifficulty) {
          practiceDifficulty = practiceDifficulty! + 1;
        }
      }
    }

    final wrongStreak = wrongStreakBySkill[problem.skill] ?? 0;
    final forcedSkill = wrongStreak >= 2 ? _prereqSkill(problem.skill) : practiceSkill;

    current = recommender.recommend(
      all: problems,
      masteryBySkill: masteryBySkill,
      seenProblemIds: seenProblemIds,
      forcedSkill: forcedSkill,
      forcedDifficulty: practiceDifficulty,
    );
    lastCorrect = null;
    _attemptsOnCurrentProblem = 0;
    notifyListeners();
  }

  int? get questionsLeftInDifficulty {
    if (practiceDifficulty == null) return null;
    final left = practiceQuestionsPerDifficulty - practiceQuestionsDoneInDifficulty;
    return left.clamp(0, practiceQuestionsPerDifficulty).toInt();
  }

  double? get difficultyProgress {
    if (practiceDifficulty == null) return null;
    return (practiceQuestionsDoneInDifficulty / practiceQuestionsPerDifficulty).clamp(0.0, 1.0);
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
    personalBankByUser.clear();

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

  void _persistPersonalBanks() {
    _box.put(
      _personalBankByUserKey,
      personalBankByUser.map((k, v) => MapEntry(k, v.toMap())),
    );
  }

  void _updatePersonalBank(PersonalBank next) {
    personalBankByUser = {...personalBankByUser, _activeUsername: next};
    _persistPersonalBanks();
    notifyListeners();
  }

  Map<String, PersonalBank> _loadPersonalBanks(dynamic raw) {
    if (raw is! Map) return {};
    final result = <String, PersonalBank>{};
    for (final entry in raw.entries) {
      final key = entry.key;
      if (key is! String) continue;
      final value = entry.value;
      if (value is Map) {
        result[key] = PersonalBank.fromMap(Map<String, dynamic>.from(value));
      }
    }
    return result;
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
