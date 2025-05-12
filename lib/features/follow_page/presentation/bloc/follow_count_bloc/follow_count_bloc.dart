import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:vandacoo/features/follow_page/domain/entities/follow_entity.dart';
import 'package:vandacoo/features/follow_page/domain/usecases/get_user_counts_usecase.dart';

part 'follow_count_event.dart';
part 'follow_count_state.dart';

class FollowCountBloc extends Bloc<FollowCountEvent, FollowCountState> {
  final GetUserCountsUsecase getUserCountsUsecase;

  // Cache for user counts
  static final Map<String, FollowEntity> _userCountsCache = {};
  FollowEntity? getUserCounts(String userId) => _userCountsCache[userId];

  FollowCountBloc({
    required this.getUserCountsUsecase,
  }) : super(FollowCountInitial()) {
    on<GetUserCountsEvent>(_handleGetUserCounts);
  }

  Future<void> _handleGetUserCounts(
    GetUserCountsEvent event,
    Emitter<FollowCountState> emit,
  ) async {
    // If we have cached data, emit loading with cache
    if (_userCountsCache.containsKey(event.userId)) {
      emit(FollowCountLoadingCache(
          followEntity: _userCountsCache[event.userId]!));
    } else {
      emit(FollowCountLoading());
    }

    final result = await getUserCountsUsecase(
      GetUserCountsParams(userId: event.userId),
    );

    result.fold(
      (failure) => emit(FollowCountError(message: failure.message)),
      (followEntity) {
        // Update cache
        _userCountsCache[event.userId] = followEntity;
        emit(FollowCountLoaded(followEntity: followEntity));
      },
    );
  }
}
