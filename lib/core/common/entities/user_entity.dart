class UserEntity {
  final String name;
  final String propic;
  final String bio;
  final String email;
  final String id;
  final String accountType;
  final String gender;
  final String age;
  final bool hasSeenIntroVideo;

  UserEntity({
    required this.name,
    this.propic = '',
    required this.bio,
    required this.email,
    required this.id,
    this.hasSeenIntroVideo = false,
    required this.accountType,
    required this.gender,
    required this.age,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'name': name,
        'bio': bio,
        'propic': propic,
        'hasSeenIntroVideo': hasSeenIntroVideo,
        'accountType': accountType,
        'gender': gender,
        'age': age,
      };
}
