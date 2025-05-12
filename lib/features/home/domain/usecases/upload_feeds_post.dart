import 'dart:io';

import 'package:fpdart/fpdart.dart' show Either;

import 'package:vandacoo/core/error/failure.dart';

import '../../../../core/usecases/usecase.dart';
import '../repository/feeds_repo.dart' show FeedsRepository;

class UploadFeedsPostUsecase implements UseCase<void, UploadFeedsPostParams> {
  final FeedsRepository repository;

  UploadFeedsPostUsecase({required this.repository});

  @override
  Future<Either<Failure, void>> call(UploadFeedsPostParams params) async {
    return await repository.uploadPost(
      userId: params.userId,
      postType: params.postType,
      caption: params.caption,
      region: params.region,
      category: params.category,
      durationDays: params.durationDays,
      mediaFile: params.mediaFile,
      thumbnailFile: params.thumbnailFile,
    );
  }
}

class UploadFeedsPostParams {
  final String userId;
  final String postType;
  final String caption;
  final String region;
  final String category;
  final File? mediaFile;
  final File? thumbnailFile;
  final int durationDays;
  UploadFeedsPostParams({
    required this.userId,
    required this.postType,
    required this.caption,
    required this.region,
    required this.category,
    required this.durationDays,
    this.mediaFile,
    this.thumbnailFile,
  });
}
