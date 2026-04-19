import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'dart:convert';

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

  static const int baseXpDelta = 10;

  Problem? current;
  bool? lastCorrect;

  String? practiceSkill;
  int? practiceDifficulty;
  int practiceQuestionsDoneInDifficulty = 0;
  int practiceQuestionsPerDifficulty = 5;
  int practiceMaxDifficulty = 3;

  int _attemptsOnCurrentProblem = 0;

  Subject subject = Subject.math;

  List<Problem> get activeProblems =>
      problems.where((p) => p.subject == subject).toList(growable: false);

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

    _migrateSubjectQuestionsToSections();

    xp = (_box.get(_xpKey, defaultValue: 0) as int);
    streak = (_box.get(_streakKey, defaultValue: 0) as int);

    current = recommender.recommend(
      all: activeProblems,
      masteryBySkill: masteryBySkill,
      seenProblemIds: seenProblemIds,
    );

    notifyListeners();
  }

  void _migrateSubjectQuestionsToSections() {
    var changed = false;

    final next = <String, PersonalBank>{};
    for (final entry in personalBankByUser.entries) {
      final bank = entry.value;
      final categories = <PersonalCategory>[];

      for (final category in bank.categories) {
        if (category.questions.isEmpty) {
          categories.add(category);
          continue;
        }

        changed = true;
        final section = PersonalSection(
          id: DateTime.now().microsecondsSinceEpoch.toString(),
          name: 'General',
          questions: category.questions,
        );

        categories.add(
          category.copyWith(
            questions: const [],
            sections: [...category.sections, section],
          ),
        );
      }

      next[entry.key] = bank.copyWith(categories: categories);
    }

    if (!changed) return;
    personalBankByUser = next;
    _persistPersonalBanks();
  }

  PersonalBank get personalBank {
    final username = _activeUsername;
    return personalBankByUser[username] ?? const PersonalBank(categories: []);
  }

  List<PersonalCategory> get personalCategories => personalBank.categories;

  String? createPersonalCategory(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return null;

    final category = PersonalCategory(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      name: trimmed,
      questions: const [],
    );

    _updatePersonalBank(
      personalBank.copyWith(categories: [...personalCategories, category]),
    );
    return category.id;
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

  static const _packPrefix = 'RGVTUTOR1:';

  String exportCategoryPack(String categoryId) {
    final category = personalCategories.where((c) => c.id == categoryId).firstOrNull;
    if (category == null) return '';
    final map = category.toMap();
    map.remove('id');
    final raw = jsonEncode(map);
    final encoded = base64UrlEncode(utf8.encode(raw));
    return '$_packPrefix$encoded';
  }

  String? importCategoryPack(String data) {
    final trimmed = data.trim();
    if (!trimmed.startsWith(_packPrefix)) return null;
    final payload = trimmed.substring(_packPrefix.length);

    Map<String, dynamic> decoded;
    try {
      decoded = jsonDecode(utf8.decode(base64Url.decode(payload))) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }

    final packId = payload;
    final category = PersonalCategory.fromMap({
      'id': DateTime.now().microsecondsSinceEpoch.toString(),
      ...decoded,
      'imported': true,
      'editUnlocked': false,
      'packId': packId,
    });

    _updatePersonalBank(
      personalBank.copyWith(categories: [...personalCategories, category]),
    );
    return category.id;
  }

  void unlockPersonalCategoryEditing(String categoryId) {
    final categories = personalCategories
        .map((c) => c.id == categoryId ? c.copyWith(editUnlocked: true) : c)
        .toList(growable: false);
    _updatePersonalBank(personalBank.copyWith(categories: categories));
  }

  void createPersonalQuestion({
    required String categoryId,
    required String question,
    required String answer,
    required String explanation,
    required List<String> incorrectAnswers,
  }) {
    return;
  }

  String? createPersonalSection({required String categoryId, required String name}) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return null;

    final section = PersonalSection(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      name: trimmed,
      questions: const [],
    );

    final categories = personalCategories.map((c) {
      if (c.id != categoryId) return c;
      return c.copyWith(sections: [...c.sections, section]);
    }).toList(growable: false);

    _updatePersonalBank(personalBank.copyWith(categories: categories));
    return section.id;
  }

  void renamePersonalSection({required String categoryId, required String sectionId, required String name}) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;

    final categories = personalCategories.map((c) {
      if (c.id != categoryId) return c;
      final sections = c.sections
          .map((s) => s.id == sectionId ? s.copyWith(name: trimmed) : s)
          .toList(growable: false);
      return c.copyWith(sections: sections);
    }).toList(growable: false);

    _updatePersonalBank(personalBank.copyWith(categories: categories));
  }

  void deletePersonalSection({required String categoryId, required String sectionId}) {
    final categories = personalCategories.map((c) {
      if (c.id != categoryId) return c;
      final sections = c.sections.where((s) => s.id != sectionId).toList(growable: false);
      return c.copyWith(sections: sections);
    }).toList(growable: false);

    _updatePersonalBank(personalBank.copyWith(categories: categories));
  }

  void createSectionQuestion({
    required String categoryId,
    required String sectionId,
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
      final sections = c.sections.map((s) {
        if (s.id != sectionId) return s;
        return s.copyWith(questions: [...s.questions, next]);
      }).toList(growable: false);
      return c.copyWith(sections: sections);
    }).toList(growable: false);

    _updatePersonalBank(personalBank.copyWith(categories: categories));
  }

  void deleteSectionQuestion({required String categoryId, required String sectionId, required String questionId}) {
    final categories = personalCategories.map((c) {
      if (c.id != categoryId) return c;
      final sections = c.sections.map((s) {
        if (s.id != sectionId) return s;
        return s.copyWith(questions: s.questions.where((q) => q.id != questionId).toList(growable: false));
      }).toList(growable: false);
      return c.copyWith(sections: sections);
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
    return;
  }

  void deletePersonalQuestion({required String categoryId, required String questionId}) {
    return;
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

    practiceSkill = null;
    practiceDifficulty = null;
    practiceQuestionsDoneInDifficulty = 0;
    lastCorrect = null;
    _attemptsOnCurrentProblem = 0;
    current = recommender.recommend(
      all: activeProblems,
      masteryBySkill: masteryBySkill,
      seenProblemIds: seenProblemIds,
    );

    notifyListeners();
  }

  List<String> get skills {
    final unique = activeProblems.map((p) => p.skill).toSet();

    if (subject == Subject.math) {
      const preferred = [
        'Elementary',
        'Middle School',
        'Integers',
        'Fractions',
        'Ratios & Proportions',
        'Pre-Algebra',
        'Algebra 1',
        'Equations',
        'Geometry',
        'Algebra 2',
        'Precalculus',
        'Calculus',
      ];

      final minDifficultyBySkill = <String, int>{};
      for (final problem in activeProblems) {
        final prev = minDifficultyBySkill[problem.skill];
        if (prev == null || problem.difficulty < prev) {
          minDifficultyBySkill[problem.skill] = problem.difficulty;
        }
      }

      final list = unique.toList(growable: false);
      list.sort((a, b) {
        final preferredA = preferred.indexOf(a);
        final preferredB = preferred.indexOf(b);
        if (preferredA != -1 || preferredB != -1) {
          if (preferredA == -1) return 1;
          if (preferredB == -1) return -1;
          final cmp = preferredA.compareTo(preferredB);
          if (cmp != 0) return cmp;
        }

        final da = minDifficultyBySkill[a] ?? 999;
        final db = minDifficultyBySkill[b] ?? 999;
        final cmp = da.compareTo(db);
        if (cmp != 0) return cmp;
        return a.compareTo(b);
      });
      return list;
    }

    final list = unique.toList(growable: false);
    list.sort();
    return list;
  }

  double masteryFor(String skill) => (masteryBySkill[skill] ?? 0.0).clamp(0.0, 1.0);

  double completionForSkill(String skill) {
    final pool = activeProblems.where((p) => p.skill == skill).toList(growable: false);
    if (pool.isEmpty) return 0.0;
    final seen = pool.where((p) => seenProblemIds.contains(p.id)).length;
    return (seen / pool.length).clamp(0.0, 1.0);
  }

  double progressForSkillDifficulty(String skill, int difficulty) {
    final pool = activeProblems
        .where((p) => p.skill == skill && p.difficulty == difficulty)
        .toList(growable: false);
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
      all: activeProblems,
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
      all: activeProblems,
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
        xp += _xpGainForStreak(streak);
      } else {
        wrongStreakBySkill[problem.skill] = (wrongStreakBySkill[problem.skill] ?? 0) + 1;
        streak = 0;
        xp = (xp - baseXpDelta).clamp(0, 1 << 30).toInt();
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
      all: activeProblems,
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

  Future<void> resetProgress({Subject? subject}) async {
    final target = subject;
    if (target == null) {
      masteryBySkill.clear();
      seenProblemIds.clear();
      wrongStreakBySkill.clear();
      xp = 0;
      streak = 0;
      lastCorrect = null;
      practiceSkill = null;
      practiceDifficulty = null;
      practiceQuestionsDoneInDifficulty = 0;
      _attemptsOnCurrentProblem = 0;

      await _box.delete(_masteryKey);
      await _box.delete(_seenKey);
      await _box.delete(_wrongStreakBySkillKey);
      await _box.delete(_xpKey);
      await _box.delete(_streakKey);
    } else {
      final targetSkills = problems
          .where((p) => p.subject == target)
          .map((p) => p.skill)
          .toSet();

      masteryBySkill.removeWhere((skill, _) => targetSkills.contains(skill));
      wrongStreakBySkill.removeWhere((skill, _) => targetSkills.contains(skill));
      seenProblemIds.removeWhere((id) => problems.any((p) => p.id == id && p.subject == target));

      lastCorrect = null;
      practiceSkill = null;
      practiceDifficulty = null;
      practiceQuestionsDoneInDifficulty = 0;
      _attemptsOnCurrentProblem = 0;

      _persist();
    }

    current = recommender.recommend(
      all: activeProblems,
      masteryBySkill: masteryBySkill,
      seenProblemIds: seenProblemIds,
    );
    notifyListeners();
  }

  int _xpGainForStreak(int streak) {
    final bonusSteps = (streak - 1).clamp(0, 10);
    final streakBonus = bonusSteps * 2;
    return baseXpDelta + streakBonus;
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
      all: activeProblems,
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
