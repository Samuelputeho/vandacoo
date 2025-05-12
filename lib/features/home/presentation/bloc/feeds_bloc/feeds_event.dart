part of 'feeds_bloc.dart';

sealed class FeedsEvent extends Equatable {
  const FeedsEvent();

  @override
  List<Object> get props => [];
}

class UploadFeedsPostEvent extends FeedsEvent {
  final String userId;
  final String postType;
  final String caption;
  final String region;
  final String category;
  final File? mediaFile;
  final File? thumbnailFile;
  final int durationDays;
  const UploadFeedsPostEvent({
    required this.userId,
    required this.postType,
    required this.caption,
    required this.region,
    required this.category,
    required this.mediaFile,
    this.thumbnailFile,
    required this.durationDays,
  });

  @override
  List<Object> get props => [
        userId,
        postType,
        caption,
        region,
        category,
        if (mediaFile != null) mediaFile!,
        if (thumbnailFile != null) thumbnailFile!,
        durationDays,
      ];
}
