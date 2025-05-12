part of 'edit_user_info_bloc.dart';

sealed class EditUserInfoEvent extends Equatable {
  const EditUserInfoEvent();

  @override
  List<Object?> get props => [];
}

final class UpdateUserInfoEvent extends EditUserInfoEvent {
  final String userId;
            // URL of the profile picture (if updating)
  final String? name;
  final String? bio;
  final String? email;
  final File? propicFile;        // New file for the profile picture (if selected)

  const UpdateUserInfoEvent({
    required this.userId,
    
    this.name,
    this.bio,
    this.email,
    this.propicFile,  // Allow passing the selected profile image file
  });

  @override
  List<Object?> get props => [userId, name, bio, email, propicFile];
}
