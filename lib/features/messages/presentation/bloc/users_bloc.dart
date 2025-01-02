import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:meta/meta.dart';
import 'package:vandacoo/core/common/entities/user_entity.dart';
import 'package:vandacoo/core/error/failure.dart';
import 'package:vandacoo/core/usecase/usecase.dart';

import '../../domain/usecase/get_all_user_messages.dart';

part 'users_event.dart';
part 'users_state.dart';

class UsersBloc extends Bloc<UsersEvent, UsersState> {
  final GetAllUsersForMessageUseCase getAllUsers;

  UsersBloc({
    required this.getAllUsers,
  }) : super(UsersInitial()) {
    on<GetAllUsersEvent>(_onGetAllUsers);
  }

  Future<void> _onGetAllUsers(
    GetAllUsersEvent event,
    Emitter<UsersState> emit,
  ) async {
    emit(UsersLoading());
    final result = await getAllUsers(NoParams());

    result.fold(
      (failure) => emit(UsersFailure(_mapFailureToMessage(failure))),
      (users) => emit(UsersLoaded(users)),
    );
  }

  String _mapFailureToMessage(Failure failure) {
    return failure.message;
  }
}
