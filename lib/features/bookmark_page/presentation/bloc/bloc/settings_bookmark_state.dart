part of 'settings_bookmark_bloc.dart';

abstract class SettingsBookmarkState extends Equatable {
  const SettingsBookmarkState();

  @override
  List<Object> get props => [];
}

class SettingsBookmarkInitial extends SettingsBookmarkState {}

class SettingsBookmarkLoading extends SettingsBookmarkState {}

class SettingsBookmarkSuccess extends SettingsBookmarkState {
  final List<String> bookmarkedPostIds;
  const SettingsBookmarkSuccess({
    required this.bookmarkedPostIds,
  });

  @override
  List<Object> get props => [bookmarkedPostIds];
}

class SettingsBookmarkError extends SettingsBookmarkState {
  final String message;
  const SettingsBookmarkError(this.message);

  @override
  List<Object> get props => [message];
}
