import 'dart:io';

import 'package:fpdart/fpdart.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vandacoo/core/common/entities/user_entity.dart';
import 'package:vandacoo/core/error/exceptions.dart';
import 'package:vandacoo/core/error/failure.dart';
import 'package:vandacoo/core/common/widgets/error_utils.dart';
import 'package:vandacoo/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:vandacoo/features/auth/domain/repository/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;
  const AuthRepositoryImpl(this.remoteDataSource);
  @override
  Future<Either<Failure, bool>> checkUserStatus(String userId) async {
    try {
      final result = await remoteDataSource.checkUserStatus(userId);
      return right(result);
    } on ServerException catch (e) {
      return left(Failure(e.message));
    }
  }

  @override
  Future<Either<Failure, UserEntity>> currentUser() async {
    try {
      final user = await remoteDataSource.getCurrentUserData();

      if (user == null) {
        return left(Failure('User not logged in!'));
      }
      return right(user);
    } on ServerException catch (e) {
      // Check if this is a network error - if so, don't treat as auth failure
      if (ErrorUtils.isNetworkError(e.message)) {
        return left(Failure(
            'Network connection issue. Please check your internet connection and try again.'));
      }
      return left(Failure(e.message));
    } catch (e) {
      // Handle other types of exceptions (SocketException, etc.)
      if (ErrorUtils.isNetworkError(e.toString())) {
        return left(Failure(
            'Network connection issue. Please check your internet connection and try again.'));
      }
      return left(Failure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> logout() async {
    try {
      await remoteDataSource.logout();
      return right(null);
    } on ServerException catch (e) {
      return left(Failure(e.message));
    }
  }

  @override
  Future<Either<Failure, UserEntity>> logInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    return _getUser(
      () async => await remoteDataSource.logInWithEmailPassword(
        email: email,
        password: password,
      ),
    );
  }

  @override
  Future<Either<Failure, UserEntity>> signUpWithEmailPassword({
    required String name,
    required String email,
    required String password,
    required String accountType,
    required String gender,
    required String age,
  }) async {
    return _getUser(
      () async => await remoteDataSource.signUpWithEmailPassword(
        name: name,
        email: email,
        password: password,
        accountType: accountType,
        gender: gender,
        age: age,
      ),
    );
  }

  Future<Either<Failure, UserEntity>> _getUser(
    Future<UserEntity> Function() fn,
  ) async {
    try {
      final user = await fn();
      return right(user);
    } on AuthException catch (e) {
      return left(Failure(e.message));
    } on ServerException catch (e) {
      return left(Failure(e.message));
    }
  }

  @override
  Future<Either<Failure, List<UserEntity>>> getAllUsers() async {
    try {
      final users = await remoteDataSource.getAllUsers();
      return right(users);
    } on ServerException catch (e) {
      return left(Failure(e.message));
    }
  }

  @override
  Future<Either<Failure, void>> updateUserProfile({
    String? userId,
    String? name,
    String? email,
    String? bio,
    File? imagePath,
  }) async {
    try {
      await remoteDataSource.updateUserProfile(
        userId: userId ?? '',
        email: email ?? '',
        name: name ?? '',
        bio: bio ?? '',
        imagePath: imagePath ?? File(''),
      );
      return right(null);
    } on ServerException catch (e) {
      print('Repository Error: ${e.message}');
      return left(Failure(e.message));
    } catch (e) {
      print('Unexpected Error: $e');
      return left(Failure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateHasSeenIntroVideo(String userId) async {
    try {
      await remoteDataSource.updateHasSeenIntroVideo(userId);
      return right(null);
    } on ServerException catch (e) {
      return left(Failure(e.message));
    }
  }

  @override
  Future<Either<Failure, void>> sendPasswordResetToken({
    required String email,
  }) async {
    try {
      await remoteDataSource.sendPasswordResetToken(email: email);
      return right(null);
    } on ServerException catch (e) {
      return left(Failure(e.message));
    }
  }

  @override
  Future<Either<Failure, void>> resetPasswordWithToken({
    required String email,
    required String token,
    required String newPassword,
  }) async {
    try {
      await remoteDataSource.resetPasswordWithToken(
        email: email,
        token: token,
        newPassword: newPassword,
      );
      return right(null);
    } on ServerException catch (e) {
      return left(Failure(e.message));
    }
  }
}
