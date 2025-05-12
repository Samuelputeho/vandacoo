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

  // Cache to store comments by post ID
  final Map<String, List<CommentEntity>> _commentsCache = {};
  List<CommentEntity> _allComments = [];

  // Cache to store posts
  List<PostEntity> _allPosts = [];
  List<PostEntity> _allStories = [];
  List<PostEntity> _profilePosts = []; // Add profile posts cache

  // Add a separate cache for feeds posts
  List<PostEntity> _feedsPosts = [];

  // Add a new field to track viewed stories
  final Set<String> _viewedStories = {};

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

  Future<void> _onToggleLike(
    GlobalToggleLikeEvent event,
    Emitter<GlobalCommentsState> emit,
  ) async {
    try {
      late PostEntity currentPost;
      String postLocation = '';

      try {
        currentPost = _profilePosts.firstWhere(
          (post) => post.id == event.postId,
        );
        postLocation = 'profile';
      } catch (_) {
        try {
          currentPost = _feedsPosts.firstWhere(
            (post) => post.id == event.postId,
          );
          postLocation = 'feed';
        } catch (_) {
          try {
            currentPost = _allPosts.firstWhere(
              (post) => post.id == event.postId,
            );
            postLocation = 'explore';
          } catch (_) {
            throw Exception('Post not found');
          }
        }
      }

      final updatedPost = currentPost.copyWith(
        isLiked: !currentPost.isLiked,
        likesCount: currentPost.isLiked
            ? currentPost.likesCount - 1
            : currentPost.likesCount + 1,
      );

      switch (postLocation) {
        case 'profile':
          _profilePosts = _profilePosts.map<PostEntity>((post) {
            return post.id == event.postId ? updatedPost : post;
          }).toList();
          emit(GlobalPostsDisplaySuccess(_profilePosts, stories: const []));
          break;
        case 'feed':
          _feedsPosts = _feedsPosts.map<PostEntity>((post) {
            return post.id == event.postId ? updatedPost : post;
          }).toList();
          emit(GlobalPostsDisplaySuccess(_feedsPosts, stories: const []));
          break;
        case 'explore':
          _allPosts = _allPosts.map<PostEntity>((post) {
            return post.id == event.postId ? updatedPost : post;
          }).toList();
          emit(GlobalPostsDisplaySuccess(_allPosts, stories: _allStories));
          break;
      }

      final result = await _toggleLikeUseCase(
        GlobalToggleLikeParams(
          postId: event.postId,
          userId: event.userId,
        ),
      );

      await result.fold(
        (failure) async {
          switch (postLocation) {
            case 'profile':
              _profilePosts = _profilePosts.map<PostEntity>((post) {
                return post.id == event.postId ? currentPost : post;
              }).toList();
              emit(GlobalPostsDisplaySuccess(_profilePosts, stories: const []));
              break;
            case 'feed':
              _feedsPosts = _feedsPosts.map<PostEntity>((post) {
                return post.id == event.postId ? currentPost : post;
              }).toList();
              emit(GlobalPostsDisplaySuccess(_feedsPosts, stories: const []));
              break;
            case 'explore':
              _allPosts = _allPosts.map<PostEntity>((post) {
                return post.id == event.postId ? currentPost : post;
              }).toList();
              emit(GlobalPostsDisplaySuccess(_allPosts, stories: _allStories));
              break;
          }
          emit(GlobalLikeError(failure.message));
        },
        (success) async {
          emit(GlobalLikeSuccess(!currentPost.isLiked));
          switch (postLocation) {
            case 'profile':
              emit(GlobalPostsDisplaySuccess(_profilePosts, stories: const []));
              break;
            case 'feed':
              emit(GlobalPostsDisplaySuccess(_feedsPosts, stories: const []));
              break;
            case 'explore':
              emit(GlobalPostsDisplaySuccess(_allPosts, stories: _allStories));
              break;
          }
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
    if (_allComments.isNotEmpty) {
      emit(GlobalCommentsLoadingCache(_allComments));
    } else {
      emit(GlobalCommentsLoading());
    }

    final result = await _getAllCommentsUseCase(NoParams());
    result.fold(
      (failure) => emit(GlobalCommentsFailure(failure.message)),
      (comments) {
        _commentsCache.clear();
        _allComments = comments;

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
    try {
      if (_allComments.isNotEmpty) {
        emit(GlobalCommentsLoadingCache(_allComments));
      } else {
        emit(GlobalCommentsLoading());
      }

      if (_commentsCache.containsKey(event.posterId)) {
        emit(GlobalCommentsDisplaySuccess(_allComments));
        return;
      }

      final result = await _getCommentsUsecase(event.posterId);

      result.fold(
        (failure) {
          emit(GlobalCommentsFailure(failure.message));
        },
        (comments) {
          _commentsCache[event.posterId] = comments;

          final Set<String> existingCommentIds =
              _allComments.map((c) => c.id).toSet();

          final newComments = comments
              .where((comment) => !existingCommentIds.contains(comment.id))
              .toList();

          _allComments = [..._allComments, ...newComments];

          emit(GlobalCommentsDisplaySuccess(_allComments));
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
        if (!_commentsCache.containsKey(event.posterId)) {
          _commentsCache[event.posterId] = [];
        }
        _commentsCache[event.posterId]!.add(newComment);

        _allComments = [..._allComments, newComment];

        emit(GlobalCommentsDisplaySuccess(_allComments));
      },
    );
  }

  Future<void> _onGetAllPosts(
    GetAllGlobalPostsEvent event,
    Emitter<GlobalCommentsState> emit,
  ) async {
    if (event.screenType == 'feed') {
      _allPosts = [];
      _allStories = [];
      _profilePosts = [];
    } else if (event.screenType == 'profile') {
      _allPosts = [];
      _allStories = [];
      _feedsPosts = [];
    } else {
      _feedsPosts = [];
      _profilePosts = [];
    }

    if (event.screenType == 'feed' && _feedsPosts.isNotEmpty) {
      emit(GlobalPostsLoadingCache(_feedsPosts));
    } else if (event.screenType == 'profile' && _profilePosts.isNotEmpty) {
      emit(GlobalPostsLoadingCache(_profilePosts));
    } else if (_allPosts.isNotEmpty) {
      emit(GlobalPostsLoadingCache(_allPosts));
    } else {
      emit(GlobalPostsLoading());
    }

    try {
      final result = await _getAllPostsUseCase(event.userId);

      await result.fold(
        (failure) async {
          emit(GlobalPostsFailure(failure.message));
        },
        (posts) async {
          switch (event.screenType) {
            case 'feed':
              _feedsPosts = posts
                  .where((post) =>
                      post.category == 'Feeds' && post.postType == 'Post')
                  .toList();
              emit(GlobalPostsDisplaySuccess(_feedsPosts, stories: const []));
              break;

            case 'profile':
              _profilePosts = posts
                  .where((post) =>
                      post.postType == 'Post' &&
                      post.category != 'Feeds' &&
                      post.userId == event.userId)
                  .toList();
              emit(GlobalPostsDisplaySuccess(_profilePosts, stories: const []));
              break;

            case 'explore':
              _allPosts = posts
                  .where((post) =>
                      post.postType == 'Post' &&
                      post.category != 'Feeds' &&
                      !post.isFromFollowed)
                  .toList();

              _allStories = posts
                  .where((post) =>
                      post.postType == 'Story' && post.category != 'Feeds')
                  .toList();

              emit(GlobalPostsDisplaySuccess(_allPosts, stories: _allStories));
              break;

            case 'following':
              _allPosts = posts
                  .where((post) =>
                      post.postType == 'Post' && post.category != 'Feeds')
                  .toList();

              _allStories = posts
                  .where((post) =>
                      post.postType == 'Story' && post.category != 'Feeds')
                  .toList();

              emit(GlobalPostsDisplaySuccess(_allPosts, stories: _allStories));
              break;
          }
        },
      );
    } catch (e) {
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
      (_) {
        _allPosts = _allPosts.map((post) {
          if (post.id == event.postId) {
            return post.copyWith(caption: event.caption);
          }
          return post;
        }).toList();

        _feedsPosts = _feedsPosts.map((post) {
          if (post.id == event.postId) {
            return post.copyWith(caption: event.caption);
          }
          return post;
        }).toList();

        emit(GlobalPostUpdateSuccess());
      },
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
          _allPosts =
              _allPosts.where((post) => post.id != event.postId).toList();
          _feedsPosts =
              _feedsPosts.where((post) => post.id != event.postId).toList();

          emit(GlobalPostDeleteSuccess());
          emit(GlobalPostsDisplaySuccess(_feedsPosts, stories: const []));
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

      late PostEntity currentPost;
      bool isInFeeds = false;

      try {
        currentPost = _feedsPosts.firstWhere(
          (post) => post.id == event.postId,
        );
        isInFeeds = true;
      } catch (_) {
        try {
          currentPost = _allPosts.firstWhere(
            (post) => post.id == event.postId,
          );
        } catch (_) {
          throw Exception('Post not found');
        }
      }

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

          if (isInFeeds) {
            emit(GlobalPostsDisplaySuccess(_feedsPosts, stories: const []));
          } else {
            emit(GlobalPostsDisplaySuccess(_allPosts, stories: _allStories));
          }
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
    _allPosts = [];
    _allStories = [];
    _feedsPosts = [];
    _profilePosts = [];
    emit(const GlobalPostsDisplaySuccess([], stories: []));
  }

  List<PostEntity> get currentPosts {
    if (_profilePosts.isNotEmpty) return _profilePosts;
    if (_feedsPosts.isNotEmpty) return _feedsPosts;
    return _allPosts;
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
