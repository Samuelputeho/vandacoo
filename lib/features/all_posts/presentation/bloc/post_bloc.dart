import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vandacoo/core/common/entities/post_entity.dart';
import 'package:vandacoo/core/usecase/usecase.dart';
import 'package:vandacoo/features/all_posts/domain/usecases/get_all_posts_usecase.dart';
import 'package:vandacoo/features/all_posts/domain/usecases/upload_post_usecase.dart';
import 'package:vandacoo/features/all_posts/domain/usecases/mark_story_viewed_usecase.dart';
import 'package:vandacoo/features/all_posts/domain/usecases/get_viewed_stories_usecase.dart';

part 'post_event.dart';
part 'post_state.dart';

class PostBloc extends Bloc<PostEvent, PostState> {
  final UploadPost _uploadPost;
  final GetAllPostsUsecase _getAllPostsUsecase;
  final MarkStoryViewedUsecase _markStoryViewedUsecase;
  final GetViewedStoriesUsecase _getViewedStoriesUsecase;
  final SharedPreferences _prefs;
  static const String _viewedStoriesKey = 'viewed_stories';

  PostBloc({
    required UploadPost uploadPost,
    required GetAllPostsUsecase getAllPostsUsecase,
    required MarkStoryViewedUsecase markStoryViewedUsecase,
    required GetViewedStoriesUsecase getViewedStoriesUsecase,
    required SharedPreferences prefs,
  })  : _uploadPost = uploadPost,
        _getAllPostsUsecase = getAllPostsUsecase,
        _markStoryViewedUsecase = markStoryViewedUsecase,
        _getViewedStoriesUsecase = getViewedStoriesUsecase,
        _prefs = prefs,
        super(PostInitial()) {
    on<PostUploadEvent>(_onPostUpload);
    on<GetAllPostsEvent>(_onGetAllPosts);
    on<MarkStoryViewedEvent>(_onMarkStoryViewed);
  }

  Set<String> get viewedStories {
    return Set<String>.from(_prefs.getStringList(_viewedStoriesKey) ?? []);
  }

  Future<void> _saveViewedStories(Set<String> stories) async {
    await _prefs.setStringList(_viewedStoriesKey, stories.toList());
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
      emit(PostLoading());
    }

    // Get posts and stories
    final res = await _getAllPostsUsecase(NoParams());

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
}
