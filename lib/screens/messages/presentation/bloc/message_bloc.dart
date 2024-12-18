import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:meta/meta.dart';
import 'package:vandacoo/screens/messages/domain/usecase/get_mesaages_usecase.dart';
import 'package:vandacoo/screens/messages/domain/usecase/send_message_usecase.dart';
import 'package:vandacoo/screens/messages/domain/entity/message_entity.dart';
import 'package:vandacoo/core/error/failure.dart';

part 'message_event.dart';
part 'message_state.dart';

class MessageBloc extends Bloc<MessageEvent, MessageState> {
  final SendMessageUsecase sendMessageUsecase;
  final GetMessagesUsecase getMessagesUsecase;

  MessageBloc({
    required this.sendMessageUsecase,
    required this.getMessagesUsecase,
  }) : super(MessageInitial()) {
    on<SendMessageEvent>(_onSendMessage);
    on<FetchMessagesEvent>(_onFetchMessages);
    on<FetchAllMessagesEvent>(_onFetchAllMessages);
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
    ));
    
    result.fold(
      (failure) => emit(MessageFailure(_mapFailureToMessage(failure))),
      (_) async {
        // After successful send, fetch all messages
        final messagesResult = await getMessagesUsecase(GetMessagesParams(
          senderId: event.senderId,
          receiverId: '',  // Empty to get all messages
        ));
        
        messagesResult.fold(
          (failure) => emit(MessageFailure(_mapFailureToMessage(failure))),
          (messages) => emit(MessageLoaded(messages)),
        );
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
      receiverId: event.receiverId ?? '',  // Handle null receiverId
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
      receiverId: '',
    ));
    result.fold(
      (failure) => emit(MessageFailure(_mapFailureToMessage(failure))),
      (messages) => emit(MessageLoaded(messages)),
    );
  }

  String _mapFailureToMessage(Failure failure) {
    return failure.message;
  }
}