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
  final Map<String, bool> _bookmarkedPosts = {};

//global variables
  static const String _viewedStoriesKey = 'viewed_stories';
  static const String _bookmarksKey = 'bookmarked_posts';
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
  })  : _uploadPost = uploadPost,
        _getAllPostsUsecase = getAllPostsUsecase,
        _markStoryViewedUsecase = markStoryViewedUsecase,
        _getViewedStoriesUsecase = getViewedStoriesUsecase,
        _prefs = prefs,
        _deletePostUseCase = deletePostUseCase,
        _updatePostCaptionUseCase = updatePostCaptionUseCase,
        _toggleBookmarkUseCase = toggleBookmarkUseCase,
        _getBookmarkedPostsUseCase = getBookmarkedPostsUseCase,
        super(PostInitial()) {
    on<PostUploadEvent>(_onPostUpload);
    on<GetAllPostsEvent>(_onGetAllPosts);
    on<MarkStoryViewedEvent>(_onMarkStoryViewed);
    on<DeletePostEvent>(_onDeletePost);
    on<UpdatePostCaptionEvent>(_onUpdatePostCaption);
    on<ToggleBookmarkEvent>(_onToggleBookmark);
    _loadBookmarksFromPrefs();
    _syncBookmarksWithDatabase();
  }

  void _loadBookmarksFromPrefs() {
    final bookmarks = _prefs.getStringList(_bookmarksKey) ?? [];
    for (final postId in bookmarks) {
      _bookmarkedPosts[postId] = true;
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
    if (state is! PostDisplaySuccess) {
      // Emit PostLoadingCache with latest posts and stories if available
      if (_posts.isNotEmpty || _stories.isNotEmpty) {
        emit(PostLoadingCache(posts: _posts, stories: _stories));
      } else {
        emit(PostLoading());
      }
    }

    // Get posts and stories
    final res = await _getAllPostsUsecase(event.userId);

    await res.fold(
      (l) async => emit(PostFailure(l.message)),
      (r) async {
        final posts = r.where((post) => post.postType == 'Post').toList();
        final stories = r.where((post) => post.postType == 'Story').toList();

        // Get viewed stories from backend
        if (emit.isDone) return;

        final viewedRes = await _getViewedStoriesUsecase(
            ViewedStoriesParams(userId: event.userId));

        await viewedRes.fold(
          (l) async => null, // Use local storage if backend fails
          (viewedIds) async {
            if (emit.isDone) return;
            // Merge backend and local storage
            final allViewed = viewedStories..addAll(viewedIds.map((e) => e.id));
            await _saveViewedStories(allViewed);
          },
        );

        if (emit.isDone) return;
        _posts
          ..clear()
          ..addAll(posts);
        _stories
          ..clear()
          ..addAll(stories);
        emit(PostDisplaySuccess(posts: posts, stories: stories));
      },
    );
  }

  void _onPostUpload(PostUploadEvent event, Emitter<PostState> emit) async {
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

    if (emit.isDone) return;
    await res.fold(
      (l) async => emit(PostFailure(l.message)),
      (r) async => emit(PostSuccess()),
    );
  }

  Future<void> _onToggleBookmark(
    ToggleBookmarkEvent event,
    Emitter<PostState> emit,
  ) async {
    try {
      // Optimistically update the local state
      final isNowBookmarked = !(_bookmarkedPosts[event.postId] ?? false);
      _bookmarkedPosts[event.postId] = isNowBookmarked;
      _saveBookmarksToPrefs();
      emit(PostBookmarkSuccess(isNowBookmarked));

      // Make the API call
      final result = await _toggleBookmarkUseCase(
        ToggleBookmarkParams(
          postId: event.postId,
          userId: event.userId,
        ),
      );

      // Handle the result
      await result.fold(
        (failure) async {
          // Revert the optimistic update on failure
          _bookmarkedPosts[event.postId] = !isNowBookmarked;
          _saveBookmarksToPrefs();
          emit(PostBookmarkError(failure.message));
        },
        (_) async {
          // State is already updated, no need to emit again
        },
      );
    } catch (e) {
      // Revert the optimistic update on error
      _bookmarkedPosts[event.postId] =
          !(_bookmarkedPosts[event.postId] ?? false);
      _saveBookmarksToPrefs();
      emit(PostBookmarkError(e.toString()));
    }
  }

  bool isPostBookmarked(String postId) => _bookmarkedPosts[postId] ?? false;
}
