import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:vandacoo/core/common/entities/user_entity.dart';
import 'package:vandacoo/features/profile/domain/usecases/get_user_info_usecase.dart';

part 'profile_event.dart';
part 'profile_state.dart';

class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  final GetUserInfoUsecase getUserInfoUsecase;

  // Cache the current user
  static UserEntity _currentUser = UserEntity.empty;
  UserEntity get currentUser => _currentUser;

  ProfileBloc({
    required this.getUserInfoUsecase,
  }) : super(ProfileInitial()) {
    on<GetUserInfoEvent>(_handleGetUserInfo);
  }

  Future<void> _handleGetUserInfo(
    GetUserInfoEvent event,
    Emitter<ProfileState> emit,
  ) async {
    // If we have cached data, emit loading with cache
    if (_currentUser != UserEntity.empty) {
      emit(ProfileLoadingCache(user: _currentUser));
    } else {
      emit(ProfileLoading());
    }

    final result = await getUserInfoUsecase(
      GetUserInfoParams(userId: event.userId),
    );

    result.fold(
      (failure) => emit(ProfileError(message: failure.message)),
      (user) {
        // Update cache
        _currentUser = user;
        emit(ProfileUserLoaded(user: user));
      },
    );
  }
}
