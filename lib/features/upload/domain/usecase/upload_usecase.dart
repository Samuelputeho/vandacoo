import 'dart:io';

import 'package:fpdart/fpdart.dart';
import 'package:vandacoo/core/error/failure.dart';

import '../../../../core/usecase/usecase.dart';
import '../repository/upload_repo.dart';

class UploadUseCase implements UseCase<void, UploadParams> {
  final UploadRepository uploadRepository;

  UploadUseCase(this.uploadRepository);

  @override
  Future<Either<Failure, void>> call(UploadParams params) async {
    return await uploadRepository.uploadPost(
      userId: params.userId,
      postType: params.postType,
      caption: params.caption,
      region: params.region,
      category: params.category,
      mediaFile: params.mediaFile,
    );
  }
}

class UploadParams {
  final String userId;
  final String postType;
  final String caption;
  final String region;
  final String category;
  final File? mediaFile;

  UploadParams({
    required this.userId,
    required this.postType,
    required this.caption,
    required this.region,
    required this.category,
    required this.mediaFile,
  });
}
