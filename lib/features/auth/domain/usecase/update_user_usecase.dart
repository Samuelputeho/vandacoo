import 'dart:io';


import 'package:fpdart/fpdart.dart';
import 'package:vandacoo/core/error/failure.dart';
import 'package:vandacoo/core/usecase/usecase.dart';
import 'package:vandacoo/features/auth/domain/repository/auth_repository.dart';

class UpdateUserProfile implements UseCase<void, UpdateUserProfileParams> {
  final AuthRepository authRepository;
  const UpdateUserProfile(this.authRepository);

  @override
  Future<Either<Failure, void>> call(UpdateUserProfileParams params) async {
    return await authRepository.updateUserProfile(
      userId: params.userId,
      name: params.name ?? '',
      email: params.email ?? '',
      bio: params.bio ?? '',
      imagePath: params.imagePath ?? File(''),
    );
  }
}

class UpdateUserProfileParams {
  final String userId;
  final String? name;
  final String? email;
  final String? bio;
  final File? imagePath;

  const UpdateUserProfileParams({
    required this.userId,
    this.name,
    this.email,
    this.bio,
    this.imagePath,
  });

  @override
  List<Object?> get props => [userId, name, email, bio, imagePath];
}
