import 'dart:io';

import 'package:flutter_bloc/flutter_bloc.dart';
// ignore: depend_on_referenced_packages
import 'package:meta/meta.dart';
import 'package:vandacoo/core/common/entities/user_entity.dart';
import 'package:vandacoo/core/usecase/usecase.dart';
import 'package:vandacoo/features/messages/domain/usecase/delete_message_thread_usecase.dart';
import 'package:vandacoo/features/messages/domain/usecase/delete_message_usecase.dart';
import 'package:vandacoo/features/messages/domain/usecase/get_all_users_for_message.dart';
import 'package:vandacoo/features/messages/domain/usecase/get_mesaages_usecase.dart';
import 'package:vandacoo/features/messages/domain/usecase/mark_message_read_usecase.dart';
import 'package:vandacoo/features/messages/domain/usecase/send_message_usecase.dart';
import 'package:vandacoo/features/messages/domain/entity/message_entity.dart';
import 'package:vandacoo/core/error/failure.dart';

import '../../../domain/usecase/delete_message_usecase.dart';

part 'message_event.dart';
part 'message_state.dart';

class MessageBloc extends Bloc<MessageEvent, MessageState> {
  final SendMessageUsecase sendMessageUsecase;
  final GetMessagesUsecase getMessagesUsecase;
  final DeleteMessageThreadUsecase deleteMessageThreadUsecase;
  final MarkMessageReadUsecase markMessageReadUsecase;
  final GetAllUsersForMessageUseCase getAllUsersUsecase;
  final DeleteMessageUsecase deleteMessageUsecase;

  MessageBloc({
    required this.sendMessageUsecase,
    required this.getMessagesUsecase,
    required this.deleteMessageThreadUsecase,
    required this.markMessageReadUsecase,
    required this.getAllUsersUsecase,
    required this.deleteMessageUsecase,
  }) : super(MessageInitial()) {
    on<SendMessageEvent>(_onSendMessage);
    on<FetchMessagesEvent>(_onFetchMessages);
    on<FetchAllMessagesEvent>(_onFetchAllMessages);
    on<DeleteMessageThreadEvent>(_onDeleteMessageThread);
    on<MarkMessageAsReadEvent>(_onMarkMessageAsRead);
    on<FetchAllUsersEvent>(_onFetchAllUsers);
    on<DeleteMessageEvent>(_onDeleteMessage);
  }

  Future<void> _onSendMessage(
    SendMessageEvent event,
    Emitter<MessageState> emit,
  ) async {
    emit(MessageLoading());
    final result = await sendMessageUsecase(SendMessageParams(
      senderId: event.senderId,
      receiverId: event.receiverId,
      content: event.content,
      messageType: event.messageType,
      mediaFile: event.mediaFile,
    ));

    result.fold(
      (failure) => emit(MessageFailure(_mapFailureToMessage(failure))),
      (message) => emit(MessageSent(message)),
    );
  }

  Future<void> _onFetchMessages(
    FetchMessagesEvent event,
    Emitter<MessageState> emit,
  ) async {
    emit(MessageLoading());
    final result = await getMessagesUsecase(GetMessagesParams(
      senderId: event.senderId,
      receiverId: event.receiverId,
    ));
    result.fold(
      (failure) => emit(MessageFailure(_mapFailureToMessage(failure))),
      (messages) => emit(MessageLoaded(messages)),
    );
  }

  Future<void> _onFetchAllMessages(
    FetchAllMessagesEvent event,
    Emitter<MessageState> emit,
  ) async {
    emit(MessageLoading());
    final result = await getMessagesUsecase(GetMessagesParams(
      senderId: event.userId,
    ));
    result.fold(
      (failure) => emit(MessageFailure(_mapFailureToMessage(failure))),
      (messages) => emit(MessageLoaded(messages)),
    );
  }

  Future<void> _onDeleteMessageThread(
    DeleteMessageThreadEvent event,
    Emitter<MessageState> emit,
  ) async {
    print('Starting delete message thread operation');
    emit(MessageLoading());

    final result = await deleteMessageThreadUsecase(DeleteMessageThreadParams(
      userId: event.userId,
      otherUserId: event.otherUserId,
    ));

    result.fold(
      (failure) {
        print('Delete thread failed: ${failure.message}');
        emit(MessageFailure(_mapFailureToMessage(failure)));
      },
      (_) {
        print('Delete thread successful, emitting MessageThreadDeleted state');
        emit(MessageThreadDeleted());
      },
    );
  }

  Future<void> _onMarkMessageAsRead(
    MarkMessageAsReadEvent event,
    Emitter<MessageState> emit,
  ) async {
    emit(MessageLoading());
    final result = await markMessageReadUsecase(MarkMessageReadParams(
      messageId: event.messageId,
    ));
    result.fold(
      (failure) => emit(MessageFailure(_mapFailureToMessage(failure))),
      (_) => emit(MessageMarkedAsRead()),
    );
  }

  Future<void> _onFetchAllUsers(
    FetchAllUsersEvent event,
    Emitter<MessageState> emit,
  ) async {
    emit(MessageLoading());
    final result = await getAllUsersUsecase(NoParams());
    result.fold(
      (failure) => emit(MessageFailure(_mapFailureToMessage(failure))),
      (users) => emit(UsersLoaded(users)),
    );
  }

  Future<void> _onDeleteMessage(
    DeleteMessageEvent event,
    Emitter<MessageState> emit,
  ) async {
    print('Starting delete message operation');
    emit(MessageLoading());

    final result = await deleteMessageUsecase(DeleteMessageParams(
      messageId: event.messageId,
      userId: event.userId,
    ));

    result.fold(
      (failure) {
        print('Delete message failed: ${failure.message}');
        emit(MessageFailure(_mapFailureToMessage(failure)));
      },
      (_) {
        print('Delete message successful');
        emit(MessageDeleted(event.messageId));
      },
    );
  }

  String _mapFailureToMessage(Failure failure) {
    return failure.message;
  }
}
