class UserEntity {
  final String name;
  final String propic;
  final String bio;
  final String email;
  final String id;

  UserEntity({
    required this.name,
    this.propic = '',
    required this.bio,
    required this.email,
    required this.id,
  });
}
