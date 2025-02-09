import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vandacoo/core/common/entities/post_entity.dart';
import 'package:vandacoo/core/usecase/usecase.dart';
import 'package:vandacoo/features/explore_page/domain/usecases/get_all_posts_usecase.dart';
import 'package:vandacoo/features/explore_page/domain/usecases/upload_post_usecase.dart';
import 'package:vandacoo/features/explore_page/domain/usecases/mark_story_viewed_usecase.dart';
import 'package:vandacoo/features/explore_page/domain/usecases/get_viewed_stories_usecase.dart';

import '../../../domain/usecases/delete_post.dart';
import '../../../domain/usecases/update_post_caption_usecase.dart';
import '../../../domain/usecases/toggle_bookmark_usecase.dart';
import '../../../domain/usecases/get_bookmarked_posts_usecase.dart';
import '../../../domain/usecases/report_post_usecase.dart';
import '../../../domain/usecases/toggle_like_usecase.dart';

part 'post_event.dart';
part 'post_state.dart';

class PostBloc extends Bloc<PostEvent, PostState> {
  final UploadPost _uploadPost;
  final GetAllPostsUsecase _getAllPostsUsecase;
  final MarkStoryViewedUsecase _markStoryViewedUsecase;
  final GetViewedStoriesUsecase _getViewedStoriesUsecase;
  final SharedPreferences _prefs;
  final DeletePostUseCase _deletePostUseCase;
  final UpdatePostCaptionUseCase _updatePostCaptionUseCase;
  final ToggleBookmarkUseCase _toggleBookmarkUseCase;
  final GetBookmarkedPostsUseCase _getBookmarkedPostsUseCase;
  final ReportPostUseCase _reportPostUseCase;
  final ToggleLikeUsecase _toggleLikeUsecase;
  final Map<String, bool> _bookmarkedPosts = {};
  final Map<String, bool> _likedPosts = {};

//global variables
  static const String _viewedStoriesKey = 'viewed_stories';
  static const String _bookmarksKey = 'bookmarked_posts';
  static const String _likesKey = 'liked_posts';
  final List<PostEntity> _posts = [];
  final List<PostEntity> _stories = [];

  List<PostEntity> get posts => _posts;
  List<PostEntity> get stories => _stories;

  PostBloc({
    required UploadPost uploadPost,
    required GetAllPostsUsecase getAllPostsUsecase,
    required MarkStoryViewedUsecase markStoryViewedUsecase,
    required GetViewedStoriesUsecase getViewedStoriesUsecase,
    required SharedPreferences prefs,
    required DeletePostUseCase deletePostUseCase,
    required UpdatePostCaptionUseCase updatePostCaptionUseCase,
    required ToggleBookmarkUseCase toggleBookmarkUseCase,
    required GetBookmarkedPostsUseCase getBookmarkedPostsUseCase,
    required ReportPostUseCase reportPostUseCase,
    required ToggleLikeUsecase toggleLikeUsecase,
  })  : _uploadPost = uploadPost,
        _getAllPostsUsecase = getAllPostsUsecase,
        _markStoryViewedUsecase = markStoryViewedUsecase,
        _getViewedStoriesUsecase = getViewedStoriesUsecase,
        _prefs = prefs,
        _deletePostUseCase = deletePostUseCase,
        _updatePostCaptionUseCase = updatePostCaptionUseCase,
        _toggleBookmarkUseCase = toggleBookmarkUseCase,
        _getBookmarkedPostsUseCase = getBookmarkedPostsUseCase,
        _reportPostUseCase = reportPostUseCase,
        _toggleLikeUsecase = toggleLikeUsecase,
        super(PostInitial()) {
    on<PostUploadEvent>(_onPostUpload);
    on<GetAllPostsEvent>(_onGetAllPosts);
    on<MarkStoryViewedEvent>(_onMarkStoryViewed);
    on<DeletePostEvent>(_onDeletePost);
    on<UpdatePostCaptionEvent>(_onUpdatePostCaption);
    on<ToggleBookmarkEvent>(_onToggleBookmark);
    on<ReportPostEvent>(_onReportPost);
    on<ToggleLikeEvent>(_onToggleLike);
    _loadBookmarksFromPrefs();
    _loadLikesFromPrefs();
    _syncBookmarksWithDatabase();
  }

  void _loadBookmarksFromPrefs() {
    final bookmarks = _prefs.getStringList(_bookmarksKey) ?? [];
    for (final postId in bookmarks) {
      _bookmarkedPosts[postId] = true;
    }
  }

  void _loadLikesFromPrefs() {
    final likes = _prefs.getStringList(_likesKey) ?? [];
    for (final postId in likes) {
      _likedPosts[postId] = true;
    }
  }

  Future<void> _syncBookmarksWithDatabase() async {
    final result = await _getBookmarkedPostsUseCase(NoParams());
    result.fold(
      (failure) {
        // If database sync fails, keep using local state
      },
      (bookmarkedPostIds) {
        _bookmarkedPosts.clear();
        for (final postId in bookmarkedPostIds) {
          _bookmarkedPosts[postId] = true;
        }
        _saveBookmarksToPrefs();
      },
    );
  }

  void _saveBookmarksToPrefs() {
    final bookmarkedIds = _bookmarkedPosts.entries
        .where((entry) => entry.value)
        .map((entry) => entry.key)
        .toList();
    _prefs.setStringList(_bookmarksKey, bookmarkedIds);
  }

  void _saveLikesToPrefs() {
    final likedIds = _likedPosts.entries
        .where((entry) => entry.value)
        .map((entry) => entry.key)
        .toList();
    _prefs.setStringList(_likesKey, likedIds);
  }

  void _onUpdatePostCaption(
    UpdatePostCaptionEvent event,
    Emitter<PostState> emit,
  ) async {
    emit(PostLoading());

    final res = await _updatePostCaptionUseCase(
      UpdatePostCaptionParams(
        postId: event.postId,
        caption: event.caption,
      ),
    );

    await res.fold(
      (l) async => emit(PostUpdateCaptionFailure(l.message)),
      (r) async => emit(PostUpdateCaptionSuccess()),
    );
  }

  Set<String> get viewedStories {
    return Set<String>.from(_prefs.getStringList(_viewedStoriesKey) ?? []);
  }

  Future<void> _saveViewedStories(Set<String> stories) async {
    await _prefs.setStringList(_viewedStoriesKey, stories.toList());
  }

  void _onDeletePost(DeletePostEvent event, Emitter<PostState> emit) async {
    emit(PostLoading());
    final res = await _deletePostUseCase(DeletePostParams(event.postId));
    await res.fold(
      (l) async => emit(PostDeleteFailure(l.message)),
      (r) async => emit(PostDeleteSuccess()),
    );
  }

  void _onMarkStoryViewed(
    MarkStoryViewedEvent event,
    Emitter<PostState> emit,
  ) async {
    // Update local storage immediately
    final stories = viewedStories..add(event.storyId);
    await _saveViewedStories(stories);

    // Update remote storage
    final res = await _markStoryViewedUsecase(
      MarkStoryViewedParams(
        storyId: event.storyId,
        viewerId: event.viewerId,
      ),
    );

    if (emit.isDone) return;
    await res.fold(
      (l) async => emit(PostFailure(l.message)),
      (r) async =>
          null, // Don't emit new state as local storage is already updated
    );
  }

  void _onGetAllPosts(
    GetAllPostsEvent event,
    Emitter<PostState> emit,
  ) async {
    print('🔄 PostBloc - Starting _onGetAllPosts for userId: ${event.userId}');
    // Always emit loading state first
    print(
        '🔄 Loading posts with cache - Posts count: ${_posts.length}, Stories count: ${_stories.length}');
    emit(
      PostLoadingCache(posts: _posts, stories: _stories),
    );

    // Get posts and stories
    print('📡 PostBloc - Fetching fresh data from database...');
    final res = await _getAllPostsUsecase(event.userId);

    await res.fold(
      (l) async {
        print('❌ PostBloc - Failed to fetch posts: ${l.message}');
        emit(PostFailure(l.message));
      },
      (r) async {
        print('📥 PostBloc - Total items received: ${r.length}');
        final posts = r.where((post) => post.postType == 'Post').toList();
        final stories = r.where((post) => post.postType == 'Story').toList();
        print(
            '📥 PostBloc - After filtering - Posts: ${posts.length}, Stories: ${stories.length}');

        // Update cache immediately
        print('🔄 PostBloc - Updating cache...');
        print(
            'Before update - Cache posts: ${_posts.length}, Cache stories: ${_stories.length}');
        _posts.clear();
        _posts.addAll(posts);
        _stories.clear();
        _stories.addAll(stories);
        print(
            'After update - Cache posts: ${_posts.length}, Cache stories: ${_stories.length}');

        // Get viewed stories from backend
        if (emit.isDone) {
          print('⚠️ PostBloc - Emit is done before fetching viewed stories');
          return;
        }

        print('📡 PostBloc - Fetching viewed stories...');
        final viewedRes = await _getViewedStoriesUsecase(
            ViewedStoriesParams(userId: event.userId));

        await viewedRes.fold(
          (l) async {
            print('⚠️ PostBloc - Failed to fetch viewed stories: ${l.message}');
            return null;
          },
          (viewedIds) async {
            if (emit.isDone) {
              print(
                  '⚠️ PostBloc - Emit is done before updating viewed stories');
              return;
            }
            print('📥 PostBloc - Updating viewed stories in local storage');
            // Merge backend and local storage
            final allViewed = viewedStories..addAll(viewedIds.map((e) => e.id));
            await _saveViewedStories(allViewed);
          },
        );

        if (emit.isDone) {
          print('⚠️ PostBloc - Emit is done before final success state');
          return;
        }
        print('✅ PostBloc - Emitting success state with updated cache');
        emit(PostDisplaySuccess(posts: _posts, stories: _stories));
      },
    );
  }

  void _onPostUpload(PostUploadEvent event, Emitter<PostState> emit) async {
    print('📤 Uploading new post...');
    emit(PostLoading());

    final res = await _uploadPost(
      UploadPostParams(
        userId: event.userId!,
        caption: event.caption!,
        image: event.image!,
        category: event.category!,
        region: event.region!,
        postType: event.postType!,
      ),
    );

    if (emit.isDone) {
      print('⚠️ Emit is done before handling upload result');
      return;
    }
    await res.fold(
      (l) async {
        print('❌ Upload failed: ${l.message}');
        emit(PostFailure(l.message));
      },
      (r) async {
        print('✅ Upload successful');
        emit(PostSuccess());
      },
    );
  }

  Future<void> _onToggleBookmark(
    ToggleBookmarkEvent event,
    Emitter<PostState> emit,
  ) async {
    try {
      print('🔖 Toggling bookmark for post: ${event.postId}');
      // Optimistically update the local state
      final isNowBookmarked = !(_bookmarkedPosts[event.postId] ?? false);
      _bookmarkedPosts[event.postId] = isNowBookmarked;
      _saveBookmarksToPrefs();
      print('📱 Local bookmark state updated: $isNowBookmarked');
      emit(PostBookmarkSuccess(isNowBookmarked));

      // Make the API call
      print('📡 Syncing bookmark with database...');
      final result = await _toggleBookmarkUseCase(
        ToggleBookmarkParams(
          postId: event.postId,
          userId: event.userId,
        ),
      );

      // Handle the result
      await result.fold(
        (failure) async {
          print('❌ Bookmark sync failed: ${failure.message}');
          // Revert the optimistic update on failure
          _bookmarkedPosts[event.postId] = !isNowBookmarked;
          _saveBookmarksToPrefs();
          emit(PostBookmarkError(failure.message));
        },
        (_) async {
          print('✅ Bookmark sync successful');
          // State is already updated, no need to emit again
        },
      );
    } catch (e) {
      print('❌ Bookmark error: $e');
      // Revert the optimistic update on error
      _bookmarkedPosts[event.postId] =
          !(_bookmarkedPosts[event.postId] ?? false);
      _saveBookmarksToPrefs();
      emit(PostBookmarkError(e.toString()));
    }
  }

  bool isPostBookmarked(String postId) => _bookmarkedPosts[postId] ?? false;

  Future<void> _onReportPost(
    ReportPostEvent event,
    Emitter<PostState> emit,
  ) async {
    emit(PostLoading());

    final result = await _reportPostUseCase(
      ReportPostParams(
        postId: event.postId,
        reporterId: event.reporterId,
        reason: event.reason,
        description: event.description,
      ),
    );

    await result.fold(
      (failure) async {
        if (failure.message.contains('already reported')) {
          emit(PostAlreadyReportedState());
        } else {
          emit(PostReportFailure(failure.message));
        }
      },
      (_) async => emit(PostReportSuccess()),
    );
  }

  Future<void> _onToggleLike(
    ToggleLikeEvent event,
    Emitter<PostState> emit,
  ) async {
    try {
      print('❤️ Toggling like for post: ${event.postId}');
      emit(PostLoadingCache(posts: _posts, stories: _stories));

      // Optimistically update the local state
      final isNowLiked = !(_likedPosts[event.postId] ?? false);
      _likedPosts[event.postId] = isNowLiked;
      _saveLikesToPrefs();
      print('📱 Local like state updated: $isNowLiked');

      // Make the API call
      print('📡 Syncing like with database...');
      final result = await _toggleLikeUsecase(
        ToggleLikeParams(
          postId: event.postId,
          userId: event.userId,
        ),
      );

      // Handle the result
      await result.fold(
        (failure) async {
          print('❌ Like sync failed: ${failure.message}');
          // Revert the optimistic update on failure
          _likedPosts[event.postId] = !isNowLiked;
          _saveLikesToPrefs();
          emit(PostLikeError(failure.message));
        },
        (_) async {
          print('✅ Like sync successful, refreshing posts...');
          // Refresh posts after successful like toggle
          final postsResult = await _getAllPostsUsecase(event.userId);
          await postsResult.fold(
            (failure) async {
              print('❌ Failed to refresh posts after like: ${failure.message}');
              emit(PostFailure(failure.message));
            },
            (posts) async {
              print('📥 Received updated posts after like');
              final postsList =
                  posts.where((post) => post.postType == 'Post').toList();
              final storiesList =
                  posts.where((post) => post.postType == 'Story').toList();
              print(
                  'Before cache update - Posts: ${_posts.length}, Stories: ${_stories.length}');
              _posts.clear();
              _posts.addAll(postsList);
              _stories.clear();
              _stories.addAll(storiesList);
              print(
                  'After cache update - Posts: ${_posts.length}, Stories: ${_stories.length}');
              // Reload likes from SharedPreferences to ensure sync
              _loadLikesFromPrefs();
              emit(PostDisplaySuccess(posts: postsList, stories: storiesList));
              // Emit like success state
              emit(PostLikeSuccess(isNowLiked));
            },
          );
        },
      );
    } catch (e) {
      print('❌ Like error: $e');
      // Revert the optimistic update on error
      _likedPosts[event.postId] = !(_likedPosts[event.postId] ?? false);
      _saveLikesToPrefs();
      emit(PostLikeError(e.toString()));
    }
  }

  bool isPostLiked(String postId) {
    return _likedPosts[postId] ?? false;
  }

  @override
  Future<void> close() {
    // Save likes state before closing
    _saveLikesToPrefs();
    return super.close();
  }
}
