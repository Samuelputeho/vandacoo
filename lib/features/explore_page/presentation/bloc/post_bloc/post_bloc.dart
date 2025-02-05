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

//global variables
  static const String _viewedStoriesKey = 'viewed_stories';
  final List<PostEntity> _posts = [];
  final List<PostEntity> _stories = [];

  PostBloc({
    required UploadPost uploadPost,
    required GetAllPostsUsecase getAllPostsUsecase,
    required MarkStoryViewedUsecase markStoryViewedUsecase,
    required GetViewedStoriesUsecase getViewedStoriesUsecase,
    required SharedPreferences prefs,
    required DeletePostUseCase deletePostUseCase,
    required UpdatePostCaptionUseCase updatePostCaptionUseCase,
  })  : _uploadPost = uploadPost,
        _getAllPostsUsecase = getAllPostsUsecase,
        _markStoryViewedUsecase = markStoryViewedUsecase,
        _getViewedStoriesUsecase = getViewedStoriesUsecase,
        _prefs = prefs,
        _deletePostUseCase = deletePostUseCase,
        _updatePostCaptionUseCase = updatePostCaptionUseCase,
        super(PostInitial()) {
    on<PostUploadEvent>(_onPostUpload);
    on<GetAllPostsEvent>(_onGetAllPosts);
    on<MarkStoryViewedEvent>(_onMarkStoryViewed);
    on<DeletePostEvent>(_onDeletePost);
    on<UpdatePostCaptionEvent>(_onUpdatePostCaption);
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
        _posts.addAll(posts);
        _stories.addAll(stories);
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
