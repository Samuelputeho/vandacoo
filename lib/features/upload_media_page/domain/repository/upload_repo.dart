import 'dart:io';

import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failure.dart';

abstract interface class UploadRepository {
  Future<Either<Failure, void>> uploadPost({
    required String userId,
    required String postType,
    required String caption,
    required String region,
    required String category,
    File? mediaFile,
    File? thumbnailFile,
  });
}
