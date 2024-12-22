class UserEntity {
  final String name;
  final String propic;
  final String bio;
  final String email;
  final String id;
  final bool hasSeenIntroVideo;

  UserEntity({
    required this.name,
    this.propic = '',
    required this.bio,
    required this.email,
    required this.id,
    this.hasSeenIntroVideo = false,
  });
}
