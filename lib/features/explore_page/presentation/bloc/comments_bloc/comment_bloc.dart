import 'package:bloc/bloc.dart';
import 'package:flutter/material.dart';
import 'package:vandacoo/core/common/entities/comment_entity.dart';
import 'package:vandacoo/features/explore_page/domain/usecases/get_comments_usecase.dart';

import '../../../../../core/usecase/usecase.dart';
import '../../../domain/usecases/add_comment_usecase.dart';
import '../../../domain/usecases/get_all_comments_usecase.dart';

part 'comment_event.dart';
part 'comment_state.dart';

class CommentBloc extends Bloc<CommentEvent, CommentState> {
  final GetCommentsUsecase getCommentsUsecase;
  final AddCommentUseCase addCommentUsecase;
  final GetAllCommentsUseCase getAllCommentsUseCase;
  // Cache to store comments by post ID
  final Map<String, List<CommentEntity>> _commentsCache = {};
  List<CommentEntity> _allComments = [];

  CommentBloc({
    required this.getCommentsUsecase,
    required this.addCommentUsecase,
    required this.getAllCommentsUseCase,
  }) : super(CommentInitial()) {
    on<GetCommentsEvent>(_onGetComments);
    on<AddCommentEvent>(_onAddComment);
    on<GetAllCommentsEvent>(_onGetAllComments);
  }

  Future<void> _onGetAllComments(
    GetAllCommentsEvent event,
    Emitter<CommentState> emit,
  ) async {
    emit(CommentLoading());
    final result = await getAllCommentsUseCase(NoParams());
    result.fold(
      (failure) => emit(CommentFailure(failure.message)),
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

        emit(CommentDisplaySuccess(_allComments));
      },
    );
  }

  Future<void> _onGetComments(
    GetCommentsEvent event,
    Emitter<CommentState> emit,
  ) async {
    emit(CommentLoading());

    // First check if we have the comments in cache
    if (_commentsCache.containsKey(event.posterId)) {
      emit(CommentDisplaySuccess(_allComments));
      return;
    }

    // If not in cache, fetch from remote
    final result = await getCommentsUsecase(event.posterId);
    result.fold(
      (failure) => emit(CommentFailure(failure.message)),
      (comments) {
        // Update cache with new comments
        _commentsCache[event.posterId] = comments;
        // Update all comments list
        _allComments = [..._allComments, ...comments];
        emit(CommentDisplaySuccess(_allComments));
      },
    );
  }

  Future<void> _onAddComment(
    AddCommentEvent event,
    Emitter<CommentState> emit,
  ) async {
    final result = await addCommentUsecase(AddCommentParams(
      posterId: event.posterId,
      userId: event.userId,
      comment: event.comment,
    ));

    result.fold(
      (failure) => emit(CommentFailure(failure.message)),
      (newComment) {
        // Update cache with new comment
        if (!_commentsCache.containsKey(event.posterId)) {
          _commentsCache[event.posterId] = [];
        }
        _commentsCache[event.posterId]!.add(newComment);

        // Update all comments list
        _allComments = [..._allComments, newComment];

        // Emit success with all updated comments
        emit(CommentDisplaySuccess(_allComments));
      },
    );
  }
}
