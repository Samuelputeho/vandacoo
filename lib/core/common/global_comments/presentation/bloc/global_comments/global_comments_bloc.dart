import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:vandacoo/core/common/entities/comment_entity.dart';
import 'package:vandacoo/core/common/global_comments/domain/usecases/add_comment_usecase.dart';
import 'package:vandacoo/core/common/global_comments/domain/usecases/delete_comment_usecase.dart';
import 'package:vandacoo/core/common/global_comments/domain/usecases/get_all_comments_usecase.dart';
import 'package:vandacoo/core/common/global_comments/domain/usecases/get_comment_usecase.dart';
import 'package:vandacoo/core/usecases/usecase.dart';

part 'global_comments_event.dart';
part 'global_comments_state.dart';

class GlobalCommentsBloc
    extends Bloc<GlobalCommentsEvent, GlobalCommentsState> {
  final GlobalCommentsGetCommentUsecase getCommentsUsecase;
  final GlobalCommentsAddCommentUseCase addCommentUsecase;
  final GlobalCommentsGetAllCommentsUsecase getAllCommentsUseCase;
  final GlobalCommentsDeleteCommentUsecase deleteCommentUseCase;

  // Cache to store comments by post ID
  final Map<String, List<CommentEntity>> _commentsCache = {};
  List<CommentEntity> _allComments = [];

  GlobalCommentsBloc({
    required this.getCommentsUsecase,
    required this.addCommentUsecase,
    required this.getAllCommentsUseCase,
    required this.deleteCommentUseCase,
  }) : super(GlobalCommentsInitial()) {
    on<GetGlobalCommentsEvent>(_onGetComments);
    on<AddGlobalCommentEvent>(_onAddComment);
    on<GetAllGlobalCommentsEvent>(_onGetAllComments);
    on<DeleteGlobalCommentEvent>(_onDeleteComment);
  }

  Future<void> _onDeleteComment(
    DeleteGlobalCommentEvent event,
    Emitter<GlobalCommentsState> emit,
  ) async {
    final result = await deleteCommentUseCase(
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

    final result = await getAllCommentsUseCase(NoParams());
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
    final result = await getCommentsUsecase(event.posterId);
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
    final result = await addCommentUsecase(
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
}
