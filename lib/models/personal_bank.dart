class PersonalBank {
  const PersonalBank({required this.categories});

  final List<PersonalCategory> categories;

  Map<String, dynamic> toMap() => {
        'categories': categories.map((c) => c.toMap()).toList(growable: false),
      };

  factory PersonalBank.fromMap(Map<String, dynamic> map) {
    final rawCategories = map['categories'];
    final categories = (rawCategories is List ? rawCategories : const <dynamic>[])
        .whereType<Map>()
        .map((row) => PersonalCategory.fromMap(Map<String, dynamic>.from(row)))
        .toList(growable: false);
    return PersonalBank(categories: categories);
  }

  PersonalBank copyWith({List<PersonalCategory>? categories}) {
    return PersonalBank(categories: categories ?? this.categories);
  }
}

class PersonalCategory {
  const PersonalCategory({required this.id, required this.name, required this.questions});

  final String id;
  final String name;
  final List<PersonalQuestion> questions;

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'questions': questions.map((q) => q.toMap()).toList(growable: false),
      };

  factory PersonalCategory.fromMap(Map<String, dynamic> map) {
    final rawQuestions = map['questions'];
    final questions = (rawQuestions is List ? rawQuestions : const <dynamic>[])
        .whereType<Map>()
        .map((row) => PersonalQuestion.fromMap(Map<String, dynamic>.from(row)))
        .toList(growable: false);
    return PersonalCategory(
      id: (map['id'] as String?) ?? '',
      name: (map['name'] as String?) ?? 'Untitled',
      questions: questions,
    );
  }

  PersonalCategory copyWith({String? id, String? name, List<PersonalQuestion>? questions}) {
    return PersonalCategory(
      id: id ?? this.id,
      name: name ?? this.name,
      questions: questions ?? this.questions,
    );
  }
}

class PersonalQuestion {
  const PersonalQuestion({
    required this.id,
    required this.question,
    required this.answer,
    required this.explanation,
    required this.incorrectAnswers,
  });

  final String id;
  final String question;
  final String answer;
  final String explanation;
  final List<String> incorrectAnswers;

  Map<String, dynamic> toMap() => {
        'id': id,
        'question': question,
        'answer': answer,
        'explanation': explanation,
        'incorrectAnswers': incorrectAnswers,
      };

  factory PersonalQuestion.fromMap(Map<String, dynamic> map) {
    final rawIncorrect = map['incorrectAnswers'];
    final incorrectAnswers = (rawIncorrect is List ? rawIncorrect : const <dynamic>[])
        .whereType<String>()
        .map((row) => row.trim())
        .where((row) => row.isNotEmpty)
        .toSet()
        .toList(growable: false);
    return PersonalQuestion(
      id: (map['id'] as String?) ?? '',
      question: (map['question'] as String?) ?? '',
      answer: (map['answer'] as String?) ?? '',
      explanation: (map['explanation'] as String?) ?? '',
      incorrectAnswers: incorrectAnswers,
    );
  }

  PersonalQuestion copyWith({
    String? id,
    String? question,
    String? answer,
    String? explanation,
    List<String>? incorrectAnswers,
  }) {
    return PersonalQuestion(
      id: id ?? this.id,
      question: question ?? this.question,
      answer: answer ?? this.answer,
      explanation: explanation ?? this.explanation,
      incorrectAnswers: incorrectAnswers ?? this.incorrectAnswers,
    );
  }
}
