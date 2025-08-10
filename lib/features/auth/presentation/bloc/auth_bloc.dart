import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vandacoo/core/common/cubits/app_user/app_user_cubit.dart';
import 'package:vandacoo/core/common/entities/user_entity.dart';
import 'package:vandacoo/core/usecase/usecase.dart';
import 'package:vandacoo/core/common/models/user_model.dart';
import 'package:vandacoo/features/auth/domain/usecase/check_user_status_usecase.dart';
import 'package:vandacoo/features/auth/domain/usecase/current_user.dart';
import 'package:vandacoo/features/auth/domain/usecase/user_login.dart';
import 'package:vandacoo/features/auth/domain/usecase/user_sign_up.dart';
import 'package:vandacoo/features/auth/domain/usecase/get_all_users.dart';
import 'package:vandacoo/features/auth/domain/usecase/logout_usecase.dart';
import 'package:vandacoo/features/auth/domain/usecase/update_user_usecase.dart';
import 'package:vandacoo/features/auth/domain/usecase/update_has_seen_intro_video_usecase.dart';
import 'package:vandacoo/features/auth/domain/usecase/send_password_reset_token_usecase.dart';
import 'package:vandacoo/features/auth/domain/usecase/reset_password_with_token_usecase.dart';

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
  final UpdateHasSeenIntroVideo _updateHasSeenIntroVideo;
  final CheckUserStatus _checkUserStatus;
  final SendPasswordResetTokenUseCase _sendPasswordResetToken;
  final ResetPasswordWithTokenUseCase _resetPasswordWithToken;

  AuthBloc({
    required UserSignUp userSignUp,
    required UserLogin userLogin,
    required CurrentUser currentUser,
    required GetAllUsers getAllUsers,
    required LogoutUsecase logoutUsecase,
    required AppUserCubit appUserCubit,
    required UpdateUserProfile updateUserProfile,
    required UpdateHasSeenIntroVideo updateHasSeenIntroVideo,
    required CheckUserStatus checkUserStatus,
    required SendPasswordResetTokenUseCase sendPasswordResetToken,
    required ResetPasswordWithTokenUseCase resetPasswordWithToken,
  })  : _userSignUp = userSignUp,
        _userLogin = userLogin,
        _currentUser = currentUser,
        _getAllUsers = getAllUsers,
        _logoutUsecase = logoutUsecase,
        _appUserCubit = appUserCubit,
        _updateUserProfile = updateUserProfile,
        _updateHasSeenIntroVideo = updateHasSeenIntroVideo,
        _checkUserStatus = checkUserStatus,
        _sendPasswordResetToken = sendPasswordResetToken,
        _resetPasswordWithToken = resetPasswordWithToken,
        super(AuthInitial()) {
    on<AuthSignUp>(_onAuthSignUp);
    on<AuthLogin>(_onAuthLogin);
    on<AuthIsUserLoggedIn>(_isUserLoggedIn);
    on<AuthGetAllUsers>(_onGetAllUsers);
    on<AuthUpdateProfile>(_onAuthUpdateProfile);
    on<AuthLogout>(_onAuthLogout);
    on<AuthUpdateHasSeenVideo>(_onAuthUpdateHasSeenVideo);
    on<AuthCheckUserStatus>(_onCheckUserStatus);
    on<AuthSendPasswordResetToken>(_onSendPasswordResetToken);
    on<AuthResetPasswordWithToken>(_onResetPasswordWithToken);
  }

  Future<void> _isUserLoggedIn(
    AuthIsUserLoggedIn event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    final res = await _currentUser(NoParams());

    await res.fold(
      (l) async {
        // Check if this is a network error - if so, don't immediately fail auth
        if (l.message.toLowerCase().contains('network connection issue') ||
            l.message.toLowerCase().contains('connection timeout')) {
          // For network issues, keep the current user state if they exist
          final currentUserState = _appUserCubit.state;
          if (currentUserState is AppUserLoggedIn) {
            // User was previously authenticated, just show network error but don't log out
            emit(AuthSuccess(currentUserState.user));
            return;
          }
        }
        emit(AuthFailure(l.message));
      },
      (user) async {
        // Check if the user's status is active
        final statusRes =
            await _checkUserStatus(CheckUserStatusParams(userId: user.id));

        await statusRes.fold((l) async {
          // Check if status check failed due to network issues
          if (l.message.toLowerCase().contains('network connection issue') ||
              l.message.toLowerCase().contains('connection timeout')) {
            // Network issue during status check - assume user is still valid
            _emitAuthSuccess(user, emit);
            return;
          }
          _appUserCubit.updateUser(null);
          emit(AuthFailure(l.message));
        }, (isActive) async {
          if (isActive) {
            _emitAuthSuccess(user, emit);
          } else {
            // Log the user out if their status is not active
            await _logoutUsecase();
            _appUserCubit.updateUser(null);
            emit(AuthFailure('Account is not active. Please contact support.'));
          }
        });
      },
    );
  }

  Future<void> _onCheckUserStatus(
    AuthCheckUserStatus event,
    Emitter<AuthState> emit,
  ) async {
    final res =
        await _checkUserStatus(CheckUserStatusParams(userId: event.userId));

    await res.fold(
      (l) async {
        // Check if this is a network error - if so, don't log out user
        if (l.message.toLowerCase().contains('network connection issue') ||
            l.message.toLowerCase().contains('connection timeout')) {
          // Network issue during status check - keep current state
          return;
        }
        emit(AuthFailure(l.message));
      },
      (isActive) async {
        if (!isActive) {
          // Log the user out if their status is not active
          await _logoutUsecase();
          _appUserCubit.updateUser(null);
          emit(AuthFailure('Account is not active. Please contact support.'));
        }
      },
    );
  }

  void _onAuthSignUp(AuthSignUp event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    final res = await _userSignUp(
      UserSignUpParams(
        password: event.password,
        name: event.name,
        email: event.email,
        accountType: event.accountType,
        gender: event.gender,
        age: event.age,
      ),
    );

    res.fold(
      (failure) => emit(AuthFailure(failure.message)),
      (user) => _emitAuthSuccess(user, emit),
    );
  }

  void _onAuthLogin(AuthLogin event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
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
      final result = await _updateUserProfile(
        UpdateUserProfileParams(
          userId: event.userId,
          name: event.name,
          email: event.email,
          bio: event.bio,
          imagePath: event.imagePath,
        ),
      );

      result.fold(
        (failure) {
          emit(AuthFailure(failure.message));
        },
        (_) {
          // Get current user data to update the state
          final currentUser = (_appUserCubit.state as AppUserLoggedIn).user;
          // Create updated user with new data
          final updatedUser = UserModel(
            id: currentUser.id,
            name: event.name ?? currentUser.name,
            email: event.email ?? currentUser.email,
            bio: event.bio ?? currentUser.bio,
            propic: event.imagePath?.path ?? currentUser.propic,
            hasSeenIntroVideo: currentUser.hasSeenIntroVideo,
            accountType: currentUser.accountType,
            gender: currentUser.gender,
            age: currentUser.age,
          );
          _appUserCubit.updateUser(updatedUser);
          emit(AuthSuccess(updatedUser));
        },
      );
    } catch (e) {
      emit(AuthFailure(e.toString()));
    }
  }

  void _onAuthUpdateHasSeenVideo(
    AuthUpdateHasSeenVideo event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    final result = await _updateHasSeenIntroVideo(event.userId);
    result.fold(
      (failure) => emit(AuthFailure(failure.message)),
      (_) {
        // Get current user data to update the state
        final currentUser = (_appUserCubit.state as AppUserLoggedIn).user;
        // Create updated user with hasSeenIntroVideo set to true
        final updatedUser = UserModel(
          id: currentUser.id,
          name: currentUser.name,
          email: currentUser.email,
          bio: currentUser.bio,
          propic: currentUser.propic,
          hasSeenIntroVideo: true,
          accountType: currentUser.accountType,
          gender: currentUser.gender,
          age: currentUser.age,
        );
        _appUserCubit.updateUser(updatedUser);
        emit(AuthSuccess(updatedUser));
      },
    );
  }

  void _onSendPasswordResetToken(
    AuthSendPasswordResetToken event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    final result = await _sendPasswordResetToken(
      SendPasswordResetTokenParams(email: event.email),
    );

    result.fold(
      (failure) => emit(AuthFailure(failure.message)),
      (_) => emit(AuthPasswordResetTokenSent()),
    );
  }

  void _onResetPasswordWithToken(
    AuthResetPasswordWithToken event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    final result = await _resetPasswordWithToken(
      ResetPasswordWithTokenParams(
        email: event.email,
        token: event.token,
        newPassword: event.newPassword,
      ),
    );

    result.fold(
      (failure) => emit(AuthFailure(failure.message)),
      (_) => emit(AuthPasswordResetSuccess()),
    );
  }
}
