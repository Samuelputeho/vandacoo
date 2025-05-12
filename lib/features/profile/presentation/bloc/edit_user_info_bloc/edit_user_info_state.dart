part of 'edit_user_info_bloc.dart';

sealed class EditUserInfoState extends Equatable {
  const EditUserInfoState();

  @override
  List<Object> get props => [];
}

final class EditUserInfoInitial extends EditUserInfoState {}

final class EditUserInfoLoading extends EditUserInfoState {}

final class EditUserInfoError extends EditUserInfoState {
  final String message;

  const EditUserInfoError({required this.message});

  @override
  List<Object> get props => [message];
}

final class EditUserInfoSuccess extends EditUserInfoState {}
