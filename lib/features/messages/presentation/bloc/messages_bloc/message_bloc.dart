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
    print('MessageBloc initialized with state: MessageInitial');
    on<SendMessageEvent>(_onSendMessage);
    on<FetchMessagesEvent>(_onFetchMessages);
    on<FetchAllMessagesEvent>(_onFetchAllMessages);
    on<DeleteMessageThreadEvent>(_onDeleteMessageThread);
    on<MarkMessageAsReadEvent>(_onMarkMessageAsRead);
    on<FetchAllUsersEvent>(_onFetchAllUsers);
    on<DeleteMessageEvent>(_onDeleteMessage);
  }

  @override
  void onChange(Change<MessageState> change) {
    super.onChange(change);
    print(
        'State changing from: ${change.currentState.runtimeType} to: ${change.nextState.runtimeType}');
    if (change.nextState is MessageLoaded) {
      final loadedState = change.nextState as MessageLoaded;
      print('MessageLoaded state details:');
      print('- Messages count: ${loadedState.messages.length}');
      print('- Users count: ${loadedState.users.length}');
      print(
          '- Users: ${loadedState.users.map((u) => "${u.name} (${u.id})").join(', ')}');
    } else if (change.nextState is UsersLoaded) {
      final usersState = change.nextState as UsersLoaded;
      print('UsersLoaded state details:');
      print('- Users count: ${usersState.users.length}');
      print(
          '- Users: ${usersState.users.map((u) => "${u.name} (${u.id})").join(', ')}');
    }
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
      (message) {
        // If we have existing messages and users, include them
        if (state is MessageLoaded) {
          final currentState = state as MessageLoaded;
          emit(MessageLoaded(
            messages: [...currentState.messages, message],
            users: currentState.users,
          ));
        } else {
          emit(MessageSent(message));
        }
      },
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
      (messages) async {
        // Get current users or fetch them if not available
        List<UserEntity> users = [];
        if (state is MessageLoaded) {
          users = (state as MessageLoaded).users;
        } else if (state is UsersLoaded) {
          users = (state as UsersLoaded).users;
        }
        emit(MessageLoaded(messages: messages, users: users));
      },
    );
  }

  Future<void> _onFetchAllMessages(
    FetchAllMessagesEvent event,
    Emitter<MessageState> emit,
  ) async {
    print('\n=== Starting _onFetchAllMessages ===');
    print('Current state: ${state.runtimeType}');

    // Store current users before emitting loading state
    List<UserEntity> users = [];
    if (state is UsersLoaded) {
      users = (state as UsersLoaded).users;
      print('Retrieved ${users.length} users from UsersLoaded state');
      print('Current users in UsersLoaded state:');
      for (var user in users) {
        print('- ${user.name} (${user.id})');
      }
    } else if (state is MessageLoaded) {
      users = (state as MessageLoaded).users;
      print('Retrieved ${users.length} users from MessageLoaded state');
      print('Current users in MessageLoaded state:');
      for (var user in users) {
        print('- ${user.name} (${user.id})');
      }
    } else {
      print('No users found in current state: ${state.runtimeType}');
    }

    print('Emitting MessageLoading state...');
    emit(MessageLoading());

    try {
      print('Fetching messages for user: ${event.userId}');
      final result = await getMessagesUsecase(GetMessagesParams(
        senderId: event.userId,
      ));

      await result.fold(
        (failure) async {
          print('❌ FetchAllMessages failed: ${failure.message}');
          emit(MessageFailure(_mapFailureToMessage(failure)));
        },
        (messages) async {
          print('✅ Messages fetched successfully:');
          print('- Total messages: ${messages.length}');
          for (var msg in messages) {
            print(
                '- Message from ${msg.senderId} to ${msg.receiverId}: ${msg.content.substring(0, msg.content.length.clamp(0, 20))}...');
          }

          if (users.isEmpty) {
            print('\n🔄 No users available, fetching users...');
            final usersResult = await getAllUsersUsecase(NoParams());
            await usersResult.fold(
              (failure) async {
                print('❌ FetchAllUsers failed: ${failure.message}');
                emit(MessageFailure(_mapFailureToMessage(failure)));
              },
              (fetchedUsers) async {
                users = fetchedUsers;
                print('✅ Users fetched successfully:');
                print('- Total users: ${users.length}');
                for (var user in users) {
                  print('- ${user.name} (${user.id})');
                }
                print('\nEmitting final MessageLoaded state with:');
                print('- ${messages.length} messages');
                print('- ${users.length} users');
                emit(MessageLoaded(messages: messages, users: users));
              },
            );
          } else {
            print('\n✅ Using existing users:');
            print('- Total users: ${users.length}');
            for (var user in users) {
              print('- ${user.name} (${user.id})');
            }
            print('\nEmitting final MessageLoaded state with:');
            print('- ${messages.length} messages');
            print('- ${users.length} users');
            emit(MessageLoaded(messages: messages, users: users));
          }
        },
      );
    } catch (e) {
      print('❌ Unexpected error in _onFetchAllMessages: $e');
      print('Stack trace: ${StackTrace.current}');
      emit(MessageFailure(e.toString()));
    }
    print('=== End _onFetchAllMessages ===\n');
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
    print('Starting mark message as read operation');
    emit(MessageLoading());

    try {
      final result = await markMessageReadUsecase(MarkMessageReadParams(
        messageId: event.messageId,
      ));

      result.fold(
        (failure) {
          print('Mark message as read failed: ${failure.message}');
          emit(MessageFailure(_mapFailureToMessage(failure)));
        },
        (_) {
          print('Message marked as read successfully');
          emit(MessageMarkedAsRead());
        },
      );
    } catch (e) {
      print('Unexpected error in _onMarkMessageAsRead: $e');
      emit(MessageFailure(e.toString()));
    }
  }

  Future<void> _onFetchAllUsers(
    FetchAllUsersEvent event,
    Emitter<MessageState> emit,
  ) async {
    print('\n=== Starting _onFetchAllUsers ===');
    print('Current state: ${state.runtimeType}');
    emit(MessageLoading());

    try {
      print('Fetching all users...');
      final result = await getAllUsersUsecase(NoParams());

      result.fold(
        (failure) {
          print('❌ FetchAllUsers failed: ${failure.message}');
          emit(MessageFailure(_mapFailureToMessage(failure)));
        },
        (users) {
          print('✅ Users fetched successfully:');
          print('- Total users: ${users.length}');
          for (var user in users) {
            print('- ${user.name} (${user.id})');
          }

          if (state is MessageLoaded) {
            final messages = (state as MessageLoaded).messages;
            print('Found existing messages: ${messages.length}');
            emit(MessageLoaded(messages: messages, users: users));
          } else {
            print('No existing messages, emitting UsersLoaded state');
            emit(UsersLoaded(users));
          }
        },
      );
    } catch (e) {
      print('❌ Unexpected error in _onFetchAllUsers: $e');
      print('Stack trace: ${StackTrace.current}');
      emit(MessageFailure(e.toString()));
    }
    print('=== End _onFetchAllUsers ===\n');
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
