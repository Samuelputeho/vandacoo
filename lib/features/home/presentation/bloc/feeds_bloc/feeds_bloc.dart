import 'dart:io';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../domain/usecases/upload_feeds_post.dart';

part 'feeds_event.dart';
part 'feeds_state.dart';

class FeedsBloc extends Bloc<FeedsEvent, FeedsState> {
  final UploadFeedsPostUsecase _uploadFeedsPostUsecase;

  FeedsBloc({
    required UploadFeedsPostUsecase uploadFeedsPostUsecase,
  })  : _uploadFeedsPostUsecase = uploadFeedsPostUsecase,
        super(FeedsInitial()) {
    on<UploadFeedsPostEvent>(_onUploadFeedsPost);
  }

  Future<void> _onUploadFeedsPost(
    UploadFeedsPostEvent event,
    Emitter<FeedsState> emit,
  ) async {
    emit(FeedsPostLoading());

    final result = await _uploadFeedsPostUsecase(
      UploadFeedsPostParams(
        userId: event.userId,
        postType: event.postType,
        caption: event.caption,
        region: event.region,
        category: 'Feeds',
        mediaFile: event.mediaFile,
        thumbnailFile: event.thumbnailFile,
        durationDays: event.durationDays,
      ),
    );

    result.fold(
      (failure) => emit(FeedsPostFailure(failure.message)),
      (_) => emit(const FeedsPostSuccess('Post uploaded successfully')),
    );
  }
}
