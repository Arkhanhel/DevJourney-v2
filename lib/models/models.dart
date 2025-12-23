class User {
  final String id;
  final String email;
  final String username;
  final String? avatarUrl;
  final DateTime createdAt;
  final DateTime? lastLoginAt;

  User({
    required this.id,
    required this.email,
    required this.username,
    this.avatarUrl,
    required this.createdAt,
    this.lastLoginAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id']?.toString() ?? '',
      email: json['email'] as String? ?? '',
      username: json['username'] as String? ?? '',
      avatarUrl: json['avatarUrl'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      lastLoginAt: json['lastLoginAt'] != null
          ? DateTime.parse(json['lastLoginAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'username': username,
      'avatarUrl': avatarUrl,
      'createdAt': createdAt.toIso8601String(),
      'lastLoginAt': lastLoginAt?.toIso8601String(),
    };
  }
}

class Challenge {
  final String id;
  final String title;
  final String description;
  final String difficulty;
  final List<String> tags;
  final int totalTests;
  final int? completedTests;
  final DateTime createdAt;

  Challenge({
    required this.id,
    required this.title,
    required this.description,
    required this.difficulty,
    required this.tags,
    required this.totalTests,
    this.completedTests,
    required this.createdAt,
  });

  factory Challenge.fromJson(Map<String, dynamic> json) {
    return Challenge(
      id: json['id']?.toString() ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      difficulty: json['difficulty'] as String? ?? 'easy',
      tags: (json['tags'] as List<dynamic>? ?? const []).map((e) => e.toString()).toList(),
      totalTests: json['totalTests'] as int? ?? 0,
      completedTests: json['completedTests'] as int?,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}

class Submission {
  final String id;
  final String challengeId;
  final String userId;
  final String code;
  final String language;
  final String status;
  final int? score;
  final String? errorMessage;
  final DateTime createdAt;

  Submission({
    required this.id,
    required this.challengeId,
    required this.userId,
    required this.code,
    required this.language,
    required this.status,
    this.score,
    this.errorMessage,
    required this.createdAt,
  });

  factory Submission.fromJson(Map<String, dynamic> json) {
    return Submission(
      id: json['id'] as String,
      challengeId: json['challengeId'] as String,
      userId: json['userId'] as String,
      code: json['code'] as String,
      language: json['language'] as String,
      status: json['status'] as String,
      score: json['score'] as int?,
      errorMessage: json['errorMessage'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}

class UserProgress {
  final String userId;
  final int totalPoints;
  final int completedChallenges;
  final int currentStreak;
  final int longestStreak;
  final DateTime lastActivityDate;
  final Map<String, int> skillLevels;

  UserProgress({
    required this.userId,
    required this.totalPoints,
    required this.completedChallenges,
    required this.currentStreak,
    required this.longestStreak,
    required this.lastActivityDate,
    required this.skillLevels,
  });

  factory UserProgress.fromJson(Map<String, dynamic> json) {
    return UserProgress(
      userId: json['userId'] as String,
      totalPoints: json['totalPoints'] as int,
      completedChallenges: json['completedChallenges'] as int,
      currentStreak: json['currentStreak'] as int,
      longestStreak: json['longestStreak'] as int,
      lastActivityDate: DateTime.parse(json['lastActivityDate'] as String),
      skillLevels: Map<String, int>.from(json['skillLevels'] as Map),
    );
  }
}

class Achievement {
  final String id;
  final String title;
  final String description;
  final String iconUrl;
  final int pointsRequired;
  final bool unlocked;
  final DateTime? unlockedAt;

  Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.iconUrl,
    required this.pointsRequired,
    required this.unlocked,
    this.unlockedAt,
  });

  factory Achievement.fromJson(Map<String, dynamic> json) {
    return Achievement(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      iconUrl: json['iconUrl'] as String,
      pointsRequired: json['pointsRequired'] as int,
      unlocked: json['unlocked'] as bool,
      unlockedAt: json['unlockedAt'] != null
          ? DateTime.parse(json['unlockedAt'] as String)
          : null,
    );
  }
}

class ChallengeCategory {
  final String id;
  final String name;
  final String description;
  final String iconUrl;
  final int challengeCount;
  final String difficulty;

  ChallengeCategory({
    required this.id,
    required this.name,
    required this.description,
    required this.iconUrl,
    required this.challengeCount,
    required this.difficulty,
  });

  factory ChallengeCategory.fromJson(Map<String, dynamic> json) {
    return ChallengeCategory(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      iconUrl: json['iconUrl'] as String,
      challengeCount: json['challengeCount'] as int,
      difficulty: json['difficulty'] as String,
    );
  }
}
