part of 'feeds_bloc.dart';

sealed class FeedsState extends Equatable {
  const FeedsState();

  @override
  List<Object> get props => [];
}

final class FeedsInitial extends FeedsState {}

final class FeedsPostLoading extends FeedsState {}

final class FeedsPostSuccess extends FeedsState {
  final String message;

  const FeedsPostSuccess(this.message);

  @override
  List<Object> get props => [message];
}

final class FeedsPostFailure extends FeedsState {
  final String message;

  const FeedsPostFailure(this.message);

  @override
  List<Object> get props => [message];
}
