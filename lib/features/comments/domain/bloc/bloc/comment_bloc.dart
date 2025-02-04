import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';
import 'package:vandacoo/core/common/entities/comment_entity.dart';
import 'package:vandacoo/features/comments/domain/usecase/add_comment_usecase.dart';
import 'package:vandacoo/features/comments/domain/usecase/get_comment_usecase.dart';

part 'comment_event.dart';
part 'comment_state.dart';

class CommentBloc extends Bloc<CommentEvent, CommentState> {
  final GetCommentsUsecase getCommentsUsecase;
  final AddCommentUsecase addCommentUsecase;

  CommentBloc({
    required this.getCommentsUsecase,
    required this.addCommentUsecase,
  }) : super(CommentInitial()) {
    on<GetCommentsEvent>(_onGetComments);
    on<AddCommentEvent>(_onAddComment);
  }

  Future<void> _onGetComments(
    GetCommentsEvent event,
    Emitter<CommentState> emit,
  ) async {
    final result = await getCommentsUsecase(event.posterId);
    result.fold(
      (failure) => emit(CommentFailure(failure.message)),
      (comments) => emit(CommentDisplaySuccess(comments)),
    );
  }

  Future<void> _onAddComment(
    AddCommentEvent event,
    Emitter<CommentState> emit,
  ) async {
    emit(CommentLoading());
    final result = await addCommentUsecase(AddCommentParams(
      posterId: event.posterId,
      userId: event.userId,
      comment: event.comment,
    ));
    result.fold(
      (failure) => emit(CommentFailure(failure.message)),
      (comment) {
        add(GetCommentsEvent(event.posterId)); // Refresh comments after adding
      },
    );
  }
}
