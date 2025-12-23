class User {
  final String id;
  final String email;
  final String username;
  final String? avatarUrl;
  final String role;
  final int totalXp;
  final DateTime createdAt;
  final UserProfile? profile;

  User({
    required this.id,
    required this.email,
    required this.username,
    this.avatarUrl,
    required this.role,
    required this.totalXp,
    required this.createdAt,
    this.profile,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id']?.toString() ?? '',
      email: json['email'] as String? ?? '',
      username: json['username'] as String? ?? '',
      avatarUrl: json['avatarUrl'] as String?,
      role: (json['role'] as String?) ?? 'student',
      totalXp: json['totalXp'] as int? ?? 0,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      profile: json['profile'] != null 
          ? UserProfile.fromJson(json['profile'] as Map<String, dynamic>) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'username': username,
      'avatarUrl': avatarUrl,
      'role': role,
      'totalXp': totalXp,
      'createdAt': createdAt.toIso8601String(),
      'profile': profile?.toJson(),
    };
  }
}

class UserProfile {
  final String id;
  final String userId;
  final int? age;
  final List<String> interests;
  final String preferredLanguage;
  final String skillLevel;
  final String? learningGoals;

  UserProfile({
    required this.id,
    required this.userId,
    this.age,
    required this.interests,
    required this.preferredLanguage,
    required this.skillLevel,
    this.learningGoals,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      userId: json['userId'] as String,
      age: json['age'] as int?,
      interests: (json['interests'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      preferredLanguage: json['preferredLanguage'] as String? ?? 'uk',
      skillLevel: json['skillLevel'] as String? ?? 'BEGINNER',
      learningGoals: json['learningGoals'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'age': age,
      'interests': interests,
      'preferredLanguage': preferredLanguage,
      'skillLevel': skillLevel,
      'learningGoals': learningGoals,
    };
  }
}

class Track {
  final String id;
  final String title;
  final String slug;
  final String description;
  final String? icon;
  final int orderIndex;

  Track({
    required this.id,
    required this.title,
    required this.slug,
    required this.description,
    this.icon,
    required this.orderIndex,
  });

  factory Track.fromJson(Map<String, dynamic> json) {
    return Track(
      id: json['id'] as String,
      title: json['title'] as String,
      slug: json['slug'] as String,
      description: json['description'] as String,
      icon: json['icon'] as String?,
      orderIndex: json['orderIndex'] as int,
    );
  }
}

class Course {
  final String id;
  final String trackId;
  final String title;
  final String slug;
  final String description;
  final String? thumbnail;
  final String level;
  final int orderIndex;
  final int? durationHours;

  Course({
    required this.id,
    required this.trackId,
    required this.title,
    required this.slug,
    required this.description,
    this.thumbnail,
    required this.level,
    required this.orderIndex,
    this.durationHours,
  });

  factory Course.fromJson(Map<String, dynamic> json) {
    return Course(
      id: json['id'] as String,
      trackId: json['trackId'] as String,
      title: json['title'] as String,
      slug: json['slug'] as String,
      description: json['description'] as String,
      thumbnail: json['thumbnail'] as String?,
      level: json['level'] as String,
      orderIndex: json['orderIndex'] as int,
      durationHours: json['durationHours'] as int?,
    );
  }
}

class Challenge {
  final String id;
  final String? lessonId;
  final String title;
  final String description;
  final String? starterCode;
  final String difficulty;
  final int xpReward;
  final int timeLimit;
  final int memoryLimit;

  Challenge({
    required this.id,
    this.lessonId,
    required this.title,
    required this.description,
    this.starterCode,
    required this.difficulty,
    required this.xpReward,
    required this.timeLimit,
    required this.memoryLimit,
  });

  factory Challenge.fromJson(Map<String, dynamic> json) {
    return Challenge(
      id: json['id'] as String,
      lessonId: json['lessonId']?.toString(),
      title: json['title'] as String,
      description: json['description'] as String,
      starterCode: json['starterCode'] as String?,
      difficulty: json['difficulty'] as String,
      xpReward: json['xpReward'] as int,
      timeLimit: json['timeLimit'] as int,
      memoryLimit: json['memoryLimit'] as int,
    );
  }
}

class Submission {
  final String id;
  final String userId;
  final String challengeId;
  final String code;
  final String language;
  final String status;
  final int? score;
  final int? executionTime;
  final String? errorMessage;
  final DateTime createdAt;

  Submission({
    required this.id,
    required this.userId,
    required this.challengeId,
    required this.code,
    required this.language,
    required this.status,
    this.score,
    this.executionTime,
    this.errorMessage,
    required this.createdAt,
  });

  factory Submission.fromJson(Map<String, dynamic> json) {
    return Submission(
      id: json['id'] as String,
      userId: json['userId'] as String,
      challengeId: json['challengeId'] as String,
      code: json['code'] as String,
      language: json['language'] as String,
      status: json['status'] as String,
      score: json['score'] as int?,
      executionTime: json['executionTime'] as int?,
      errorMessage: json['errorMessage'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Submission copyWith({
    String? id,
    String? userId,
    String? challengeId,
    String? code,
    String? language,
    String? status,
    int? score,
    int? executionTime,
    String? errorMessage,
    DateTime? createdAt,
  }) {
    return Submission(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      challengeId: challengeId ?? this.challengeId,
      code: code ?? this.code,
      language: language ?? this.language,
      status: status ?? this.status,
      score: score ?? this.score,
      executionTime: executionTime ?? this.executionTime,
      errorMessage: errorMessage ?? this.errorMessage,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
