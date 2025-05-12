import 'dart:io';

// ignore: implementation_imports
import 'package:fpdart/src/either.dart';

import 'package:vandacoo/core/error/failure.dart';

import '../../../../core/error/exceptions.dart';
import '../../domain/repository/feeds_repo.dart' show FeedsRepository;
import '../datasource/feeds_remote_datasource.dart' show FeedsRemoteDataSource;

class FeedsRepositoryImpl implements FeedsRepository {
  final FeedsRemoteDataSource remoteDataSource;

  FeedsRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, void>> uploadPost({
    required String userId,
    required String postType,
    required String caption,
    required String region,
    required String category,
    required int durationDays,
    File? mediaFile,
    File? thumbnailFile,
  }) async {
    try {
      await remoteDataSource.uploadPost(
        userId: userId,
        postType: postType,
        caption: caption,
        region: region,
        category: category,
        durationDays: durationDays,
        mediaFile: mediaFile,
        thumbnailFile: thumbnailFile,
      );
      return right(null);
    } on ServerException catch (e) {
      return left(Failure(e.message));
    }
  }
}
