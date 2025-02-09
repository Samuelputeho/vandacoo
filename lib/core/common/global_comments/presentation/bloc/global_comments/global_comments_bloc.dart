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
import 'package:vandacoo/core/usecases/usecase.dart';

part 'global_comments_event.dart';
part 'global_comments_state.dart';

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
  final SharedPreferences _prefs;

  // Cache to store comments by post ID
  final Map<String, List<CommentEntity>> _commentsCache = {};
  List<CommentEntity> _allComments = [];

  // Cache to store posts
  List<PostEntity> _allPosts = [];

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
        _prefs = prefs,
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
  }

  Future<void> _onToggleLike(
    GlobalToggleLikeEvent event,
    Emitter<GlobalCommentsState> emit,
  ) async {
    try {
      // Find the current post and create an optimistically updated version
      final currentPost =
          _allPosts.firstWhere((post) => post.id == event.postId);
      final updatedPost = currentPost.copyWith(
        isLiked: !currentPost.isLiked,
        likesCount: currentPost.isLiked
            ? currentPost.likesCount - 1
            : currentPost.likesCount + 1,
      );

      // Update the posts list with the optimistic change
      _allPosts = _allPosts.map((post) {
        if (post.id == event.postId) {
          return updatedPost;
        }
        return post;
      }).toList();

      // Emit the optimistic update immediately
      emit(GlobalPostsDisplaySuccess(_allPosts));

      // Make the API call
      final result = await _toggleLikeUseCase(
        GlobalToggleLikeParams(
          postId: event.postId,
          userId: event.userId,
        ),
      );

      // Handle the result
      await result.fold(
        (failure) async {
          if (!emit.isDone) {
            // Revert the optimistic update on failure
            _allPosts = _allPosts.map((post) {
              if (post.id == event.postId) {
                return currentPost;
              }
              return post;
            }).toList();
            emit(GlobalPostsDisplaySuccess(_allPosts));
            emit(GlobalLikeError(failure.message));
          }
        },
        (success) async {
          // The optimistic update was successful, no need to do anything
        },
      );
    } catch (e) {
      if (!emit.isDone) {
        emit(GlobalLikeError(e.toString()));
      }
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
    // Emit loading state with cached comments if available
    if (_allComments.isNotEmpty) {
      emit(GlobalCommentsLoadingCache(_allComments));
    } else {
      emit(GlobalCommentsLoading());
    }

    final result = await _getAllCommentsUseCase(NoParams());
    result.fold(
      (failure) => emit(GlobalCommentsFailure(failure.message)),
      (comments) {
        // Clear existing cache
        _commentsCache.clear();
        _allComments = comments;

        // Group comments by posterId
        for (var comment in comments) {
          if (!_commentsCache.containsKey(comment.posterId)) {
            _commentsCache[comment.posterId] = [];
          }
          _commentsCache[comment.posterId]!.add(comment);
        }

        emit(GlobalCommentsDisplaySuccess(_allComments));
      },
    );
  }

  Future<void> _onGetComments(
    GetGlobalCommentsEvent event,
    Emitter<GlobalCommentsState> emit,
  ) async {
    // Emit loading state with cached comments if available
    if (_allComments.isNotEmpty) {
      emit(GlobalCommentsLoadingCache(_allComments));
    } else {
      emit(GlobalCommentsLoading());
    }

    // First check if we have the comments in cache
    if (_commentsCache.containsKey(event.posterId)) {
      emit(GlobalCommentsDisplaySuccess(_allComments));
      return;
    }

    // If not in cache, fetch from remote
    final result = await _getCommentsUsecase(event.posterId);
    result.fold(
      (failure) => emit(GlobalCommentsFailure(failure.message)),
      (comments) {
        // Update cache with new comments
        _commentsCache[event.posterId] = comments;
        // Update all comments list
        _allComments = [..._allComments, ...comments];
        emit(GlobalCommentsDisplaySuccess(_allComments));
      },
    );
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
        // Update cache with new comment
        if (!_commentsCache.containsKey(event.posterId)) {
          _commentsCache[event.posterId] = [];
        }
        _commentsCache[event.posterId]!.add(newComment);

        // Update all comments list
        _allComments = [..._allComments, newComment];

        // Emit success with all updated comments
        emit(GlobalCommentsDisplaySuccess(_allComments));
      },
    );
  }

  Future<void> _onGetAllPosts(
    GetAllGlobalPostsEvent event,
    Emitter<GlobalCommentsState> emit,
  ) async {
    // Emit loading state with cached posts if available
    if (_allPosts.isNotEmpty) {
      emit(GlobalPostsLoadingCache(_allPosts));
    } else {
      emit(GlobalPostsLoading());
    }

    final result = await _getAllPostsUseCase(event.userId);
    result.fold(
      (failure) => emit(GlobalPostsFailure(failure.message)),
      (posts) {
        _allPosts = posts;
        emit(GlobalPostsDisplaySuccess(_allPosts));
      },
    );
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
      (_) {
        // Update the post in the cache
        final updatedPosts = _allPosts.map((post) {
          if (post.id == event.postId) {
            return post.copyWith(caption: event.caption);
          }
          return post;
        }).toList();

        _allPosts = updatedPosts;
        emit(GlobalPostUpdateSuccess());
        emit(GlobalPostsDisplaySuccess(_allPosts));
      },
    );
  }

  Future<void> _onDeletePost(
    DeleteGlobalPostEvent event,
    Emitter<GlobalCommentsState> emit,
  ) async {
    try {
      emit(GlobalPostsLoading());

      // Remove the post from the cache
      _allPosts = _allPosts.where((post) => post.id != event.postId).toList();

      emit(GlobalPostDeleteSuccess());
      emit(GlobalPostsDisplaySuccess(_allPosts));
    } catch (e) {
      emit(GlobalPostDeleteFailure(e.toString()));
    }
  }

  Future<void> _onReportPost(
    GlobalReportPostEvent event,
    Emitter<GlobalCommentsState> emit,
  ) async {
    emit(GlobalPostsLoading());

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
        (failure) => emit(GlobalBookmarkFailure(failure.message)),
        (_) => emit(GlobalBookmarkSuccess()),
      );
    } catch (e) {
      emit(GlobalBookmarkFailure(e.toString()));
    }
  }
}
