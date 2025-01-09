import 'dart:io';

import 'package:bloc/bloc.dart';
import 'package:flutter/material.dart';

import '../../../domain/usecase/upload_usecase.dart';

part 'upload_event.dart';
part 'upload_state.dart';

class UploadBloc extends Bloc<UploadEvent, UploadState> {
  final UploadUseCase _uploadUseCase;

  UploadBloc({
    required UploadUseCase uploadUseCase,
  })  : _uploadUseCase = uploadUseCase,
        super(UploadInitial()) {
    on<UploadEvent>((event, emit) {});
    on<UploadPostEvent>(_onUploadPost);
  }

  Future<void> _onUploadPost(
      UploadPostEvent event, Emitter<UploadState> emit) async {
    emit(UploadPostLoading());
    final result = await _uploadUseCase(UploadParams(
      userId: event.userId,
      postType: event.postType,
      caption: event.caption,
      region: event.region,
      category: event.category,
      mediaFile: event.mediaFile,
    ));

    result.fold(
      (failure) => emit(UploadPostFailure(failure.message)),
      (success) => emit(UploadPostSuccess('Post uploaded successfully')),
    );
  }
}
