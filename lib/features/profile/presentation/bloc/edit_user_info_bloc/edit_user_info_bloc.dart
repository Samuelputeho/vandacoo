import 'dart:io';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:vandacoo/features/profile/domain/usecases/edit_user_info_usecase.dart';
import 'package:vandacoo/core/error/failure.dart';
import 'package:vandacoo/core/common/entities/user_entity.dart';

part 'edit_user_info_event.dart';
part 'edit_user_info_state.dart';

class EditUserInfoBloc extends Bloc<EditUserInfoEvent, EditUserInfoState> {
  final EditUserInfoUsecase editUserInfoUsecase;

  EditUserInfoBloc({required this.editUserInfoUsecase}) : super(EditUserInfoInitial()) {
    on<UpdateUserInfoEvent>(_handleEditUserInfo);
  }

  Future<void> _handleEditUserInfo(
    UpdateUserInfoEvent event,
    Emitter<EditUserInfoState> emit,
  ) async {
    emit(EditUserInfoLoading());

    // Start the process of editing user info (name, bio, email, or profile picture)
    try {
      final result = await editUserInfoUsecase(EditUserInfoParams(
        userId: event.userId,
        name: event.name,
        bio: event.bio,
        email: event.email,
        propicFile: event.propicFile,
      ));

      result.fold(
        (failure) {
          emit(EditUserInfoError(message: failure.message));
        },
        (_) {
          emit(EditUserInfoSuccess());
        },
      );
    } catch (e) {
      emit(EditUserInfoError(message: e.toString()));
    }
  }
}
