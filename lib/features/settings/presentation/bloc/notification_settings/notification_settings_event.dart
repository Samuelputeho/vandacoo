import 'package:equatable/equatable.dart';

abstract class NotificationSettingsEvent extends Equatable {
  const NotificationSettingsEvent();

  @override
  List<Object?> get props => [];
}

class NotificationSettingsLoadRequested extends NotificationSettingsEvent {
  const NotificationSettingsLoadRequested();
}

class NotificationSettingsToggleRequested extends NotificationSettingsEvent {
  final bool enable;
  const NotificationSettingsToggleRequested({required this.enable});

  @override
  List<Object?> get props => [enable];
}
