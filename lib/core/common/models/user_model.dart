import 'package:vandacoo/core/common/entities/user_entity.dart';

class UserModel extends UserEntity {
  UserModel({
    required super.name,
    required super.email,
    required super.id,
    required super.propic,
    required super.bio,
    required super.accountType,
    required super.gender,
    required super.age,
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
      accountType: map['account_type'] ?? '',
      gender: map['gender'] ?? '',
      age: map['age'] ?? '',
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
        'account_type': accountType,
        'gender': gender,
        'age': age,
      };
  UserModel copyWith({
    String? id,
    String? email,
    String? name,
    String? propic,
    String? bio,
    bool? hasSeenIntroVideo,
    String? accountType,
    String? gender,
    String? age,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      propic: propic ?? this.propic,
      bio: bio ?? this.bio,
      hasSeenIntroVideo: hasSeenIntroVideo ?? this.hasSeenIntroVideo,
      accountType: accountType ?? this.accountType,
      gender: gender ?? this.gender,
      age: age ?? this.age,
    );
  }
}
