part of 'post_bloc.dart';

@immutable
sealed class PostState {}

final class PostInitial extends PostState {}

final class PostLoading extends PostState {}

final class PostFailure extends PostState {
  final String error;

  PostFailure(this.error);
}

final class PostSuccess extends PostState {}

final class PostDisplaySuccess extends PostState {
  final List<PostEntity> posts;

  PostDisplaySuccess(this.posts);
}
