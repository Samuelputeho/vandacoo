import 'package:fpdart/fpdart.dart';
import 'package:vandacoo/core/common/entities/user_entity.dart';
import 'package:vandacoo/core/error/failure.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/common/models/post_model.dart';
import '../../domain/repository/profile_repository.dart';
import '../datasource/profile_remote_datasource.dart';
import 'dart:io';

class ProfileRepositoryImpl implements ProfileRepository {
  final ProfileRemoteDatasource remoteDatasource;

  ProfileRepositoryImpl({required this.remoteDatasource});

  @override
  Future<Either<Failure, List<PostModel>>> getPostsForUser(String userId) async {
    try {
      final posts = await remoteDatasource.getPostsForUser(userId);
      return Right(posts);
    } on ServerException catch (e) {
      return Left(Failure(e.message));
    } catch (e) {
      return Left(Failure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, UserEntity>> getUserInformation(String userId) async {
    try {
      final user = await remoteDatasource.getUserInformation(userId);
      return Right(user);
    } on ServerException catch (e) {
      return Left(Failure(e.message));
    } catch (e) {
      return Left(Failure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> editUserInfo({
    required String userId,
    String? propic,
    String? name,
    String? bio,
    String? email,
    File? propicFile,
  }) async {
    try {
      print('Repository: Updating user profile...');
      await remoteDatasource.editUserInfo(
        userId: userId,
        
        name: name,
        bio: bio,
        email: email,
        propicFile: propicFile,
      );
      print('Repository: Profile update completed.');
      return const Right(null);
    } on ServerException catch (e) {
      return Left(Failure(e.message));
    } catch (e) {
      return Left(Failure(e.toString()));
    }
  }
}
