import 'dart:io';

import 'package:fpdart/fpdart.dart';
import 'package:vandacoo/core/common/entities/user_entity.dart';
import 'package:vandacoo/core/error/failure.dart';

abstract interface class AuthRepository {
  Future<Either<Failure, UserEntity>> signUpWithEmailPassword({
    required String name,
    required String email,
    required String password,
    required String accountType,
    required String gender,
    required String age,
  });

  Future<Either<Failure, void>> logout();
  Future<Either<Failure, UserEntity>> logInWithEmailPassword({
    required String email,
    required String password,
  });

  Future<Either<Failure, UserEntity>> currentUser();
  Future<Either<Failure, List<UserEntity>>> getAllUsers();

  Future<Either<Failure, void>> updateUserProfile({
    String? userId,
    String? name,
    String? email,
    String? bio,
    File? imagePath,
  });

  Future<Either<Failure, void>> updateHasSeenIntroVideo(String userId);
}
