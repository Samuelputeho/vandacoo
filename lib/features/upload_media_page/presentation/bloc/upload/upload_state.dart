part of 'upload_bloc.dart';

@immutable
sealed class UploadState {}

final class UploadInitial extends UploadState {}

final class UploadPostLoading extends UploadState {}

final class UploadPostSuccess extends UploadState {
  final String message;

  UploadPostSuccess(this.message);
}

final class UploadPostFailure extends UploadState {
  final String message;

  UploadPostFailure(this.message);
}
