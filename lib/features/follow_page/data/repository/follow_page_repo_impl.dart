import 'package:fpdart/fpdart.dart';
import 'package:vandacoo/features/follow_page/domain/entities/follow_entity.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failure.dart';
import '../../domain/repository/follow_page_repository.dart';
import '../datasource/follow_page_remote_datasource.dart';

class FollowPageRepositoryImpl implements FollowPageRepository {
  final FollowPageRemoteDatasource _remoteDatasource;

  FollowPageRepositoryImpl(this._remoteDatasource);

  @override
  Future<Either<Failure, void>> followUser(
      String followerId, String followingId) async {
    try {
      await _remoteDatasource.followUser(followerId, followingId);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(Failure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> unfollowUser(
      String followerId, String followingId) async {
    try {
      await _remoteDatasource.unfollowUser(followerId, followingId);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(Failure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> isFollowing(
      String followerId, String followingId) async {
    try {
      final isFollowing =
          await _remoteDatasource.isFollowing(followerId, followingId);
      return Right(isFollowing);
    } on ServerException catch (e) {
      return Left(Failure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, FollowEntity>> getUserCounts(String userId) async {
    try {
      final followModel = await _remoteDatasource.getUserCounts(userId);
      return Right(followModel);
    } on ServerException catch (e) {
      return Left(Failure(e.toString()));
    }
  }
}
