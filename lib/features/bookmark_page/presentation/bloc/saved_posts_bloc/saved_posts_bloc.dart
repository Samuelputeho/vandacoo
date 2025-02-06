import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vandacoo/core/usecases/usecase.dart';
import 'package:vandacoo/core/common/entities/post_entity.dart';
import 'package:vandacoo/features/bookmark_page/domain/usecases/get_saved_posts_usecase.dart';
import 'package:vandacoo/features/bookmark_page/domain/usecases/toggle_saved_post_usecase.dart';
import 'saved_posts_event.dart';
import 'saved_posts_state.dart';

class SavedPostsBloc extends Bloc<SavedPostsEvent, SavedPostsState> {
  final ToggleSavedPostUseCase _toggleSavedPostUseCase;
  final GetSavedPostsUseCase _getSavedPostsUseCase;
  List<PostEntity> _savedPosts = [];

  SavedPostsBloc({
    required ToggleSavedPostUseCase toggleSavedPostUseCase,
    required GetSavedPostsUseCase getSavedPostsUseCase,
  })  : _toggleSavedPostUseCase = toggleSavedPostUseCase,
        _getSavedPostsUseCase = getSavedPostsUseCase,
        super(SavedPostsInitial()) {
    on<ToggleSavedPostEvent>(_onToggleSavedPost);
    on<LoadSavedPostsEvent>(_onLoadSavedPosts);
  }

  Future<void> _onToggleSavedPost(
    ToggleSavedPostEvent event,
    Emitter<SavedPostsState> emit,
  ) async {
    try {
      final isNowSaved = !isPostSaved(event.postId);

      final result = await _toggleSavedPostUseCase(
        ToggleSavedPostParams(postId: event.postId),
      );

      await result.fold(
        (failure) async {
          emit(SavedPostToggleFailure(failure.message));
        },
        (_) async {
          final savedPostsResult = await _getSavedPostsUseCase(NoParams());
          await savedPostsResult.fold(
            (failure) async {
              emit(SavedPostToggleFailure(failure.message));
            },
            (savedPosts) async {
              _savedPosts = savedPosts;
              emit(SavedPostToggleSuccess(
                isSaved: isPostSaved(event.postId),
                posts: _savedPosts,
              ));
            },
          );
        },
      );
    } catch (e) {
      emit(SavedPostToggleFailure(e.toString()));
    }
  }

  Future<void> _onLoadSavedPosts(
    LoadSavedPostsEvent event,
    Emitter<SavedPostsState> emit,
  ) async {
    try {
      emit(SavedPostsLoading());
      final result = await _getSavedPostsUseCase(NoParams());
      await result.fold(
        (failure) async => emit(SavedPostsFailure(failure.message)),
        (savedPosts) async {
          _savedPosts = savedPosts;
          emit(SavedPostsSuccess(posts: _savedPosts));
        },
      );
    } catch (e) {
      emit(SavedPostsFailure(e.toString()));
    }
  }

  bool isPostSaved(String postId) =>
      _savedPosts.any((post) => post.id == postId);
}
