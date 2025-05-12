import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../domain/usecases/follow_user_usecase.dart';
import '../../../domain/usecases/unfollow_user_usecase.dart';
import '../../../domain/usecases/is_following.dart';

part 'follow_page_event.dart';
part 'follow_page_state.dart';

class FollowPageBloc extends Bloc<FollowPageEvent, FollowPageState> {
  final FollowUserUsecase followUserUsecase;
  final UnfollowUserUsecase unfollowUserUsecase;
  final IsFollowingUseCase isFollowingUseCase;

  // Cache for following status
  static final Map<String, bool> _followingStatusCache = {};
  bool isFollowing(String followerId, String followingId) =>
      _followingStatusCache['${followerId}_$followingId'] ?? false;

  FollowPageBloc({
    required this.followUserUsecase,
    required this.unfollowUserUsecase,
    required this.isFollowingUseCase,
  }) : super(FollowPageInitial()) {
    on<FollowUserEvent>(_onFollowUser);
    on<UnfollowUserEvent>(_onUnfollowUser);
    on<CheckIsFollowingEvent>(_onCheckIsFollowing);
  }

  Future<void> _onCheckIsFollowing(
    CheckIsFollowingEvent event,
    Emitter<FollowPageState> emit,
  ) async {
    final cacheKey = '${event.followerId}_${event.followingId}';

    // If we have cached status, emit loading with cache
    if (_followingStatusCache.containsKey(cacheKey)) {
      emit(FollowPageLoadingCache(
          isFollowing: _followingStatusCache[cacheKey]!));
    } else {
      emit(FollowPageLoading());
    }

    final result = await isFollowingUseCase(
      IsFollowingParams(
        followerId: event.followerId,
        followingId: event.followingId,
      ),
    );

    result.fold(
      (failure) => emit(FollowPageError(failure.message)),
      (isFollowing) {
        // Update cache
        _followingStatusCache[cacheKey] = isFollowing;
        emit(IsFollowingState(isFollowing));
      },
    );
  }

  Future<void> _onFollowUser(
    FollowUserEvent event,
    Emitter<FollowPageState> emit,
  ) async {
    emit(FollowPageLoading());

    final result = await followUserUsecase(
      FollowUserParams(
        followerId: event.followerId,
        followingId: event.followingId,
      ),
    );

    result.fold(
      (failure) => emit(FollowPageError(failure.message)),
      (_) {
        // Update cache
        _followingStatusCache['${event.followerId}_${event.followingId}'] =
            true;
        emit(FollowPageSuccess());
      },
    );
  }

  Future<void> _onUnfollowUser(
    UnfollowUserEvent event,
    Emitter<FollowPageState> emit,
  ) async {
    emit(FollowPageLoading());

    final result = await unfollowUserUsecase(
      UnfollowUserParams(
        followerId: event.followerId,
        followingId: event.followingId,
      ),
    );

    result.fold(
      (failure) => emit(FollowPageError(failure.message)),
      (_) {
        // Update cache
        _followingStatusCache['${event.followerId}_${event.followingId}'] =
            false;
        emit(FollowPageSuccess());
      },
    );
  }
}
