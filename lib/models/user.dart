class AppUser {
  const AppUser({
    required this.name,
    required this.username,
    required this.password,
    required this.age,
    required this.gradeLevel,
    required this.isGuest,
  });

  final String name;
  final String username;
  final String password;
  final int age;
  final String gradeLevel;
  final bool isGuest;

  factory AppUser.guest() => const AppUser(
        name: 'Guest',
        username: '__guest__',
        password: '',
        age: 0,
        gradeLevel: '',
        isGuest: true,
      );

  Map<String, dynamic> toMap() => {
        'name': name,
        'username': username,
        'password': password,
        'age': age,
        'gradeLevel': gradeLevel,
        'isGuest': isGuest,
      };

  static AppUser fromMap(Map<String, dynamic> map) => AppUser(
        name: (map['name'] as String?) ?? '',
        username: (map['username'] as String?) ?? '',
        password: (map['password'] as String?) ?? '',
        age: (map['age'] as int?) ?? 0,
        gradeLevel: (map['gradeLevel'] as String?) ?? '',
        isGuest: (map['isGuest'] as bool?) ?? false,
      );
}
