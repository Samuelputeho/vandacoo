import 'package:fpdart/fpdart.dart';
import 'package:vandacoo/core/common/entities/user_entity.dart';
import 'package:vandacoo/core/error/failure.dart';
import 'package:vandacoo/core/usecase/usecase.dart';
import 'package:vandacoo/features/auth/domain/repository/auth_repository.dart';

class UserSignUp implements UseCase<UserEntity, UserSignUpParams> {
  final AuthRepository authRepository;
  const UserSignUp(this.authRepository);
  @override
  Future<Either<Failure, UserEntity>> call(UserSignUpParams params) async {
    return await authRepository.signUpWithEmailPassword(
      name: params.name,
      email: params.email,
      password: params.password,
      accountType: params.accountType,
      gender: params.gender,
      age: params.age,
    );
  }
}

class UserSignUpParams {
  final String email;
  final String password;
  final String name;
  final String accountType;
  final String gender;
  final String age;
  UserSignUpParams({
    required this.password,
    required this.name,
    required this.email,
    required this.accountType,
    required this.gender,
    required this.age,
  });
}
