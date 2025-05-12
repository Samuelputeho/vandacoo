part of 'settings_bookmark_bloc.dart';

abstract class SettingsBookmarkEvent extends Equatable {
  const SettingsBookmarkEvent();

  @override
  List<Object> get props => [];
}

class SettingsToggleBookmarkEvent extends SettingsBookmarkEvent {
  final String postId;

  const SettingsToggleBookmarkEvent({
    required this.postId,
  });

  @override
  List<Object> get props => [postId];
}

class SettingsLoadBookmarkedPostsEvent extends SettingsBookmarkEvent {}
