import 'package:fpdart/fpdart.dart';
import 'package:vandacoo/core/common/entities/post_entity.dart';
import 'package:vandacoo/core/error/failure.dart';
import '../../../../core/common/entities/user_entity.dart';
import 'dart:io'; // Import for File type

abstract interface class ProfileRepository {
  Future<Either<Failure, List<PostEntity>>> getPostsForUser(String userId);
  Future<Either<Failure, UserEntity>> getUserInformation(String userId);
  
  Future<Either<Failure, void>> editUserInfo({
    required String userId,
    String? propic, // URL of the profile picture
    String? name,
    String? bio,
    String? email,
    File? propicFile, // New parameter to upload the profile picture file
  });
}
