enum Subject {
  math('math'),
  reading('reading'),
  science('science'),
  history('history');

  const Subject(this.id);

  final String id;
}

extension SubjectX on Subject {
  static Subject fromId(String id) {
    for (final subject in Subject.values) {
      if (subject.id == id) return subject;
    }
    return Subject.math;
  }

  String get label {
    switch (this) {
      case Subject.math:
        return 'Math';
      case Subject.reading:
        return 'Reading / Writing';
      case Subject.science:
        return 'Science';
      case Subject.history:
        return 'History';
    }
  }
}
