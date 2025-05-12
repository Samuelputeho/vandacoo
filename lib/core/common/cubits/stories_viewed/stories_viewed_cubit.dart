import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vandacoo/core/common/global_comments/presentation/bloc/global_comments/global_comments_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StoriesViewedCubit extends Cubit<Set<String>> {
  String? _currentUserId;
  final SharedPreferences _prefs;
  final GlobalCommentsBloc globalCommentsBloc;

  StoriesViewedCubit({
    required this.globalCommentsBloc,
    required SharedPreferences prefs,
  })  : _prefs = prefs,
        super({}) {
    _loadViewedStories();
  }

  void setCurrentUser(String userId) {
    _currentUserId = userId;
    _loadViewedStories();
  }

  void _loadViewedStories() {
    if (_currentUserId == null) return;
    final key = 'viewed_stories_$_currentUserId';
    final viewedStories = _prefs.getStringList(key) ?? [];
    emit(Set.from(viewedStories));
  }

  void _saveViewedStories() {
    if (_currentUserId == null) return;
    final key = 'viewed_stories_$_currentUserId';
    _prefs.setStringList(key, state.toList());
  }

  void markStoryAsViewed(String storyId) {
    if (_currentUserId == null) {
      return;
    }

    final newState = Set<String>.from(state)..add(storyId);
    emit(newState);
    _saveViewedStories();

    // Persist to database via GlobalCommentsBloc
    globalCommentsBloc.add(MarkStoryAsViewedEvent(
      storyId: storyId,
      userId: _currentUserId!,
    ));
  }

  void removeStory(String storyId) {
    final newState = Set<String>.from(state)..remove(storyId);
    emit(newState);
    _saveViewedStories();
  }

  bool isStoryViewed(String storyId) {
    return state.contains(storyId);
  }

  void clearViewedStories() {
    emit({});
  }

  // Method to initialize viewed stories from database
  void initializeFromDatabase(List<String> viewedStoryIds) {
    final newState = Set<String>.from(state)..addAll(viewedStoryIds);

    emit(newState);
    _saveViewedStories();
  }
}
