import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vandacoo/core/common/cubits/app_user/app_user_cubit.dart';
import 'package:vandacoo/core/common/entities/user_entity.dart';
import 'package:vandacoo/core/usecase/usecase.dart';
import 'package:vandacoo/features/auth/domain/usecase/current_user.dart';
import 'package:vandacoo/features/auth/domain/usecase/user_login.dart';
import 'package:vandacoo/features/auth/domain/usecase/user_sign_up.dart';
import 'package:vandacoo/features/auth/domain/usecase/get_all_users.dart';
import 'package:vandacoo/features/auth/domain/usecase/logout_usecase.dart';
import 'package:vandacoo/features/auth/domain/usecase/update_user_usecase.dart';

part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final UserSignUp _userSignUp;
  final UserLogin _userLogin;
  final CurrentUser _currentUser;
  final GetAllUsers _getAllUsers;
  final LogoutUsecase _logoutUsecase;
  final AppUserCubit _appUserCubit;
  final UpdateUserProfile _updateUserProfile;

  AuthBloc({
    required UserSignUp userSignUp,
    required UserLogin userLogin,
    required CurrentUser currentUser,
    required GetAllUsers getAllUsers,
    required LogoutUsecase logoutUsecase,
    required AppUserCubit appUserCubit,
    required UpdateUserProfile updateUserProfile,
  })  : _userSignUp = userSignUp,
        _userLogin = userLogin,
        _currentUser = currentUser,
        _getAllUsers = getAllUsers,
        _logoutUsecase = logoutUsecase,
        _appUserCubit = appUserCubit,
        _updateUserProfile = updateUserProfile,
        super(AuthInitial()) {
    on<AuthEvent>((_, emit) => emit(AuthLoading()));
    on<AuthSignUp>(_onAuthSignUp);
    on<AuthLogin>(_onAuthLogin);
    on<AuthIsUserLoggedIn>(_isUserLoggedIn);
    on<AuthGetAllUsers>(_onGetAllUsers);
    on<AuthUpdateProfile>(_onAuthUpdateProfile);
    on<AuthLogout>(_onAuthLogout);
  }

  void _isUserLoggedIn(
    AuthIsUserLoggedIn event,
    Emitter<AuthState> emit,
  ) async {
    final res = await _currentUser(NoParams());

    res.fold(
      (l) => emit(AuthFailure(l.message)),
      (r) => _emitAuthSuccess(r, emit),
    );
  }

  void _onAuthSignUp(AuthSignUp event, Emitter<AuthState> emit) async {
    final res = await _userSignUp(
      UserSignUpParams(
        password: event.password,
        name: event.name,
        email: event.email,
      ),
    );

    res.fold(
      (failure) => emit(AuthFailure(failure.message)),
      (user) => _emitAuthSuccess(user, emit),
    );
  }

  void _onAuthLogin(AuthLogin event, Emitter<AuthState> emit) async {
    final res = await _userLogin(
      UserLoginParams(
        email: event.email,
        password: event.password,
      ),
    );

    res.fold(
      (l) => emit(AuthFailure(l.message)),
      (r) => _emitAuthSuccess(r, emit),
    );
  }

  void _emitAuthSuccess(UserEntity user, Emitter<AuthState> emit) {
    _appUserCubit.updateUser(user);
    emit(AuthSuccess(user));
  }

  Future<void> _onGetAllUsers(
    AuthGetAllUsers event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    final result = await _getAllUsers(NoParams());
    result.fold(
      (failure) => emit(AuthFailure(failure.message)),
      (users) => emit(AuthUsersLoaded(users)),
    );
  }

  void _onAuthLogout(AuthLogout event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    final res = await _logoutUsecase();

    res.fold(
      (failure) => emit(AuthFailure(failure.message)),
      (_) {
        _appUserCubit.updateUser(null); // Clear user data
        emit(AuthInitial()); // Reset to initial state
      },
    );
  }

  void _onAuthUpdateProfile(
      AuthUpdateProfile event, Emitter<AuthState> emit) async {
    emit(AuthLoading());

    try {
      print('Starting profile update...');
      // Get current user data to preserve unchanged fields
      final currentUser = (_appUserCubit.state as AppUserLoggedIn).user;

      final res = await _updateUserProfile(UpdateUserProfileParams(
        userId: event.userId,
        name: event.name ?? currentUser.name,
        email: event.email ?? currentUser.email,
        bio: event.bio ?? currentUser.bio,
        imagePath: event.imagePath,
      ));

      res.fold(
        (failure) {
          print('Update failed: ${failure.message}');
          emit(AuthFailure(failure.message));
        },
        (_) {
          // Create mutable user variable
          var updatedUser = UserEntity(
            id: event.userId,
            email: event.email ?? currentUser.email,
            name: event.name ?? currentUser.name,
            bio: event.bio ?? currentUser.bio,
            propic: currentUser.propic, // Keep existing propic if no new image
          );

          // Only update propic if a new image was provided
          if (event.imagePath != null) {
            updatedUser = UserEntity(
              id: updatedUser.id,
              email: updatedUser.email,
              name: updatedUser.name,
              bio: updatedUser.bio,
              propic: event.imagePath!.path,
            );
          }

          print('Update successful');
          _appUserCubit.updateUser(updatedUser);
          emit(AuthSuccess(updatedUser));
        },
      );
    } catch (e) {
      print('Error in _onAuthUpdateProfile: $e');
      emit(AuthFailure(e.toString()));
    }
  }
}
