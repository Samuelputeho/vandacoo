part of 'upload_bloc.dart';

@immutable
sealed class UploadEvent {}

class UploadPostEvent extends UploadEvent {
  final String userId;
  final String postType;
  final String caption;
  final String region;
  final String category;
  final File? imageFile;
  final String? videoUrl;

  UploadPostEvent({
    required this.userId,
    required this.postType,
    required this.caption,
    required this.region,
    required this.category,
    required this.imageFile,
    required this.videoUrl,
  });
}
