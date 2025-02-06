import 'package:vandacoo/core/common/entities/post_entity.dart';

abstract class SavedPostsState {}

class SavedPostsInitial extends SavedPostsState {}

class SavedPostsLoading extends SavedPostsState {}

class SavedPostsSuccess extends SavedPostsState {
  final List<PostEntity> posts;

  SavedPostsSuccess({
    required this.posts,
  });
}

class SavedPostsFailure extends SavedPostsState {
  final String error;

  SavedPostsFailure(this.error);
}

class SavedPostToggleSuccess extends SavedPostsState {
  final bool isSaved;
  final List<PostEntity> posts;

  SavedPostToggleSuccess({
    required this.isSaved,
    required this.posts,
  });
}

class SavedPostToggleFailure extends SavedPostsState {
  final String error;

  SavedPostToggleFailure(this.error);
}
