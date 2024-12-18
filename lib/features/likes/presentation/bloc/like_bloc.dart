import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vandacoo/features/likes/domain/repository/like_repository.dart';

part 'like_event.dart';
part 'like_state.dart';

class LikeBloc extends Bloc<LikeEvent, Map<String, LikeState>> {
  final LikeRepository likeRepository;

  LikeBloc({required this.likeRepository}) : super({}) {
    on<ToggleLikeEvent>(_onToggleLike);
    on<GetLikesEvent>(_onGetLikes);
  }

  Future<void> _onToggleLike(
    ToggleLikeEvent event,
    Emitter<Map<String, LikeState>> emit,
  ) async {
    try {
      final currentState = Map<String, LikeState>.from(state);
      currentState[event.postId] = LikeLoading(event.postId);
      emit(currentState);

      final result = await likeRepository.toggleLike(event.postId, event.userId);
      result.fold(
        (failure) {
          final newState = Map<String, LikeState>.from(state);
          newState[event.postId] = LikeFailure(
            postId: event.postId,
            message: failure.message,
          );
          emit(newState);
        },
        (_) => add(GetLikesEvent(event.postId)),
      );
    } catch (e) {
      final newState = Map<String, LikeState>.from(state);
      newState[event.postId] = LikeFailure(
        postId: event.postId,
        message: e.toString(),
      );
      emit(newState);
    }
  }

  Future<void> _onGetLikes(
    GetLikesEvent event,
    Emitter<Map<String, LikeState>> emit,
  ) async {
    try {
      final currentState = Map<String, LikeState>.from(state);
      currentState[event.postId] = LikeLoading(event.postId);
      emit(currentState);

      final result = await likeRepository.getLikes(event.postId);
      result.fold(
        (failure) {
          final newState = Map<String, LikeState>.from(state);
          newState[event.postId] = LikeFailure(
            postId: event.postId,
            message: failure.message,
          );
          emit(newState);
        },
        (likes) {
          final newState = Map<String, LikeState>.from(state);
          newState[event.postId] = LikeSuccess(
            postId: event.postId,
            likedByUsers: likes,
          );
          emit(newState);
        },
      );
    } catch (e) {
      final newState = Map<String, LikeState>.from(state);
      newState[event.postId] = LikeFailure(
        postId: event.postId,
        message: e.toString(),
      );
      emit(newState);
    }
  }
}