import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vandacoo/core/usecase/usecase.dart';
import 'package:vandacoo/features/explore_page/domain/usecases/toggle_bookmark_usecase.dart';
import 'package:vandacoo/features/explore_page/domain/usecases/get_bookmarked_posts_usecase.dart';
import 'explore_bookmark_event.dart';
import 'explore_bookmark_state.dart';

class ExploreBookmarkBloc
    extends Bloc<ExploreBookmarkEvent, Map<String, ExploreBookmarkState>> {
  final ToggleBookmarkUseCase _toggleBookmarkUseCase;
  final GetBookmarkedPostsUseCase _getBookmarkedPostsUseCase;

  ExploreBookmarkBloc({
    required ToggleBookmarkUseCase toggleBookmarkUseCase,
    required GetBookmarkedPostsUseCase getBookmarkedPostsUseCase,
  })  : _toggleBookmarkUseCase = toggleBookmarkUseCase,
        _getBookmarkedPostsUseCase = getBookmarkedPostsUseCase,
        super({}) {
    on<ExploreToggleBookmarkEvent>(_onToggleBookmark);
    on<ExploreLoadBookmarkedPostsEvent>(_onLoadBookmarkedPosts);
  }

  Future<void> _onToggleBookmark(
    ExploreToggleBookmarkEvent event,
    Emitter<Map<String, ExploreBookmarkState>> emit,
  ) async {
    try {
      final newState = Map<String, ExploreBookmarkState>.from(state);
      newState[event.postId] = ExploreBookmarkLoading();
      emit(newState);

      final result = await _toggleBookmarkUseCase(
        ToggleBookmarkParams(
          postId: event.postId,
          userId: event.userId,
        ),
      );

      await result.fold(
        (failure) async {
          newState[event.postId] = ExploreBookmarkError(failure.message);
          emit(newState);
        },
        (_) async {
          final bookmarkedPostsResult =
              await _getBookmarkedPostsUseCase(NoParams());

          await bookmarkedPostsResult.fold(
            (failure) async {
              newState[event.postId] = ExploreBookmarkError(failure.message);
              emit(newState);
            },
            (bookmarkedPosts) async {
              newState[event.postId] = ExploreBookmarkSuccess(
                isBookmarked: bookmarkedPosts.contains(event.postId),
                bookmarkedPostIds: bookmarkedPosts,
              );
              emit(newState);
            },
          );
        },
      );
    } catch (e) {
      final newState = Map<String, ExploreBookmarkState>.from(state);
      newState[event.postId] = ExploreBookmarkError(e.toString());
      emit(newState);
    }
  }

  Future<void> _onLoadBookmarkedPosts(
    ExploreLoadBookmarkedPostsEvent event,
    Emitter<Map<String, ExploreBookmarkState>> emit,
  ) async {
    try {
      final newState = Map<String, ExploreBookmarkState>.from(state);
      final result = await _getBookmarkedPostsUseCase(NoParams());

      await result.fold(
        (failure) async {
          emit({}); // Clear state on error
        },
        (bookmarkedPosts) async {
          for (final postId in bookmarkedPosts) {
            newState[postId] = ExploreBookmarkSuccess(
              isBookmarked: true,
              bookmarkedPostIds: bookmarkedPosts,
            );
          }
          emit(newState);
        },
      );
    } catch (e) {
      emit({}); // Clear state on error
    }
  }
}
