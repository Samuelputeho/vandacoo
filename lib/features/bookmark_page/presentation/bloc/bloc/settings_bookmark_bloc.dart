import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:vandacoo/core/usecases/usecase.dart';
import 'package:vandacoo/features/bookmark_page/domain/usecases/r_get_bookmarkedpost_usecase.dart';
import 'package:vandacoo/features/bookmark_page/domain/usecases/r_toggle_bookmarks_usecase.dart';

part 'settings_bookmark_event.dart';
part 'settings_bookmark_state.dart';

class SettingsBookmarkBloc
    extends Bloc<SettingsBookmarkEvent, SettingsBookmarkState> {
  final BookmarkPageToggleBookmarkUseCase _toggleBookmarkUseCase;
  final BookMarkPageGetBookmarkedPostsUseCase _getBookmarkedPostsUseCase;

  SettingsBookmarkBloc({
    required BookmarkPageToggleBookmarkUseCase toggleBookmarkUseCase,
    required BookMarkPageGetBookmarkedPostsUseCase getBookmarkedPostsUseCase,
  })  : _toggleBookmarkUseCase = toggleBookmarkUseCase,
        _getBookmarkedPostsUseCase = getBookmarkedPostsUseCase,
        super(SettingsBookmarkInitial()) {
    on<SettingsToggleBookmarkEvent>(_onToggleBookmark);
    on<SettingsLoadBookmarkedPostsEvent>(_onLoadBookmarkedPosts);
  }

  Future<void> _onToggleBookmark(
    SettingsToggleBookmarkEvent event,
    Emitter<SettingsBookmarkState> emit,
  ) async {
    try {
      emit(SettingsBookmarkLoading());

      final result = await _toggleBookmarkUseCase(
        BookmarkPageToggleBookmarkParams(
          postId: event.postId,
        ),
      );

      await result.fold(
        (failure) async {
          emit(SettingsBookmarkError(failure.message));
        },
        (_) async {
          final bookmarkedPostsResult =
              await _getBookmarkedPostsUseCase(NoParams());

          await bookmarkedPostsResult.fold(
            (failure) async {
              emit(SettingsBookmarkError(failure.message));
            },
            (bookmarkedPosts) async {
              emit(SettingsBookmarkSuccess(
                bookmarkedPostIds: bookmarkedPosts,
              ));
            },
          );
        },
      );
    } catch (e) {
      emit(SettingsBookmarkError(e.toString()));
    }
  }

  Future<void> _onLoadBookmarkedPosts(
    SettingsLoadBookmarkedPostsEvent event,
    Emitter<SettingsBookmarkState> emit,
  ) async {
    try {
      emit(SettingsBookmarkLoading());

      final result = await _getBookmarkedPostsUseCase(NoParams());

      await result.fold(
        (failure) async {
          emit(SettingsBookmarkError(failure.message));
        },
        (bookmarkedPosts) async {
          emit(SettingsBookmarkSuccess(
            bookmarkedPostIds: bookmarkedPosts,
          ));
        },
      );
    } catch (e) {
      emit(SettingsBookmarkError(e.toString()));
    }
  }
}
