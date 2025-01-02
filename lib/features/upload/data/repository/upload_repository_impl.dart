import 'dart:io';

import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failure.dart';
import '../datasource/upload_remote_datasource.dart';
import '../../domain/repository/upload_repo.dart';

class UploadRepositoryImpl implements UploadRepository {
  final UploadRemoteDataSource uploadRemoteDataSource;

  UploadRepositoryImpl(this.uploadRemoteDataSource);

  @override
  Future<Either<Failure, void>> uploadPost(
      {required String userId,
      required String postType,
      required String caption,
      required String region,
      required String category,
      File? imageFile,
      String? videoUrl}) async {
    try {
      return right(await uploadRemoteDataSource.uploadPost(
        userId: userId,
        postType: postType,
        caption: caption,
        region: region,
        category: category,
        imageFile: imageFile,
        videoUrl: videoUrl,
      ));
    } catch (e) {
      return left(
        Failure(
          e.toString(),
        ),
      );
    }
  }
}
