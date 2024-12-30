part of 'auth_bloc.dart';

@immutable
sealed class AuthEvent {}

final class AuthSignUp extends AuthEvent {
  final String name;
  final String password;
  final String email;
  final String accountType;
  final String gender;
  final String age;
  AuthSignUp({
    required this.name,
    required this.password,
    required this.email,
    required this.accountType,
    required this.gender,
    required this.age,
  });
}

final class AuthLogin extends AuthEvent {
  final String email;
  final String password;

  AuthLogin({
    required this.email,
    required this.password,
  });
}

final class AuthIsUserLoggedIn extends AuthEvent {}

final class AuthGetAllUsers extends AuthEvent {}

final class AuthLogout extends AuthEvent {}

final class AuthUpdateProfile extends AuthEvent {
  final String userId;
  final String? name;
  final String? email;
  final String? bio;
  final File? imagePath;

  AuthUpdateProfile({
    required this.userId,
    this.name,
    this.email,
    this.bio,
    this.imagePath,
  });
}

final class AuthUpdateHasSeenVideo extends AuthEvent {
  final String userId;

  AuthUpdateHasSeenVideo({required this.userId});
}
