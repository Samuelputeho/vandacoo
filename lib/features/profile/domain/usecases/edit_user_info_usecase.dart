import 'dart:io'; // Import to handle File type
import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/usecase/usecase.dart';
import '../repository/profile_repository.dart';

class EditUserInfoUsecase implements UseCase<void, EditUserInfoParams> {
  final ProfileRepository profileRepository;

  EditUserInfoUsecase({required this.profileRepository});

  @override
  Future<Either<Failure, void>> call(EditUserInfoParams params) async {
    return profileRepository.editUserInfo(
      userId: params.userId,
      name: params.name,
      bio: params.bio,
      email: params.email,
      propicFile: params.propicFile, // File can be passed here
    );
  }
}

class EditUserInfoParams {
  final String userId;
  final String? name;
  final String? bio;
  final String? email;
  final File? propicFile; // File for the new profile picture to be uploaded

  EditUserInfoParams({
    required this.userId,
    this.name,
    this.bio,
    this.email,
    this.propicFile,  // Allow passing the file for profile picture
  });
}
