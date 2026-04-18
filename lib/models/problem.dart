class Problem {
  const Problem({
    required this.id,
    required this.skill,
    required this.difficulty,
    required this.question,
    required this.choices,
    required this.answerIndex,
    required this.steps,
  });

  final String id;
  final String skill;
  final int difficulty;
  final String question;
  final List<String> choices;
  final int answerIndex;
  final List<String> steps;

  factory Problem.fromJson(Map<String, dynamic> json) {
    return Problem(
      id: json['id'] as String,
      skill: json['skill'] as String,
      difficulty: json['difficulty'] as int,
      question: json['question'] as String,
      choices: (json['choices'] as List).cast<String>(),
      answerIndex: json['answerIndex'] as int,
      steps: (json['steps'] as List).cast<String>(),
    );
  }
}
