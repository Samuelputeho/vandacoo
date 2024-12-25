import 'package:vandacoo/core/common/entities/user_entity.dart';

class UserModel extends UserEntity {
  UserModel({
    required super.name,
    required super.email,
    required super.id,
    required super.propic,
    required super.bio,
    super.hasSeenIntroVideo,
  });

  factory UserModel.fromJson(Map<String, dynamic> map) {
    return UserModel(
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      id: map['id'] ?? '',
      propic: map['propic'] ?? '',
      bio: map['bio'] ?? '',
      hasSeenIntroVideo: map['has_seen_intro_video'] ?? false,
    );
  }
  @override
  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'name': name,
        'bio': bio,
        'propic': propic,
        'has_seen_intro_video': hasSeenIntroVideo,
      };
  UserModel copyWith({
    String? id,
    String? email,
    String? name,
    String? propic,
    String? bio,
    bool? hasSeenIntroVideo,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      propic: propic ?? this.propic,
      bio: bio ?? this.bio,
      hasSeenIntroVideo: hasSeenIntroVideo ?? this.hasSeenIntroVideo,
    );
  }
}
