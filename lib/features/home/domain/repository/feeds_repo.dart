import 'dart:io';

import 'package:fpdart/fpdart.dart' show Either;

import '../../../../core/error/failure.dart' show Failure;

abstract interface class FeedsRepository {
  Future<Either<Failure, void>> uploadPost({
    required String userId,
    required String postType,
    required String caption,
    required String region,
    required String category,
    required int durationDays,
    File? mediaFile,
    File? thumbnailFile,
  });
}
