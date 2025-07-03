import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vandacoo/core/common/entities/comment_entity.dart';
import 'package:vandacoo/core/common/entities/post_entity.dart';
import 'package:vandacoo/core/common/global_comments/domain/usecases/add_comment_usecase.dart';
import 'package:vandacoo/core/common/global_comments/domain/usecases/delete_comment_usecase.dart';
import 'package:vandacoo/core/common/global_comments/domain/usecases/get_all_comments_usecase.dart';
import 'package:vandacoo/core/common/global_comments/domain/usecases/get_all_posts_usecase.dart';
import 'package:vandacoo/core/common/global_comments/domain/usecases/get_comment_usecase.dart';
import 'package:vandacoo/core/common/global_comments/domain/usecases/global_toggle_bookmark.dart';
import 'package:vandacoo/core/common/global_comments/domain/usecases/reporting.dart';
import 'package:vandacoo/core/common/global_comments/domain/usecases/toggle_like.dart';
import 'package:vandacoo/core/common/global_comments/domain/usecases/update_post_caption_usecase.dart';
import 'package:vandacoo/core/common/global_comments/domain/usecases/viewd_stories_usecase.dart';
import 'package:vandacoo/core/usecases/usecase.dart';

import '../../../domain/usecases/delete_post_usecase.dart';
import '../../../domain/usecases/mark_story_viewed_usecase.dart';

part 'global_comments_event.dart';
part 'global_comments_state.dart';

// Add new states for story view
class GlobalStoryViewSuccess extends GlobalCommentsState {
  const GlobalStoryViewSuccess();
}

class GlobalStoryViewFailure extends GlobalCommentsState {
  final String error;
  const GlobalStoryViewFailure(this.error);
}

class GlobalCommentsBloc
    extends Bloc<GlobalCommentsEvent, GlobalCommentsState> {
  final GlobalCommentsGetCommentUsecase _getCommentsUsecase;
  final GlobalCommentsAddCommentUseCase _addCommentUsecase;
  final GlobalCommentsGetAllCommentsUsecase _getAllCommentsUseCase;
  final GlobalCommentsDeleteCommentUsecase _deleteCommentUseCase;
  final BookMarkGetAllPostsUsecase _getAllPostsUseCase;
  final GlobalCommentsUpdatePostCaptionUseCase _updatePostCaptionUseCase;
  final GlobalReportPostUseCase _reportPostUseCase;
  final GlobalToggleLikeUsecase _toggleLikeUseCase;
  final GlobalToggleBookmarkUseCase _toggleBookmarkUseCase;
  final GlobalDeletePostUseCase _deletePostUseCase;
  final MarkStoryViewedUseCase _markStoryViewedUseCase;
  final GetViewedStoriesUseCase _getViewedStoriesUseCase;

  // Add a new field to track viewed stories
  final Set<String> _viewedStories = {};

  // Keep track of current posts and comments
  List<PostEntity> _currentPosts = [];
  List<PostEntity> _currentStories = [];
  List<CommentEntity> _currentComments = [];

  // Flag to track if we're currently loading posts to prevent premature emissions
  bool _isLoadingPosts = false;

  GlobalCommentsBloc({
    required GlobalCommentsGetCommentUsecase getCommentsUsecase,
    required GlobalCommentsAddCommentUseCase addCommentUsecase,
    required GlobalCommentsGetAllCommentsUsecase getAllCommentsUseCase,
    required GlobalCommentsDeleteCommentUsecase deleteCommentUseCase,
    required BookMarkGetAllPostsUsecase getAllPostsUseCase,
    required GlobalCommentsUpdatePostCaptionUseCase updatePostCaptionUseCase,
    required GlobalReportPostUseCase reportPostUseCase,
    required GlobalToggleLikeUsecase toggleLikeUseCase,
    required GlobalToggleBookmarkUseCase toggleBookmarkUseCase,
    required GlobalDeletePostUseCase deletePostUseCase,
    required MarkStoryViewedUseCase markStoryViewedUseCase,
    required GetViewedStoriesUseCase getViewedStoriesUseCase,
    required SharedPreferences prefs,
  })  : _getCommentsUsecase = getCommentsUsecase,
        _addCommentUsecase = addCommentUsecase,
        _getAllCommentsUseCase = getAllCommentsUseCase,
        _deleteCommentUseCase = deleteCommentUseCase,
        _getAllPostsUseCase = getAllPostsUseCase,
        _updatePostCaptionUseCase = updatePostCaptionUseCase,
        _reportPostUseCase = reportPostUseCase,
        _toggleLikeUseCase = toggleLikeUseCase,
        _toggleBookmarkUseCase = toggleBookmarkUseCase,
        _deletePostUseCase = deletePostUseCase,
        _markStoryViewedUseCase = markStoryViewedUseCase,
        _getViewedStoriesUseCase = getViewedStoriesUseCase,
        super(GlobalCommentsInitial()) {
    on<GetGlobalCommentsEvent>(_onGetComments);
    on<AddGlobalCommentEvent>(_onAddComment);
    on<GetAllGlobalCommentsEvent>(_onGetAllComments);
    on<DeleteGlobalCommentEvent>(_onDeleteComment);
    on<GetAllGlobalPostsEvent>(_onGetAllPosts);
    on<UpdateGlobalPostCaptionEvent>(_onUpdatePostCaption);
    on<DeleteGlobalPostEvent>(_onDeletePost);
    on<GlobalReportPostEvent>(_onReportPost);
    on<GlobalToggleLikeEvent>(_onToggleLike);
    on<ToggleGlobalBookmarkEvent>(_onToggleBookmark);
    on<ClearGlobalPostsEvent>(_onClearPosts);
    on<MarkStoryAsViewedEvent>(_onMarkStoryAsViewed);
  }

  // Helper method to emit combined state when both posts and comments are available
  void _emitCombinedStateIfPossible(Emitter<GlobalCommentsState> emit) {
    // Don't emit if we're currently loading posts to prevent race conditions
    if (_isLoadingPosts) {
      return;
    }

    if (_currentPosts.isNotEmpty && _currentComments.isNotEmpty) {
      emit(GlobalPostsAndCommentsSuccess(
        posts: _currentPosts,
        stories: _currentStories,
        comments: _currentComments,
      ));
    } else if (_currentPosts.isNotEmpty) {
      emit(GlobalPostsDisplaySuccess(_currentPosts, stories: _currentStories));
    } else if (_currentComments.isNotEmpty) {
      emit(GlobalCommentsDisplaySuccess(_currentComments));
    }
  }

  Future<void> _onToggleLike(
    GlobalToggleLikeEvent event,
    Emitter<GlobalCommentsState> emit,
  ) async {
    try {
      final result = await _toggleLikeUseCase(
        GlobalToggleLikeParams(
          postId: event.postId,
          userId: event.userId,
        ),
      );

      result.fold(
        (failure) {
          emit(GlobalLikeError(failure.message));
        },
        (_) {
          emit(const GlobalLikeSuccess());
        },
      );
    } catch (e) {
      emit(GlobalLikeError(e.toString()));
    }
  }

  Future<void> _onDeleteComment(
    DeleteGlobalCommentEvent event,
    Emitter<GlobalCommentsState> emit,
  ) async {
    final result = await _deleteCommentUseCase(
      GlobalCommentsDeleteCommentParams(
        commentId: event.commentId,
        userId: event.userId,
      ),
    );

    result.fold(
      (failure) => emit(GlobalCommentsDeleteFailure(error: failure.message)),
      (_) => emit(GlobalCommentsDeleteSuccess()),
    );
  }

  Future<void> _onGetAllComments(
    GetAllGlobalCommentsEvent event,
    Emitter<GlobalCommentsState> emit,
  ) async {
    // Only emit loading if no comments are currently available AND it's not a background refresh
    if (state is! GlobalCommentsDisplaySuccess && !event.isBackgroundRefresh) {
      emit(GlobalCommentsLoading());
    }

    final result = await _getAllCommentsUseCase(NoParams());
    result.fold(
      (failure) {
        emit(GlobalCommentsFailure(failure.message));
      },
      (comments) {
        _currentComments = comments;
        _emitCombinedStateIfPossible(emit);
      },
    );
  }

  Future<void> _onGetComments(
    GetGlobalCommentsEvent event,
    Emitter<GlobalCommentsState> emit,
  ) async {
    try {
      // Only emit loading if no comments are currently available
      if (state is! GlobalCommentsDisplaySuccess) {
        emit(GlobalCommentsLoading());
      }

      final result = await _getCommentsUsecase(event.posterId);

      result.fold(
        (failure) {
          emit(GlobalCommentsFailure(failure.message));
        },
        (comments) {
          _currentComments = comments;
          _emitCombinedStateIfPossible(emit);
        },
      );
    } catch (e) {
      emit(GlobalCommentsFailure(e.toString()));
    }
  }

  Future<void> _onAddComment(
    AddGlobalCommentEvent event,
    Emitter<GlobalCommentsState> emit,
  ) async {
    final result = await _addCommentUsecase(
      GlobalCommentsAddCommentParams(
        posterId: event.posterId,
        userId: event.userId,
        comment: event.comment,
      ),
    );

    result.fold(
      (failure) => emit(GlobalCommentsFailure(failure.message)),
      (newComment) {
        // Refresh comments after adding without showing loading state
        add(const GetAllGlobalCommentsEvent(isBackgroundRefresh: true));
      },
    );
  }

  Future<void> _onGetAllPosts(
    GetAllGlobalPostsEvent event,
    Emitter<GlobalCommentsState> emit,
  ) async {
    // Set loading flag to prevent premature emissions
    _isLoadingPosts = true;

    // Clear current posts to prevent stale data from affecting emissions
    _currentPosts = [];
    _currentStories = [];

    emit(GlobalPostsLoading());

    try {
      final result = await _getAllPostsUseCase(event.userId);

      await result.fold(
        (failure) async {
          _isLoadingPosts = false; // Clear loading flag on failure
          emit(GlobalPostsFailure(failure.message));
        },
        (posts) async {
          print('🔄 Raw posts received: ${posts.length}');
          switch (event.screenType) {
            case 'feed':
              final feedsPosts = posts
                  .where((post) =>
                      post.category == 'Feeds' && post.postType == 'Post')
                  .toList();
              print('🔄 Feed posts filtered: ${feedsPosts.length}');
              _currentPosts = feedsPosts;
              _currentStories = [];
              _isLoadingPosts = false; // Clear loading flag
              _emitCombinedStateIfPossible(emit);
              break;

            case 'profile':
              final profilePosts = posts
                  .where((post) =>
                      post.postType == 'Post' &&
                      post.category != 'Feeds' &&
                      post.userId == event.userId)
                  .toList();
              print(
                  '🔄 Profile posts filtered: ${profilePosts.length} for user: ${event.userId}');
              _currentPosts = profilePosts;
              _currentStories = [];
              _isLoadingPosts = false; // Clear loading flag
              _emitCombinedStateIfPossible(emit);
              break;

            case 'explore':
              final explorePosts = posts
                  .where((post) =>
                      post.postType == 'Post' &&
                      post.category != 'Feeds' &&
                      !post.isFromFollowed)
                  .toList();

              final stories = posts
                  .where((post) =>
                      post.postType == 'Story' && post.category != 'Feeds')
                  .toList();

              _currentPosts = explorePosts;
              _currentStories = stories;
              _isLoadingPosts = false; // Clear loading flag
              _emitCombinedStateIfPossible(emit);
              break;

            case 'following':
              final followingPosts = posts
                  .where((post) =>
                      post.postType == 'Post' &&
                      post.category != 'Feeds' &&
                      post.isFromFollowed)
                  .toList();

              final stories = posts
                  .where((post) =>
                      post.postType == 'Story' && post.category != 'Feeds')
                  .toList();

              _currentPosts = followingPosts;
              _currentStories = stories;
              _isLoadingPosts = false; // Clear loading flag
              _emitCombinedStateIfPossible(emit);
              break;
          }
        },
      );
    } catch (e) {
      _isLoadingPosts = false; // Clear loading flag on exception
      emit(GlobalPostsFailure(e.toString()));
    }
  }

  Future<void> _onUpdatePostCaption(
    UpdateGlobalPostCaptionEvent event,
    Emitter<GlobalCommentsState> emit,
  ) async {
    emit(GlobalPostsLoading());

    final result = await _updatePostCaptionUseCase(
      UpdatePostCaptionParams(
        postId: event.postId,
        caption: event.caption,
      ),
    );

    result.fold(
      (failure) => emit(GlobalPostUpdateFailure(failure.message)),
      (_) => emit(GlobalPostUpdateSuccess()),
    );
  }

  Future<void> _onDeletePost(
    DeleteGlobalPostEvent event,
    Emitter<GlobalCommentsState> emit,
  ) async {
    try {
      emit(GlobalPostsLoading());

      final result = await _deletePostUseCase(event.postId);

      await result.fold(
        (failure) async {
          emit(GlobalPostDeleteFailure(failure.message));
        },
        (_) async {
          emit(GlobalPostDeleteSuccess());
        },
      );
    } catch (e) {
      emit(GlobalPostDeleteFailure(e.toString()));
    }
  }

  Future<void> _onReportPost(
    GlobalReportPostEvent event,
    Emitter<GlobalCommentsState> emit,
  ) async {
    final result = await _reportPostUseCase(
      GlobalReportPostParams(
        postId: event.postId,
        reporterId: event.reporterId,
        reason: event.reason,
        description: event.description,
      ),
    );

    result.fold(
      (failure) {
        if (failure.message.contains('already reported')) {
          emit(GlobalPostAlreadyReportedState());
        } else {
          emit(GlobalPostReportFailure(failure.message));
        }
      },
      (_) => emit(GlobalPostReportSuccess()),
    );
  }

  Future<void> _onToggleBookmark(
    ToggleGlobalBookmarkEvent event,
    Emitter<GlobalCommentsState> emit,
  ) async {
    try {
      emit(GlobalBookmarkLoading());

      final result = await _toggleBookmarkUseCase(
        GlobalToggleBookmarkParams(
          postId: event.postId,
        ),
      );

      result.fold(
        (failure) {
          emit(GlobalBookmarkFailure(failure.message));
        },
        (_) {
          emit(GlobalBookmarkSuccess());
        },
      );
    } catch (e) {
      emit(GlobalBookmarkFailure(e.toString()));
    }
  }

  void _onClearPosts(
    ClearGlobalPostsEvent event,
    Emitter<GlobalCommentsState> emit,
  ) {
    // Clear tracked posts and stories
    _currentPosts = [];
    _currentStories = [];
    _isLoadingPosts = false; // Clear loading flag when clearing posts

    // Immediately emit empty state to clear UI
    emit(const GlobalPostsDisplaySuccess([], stories: []));
  }

  Future<void> _onMarkStoryAsViewed(
    MarkStoryAsViewedEvent event,
    Emitter<GlobalCommentsState> emit,
  ) async {
    try {
      if (_viewedStories.contains(event.storyId)) {
        return;
      }

      _viewedStories.add(event.storyId);

      final result = await _markStoryViewedUseCase(
        MarkStoryViewedParams(
          storyId: event.storyId,
          userId: event.userId,
        ),
      );

      result.fold(
        (failure) {
          _viewedStories.remove(event.storyId);
          emit(GlobalStoryViewFailure(
            'Failed to sync story view: ${failure.message.isEmpty ? "Unknown error occurred" : failure.message}',
          ));
        },
        (_) {
          emit(const GlobalStoryViewSuccess());
        },
      );
    } catch (e) {
      _viewedStories.remove(event.storyId);
      emit(GlobalStoryViewFailure(
        'Failed to sync story view: ${e.toString()}',
      ));
    }
  }

  Set<String> get viewedStories => Set.from(_viewedStories);

  Future<List<String>> getViewedStories(String userId) async {
    try {
      final result = await _getViewedStoriesUseCase(userId);
      return result.fold(
        (failure) => throw Exception(failure.message),
        (stories) => stories,
      );
    } catch (e) {
      rethrow;
    }
  }
}
