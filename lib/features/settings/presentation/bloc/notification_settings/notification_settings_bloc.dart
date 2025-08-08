import 'package:bloc/bloc.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_app_badger/flutter_app_badger.dart';

import '../../../../../core/utils/shared_preferences_with_cache.dart';
import 'notification_settings_event.dart';
import 'notification_settings_state.dart';

class NotificationSettingsBloc
    extends Bloc<NotificationSettingsEvent, NotificationSettingsState> {
  static const String _prefsKey = 'push_notifications_enabled';
  final SharedPreferencesWithCache _prefs;

  NotificationSettingsBloc(this._prefs)
      : super(NotificationSettingsState.initial()) {
    on<NotificationSettingsLoadRequested>(_onLoad);
    on<NotificationSettingsToggleRequested>(_onToggle);
  }

  Future<void> _onLoad(NotificationSettingsLoadRequested event,
      Emitter<NotificationSettingsState> emit) async {
    emit(state.copyWith(isLoading: true));
    final stored = _prefs.getBool(_prefsKey) ?? false;
    emit(state.copyWith(isLoading: false, pushEnabled: stored));
  }

  Future<void> _onToggle(NotificationSettingsToggleRequested event,
      Emitter<NotificationSettingsState> emit) async {
    emit(state.copyWith(isLoading: true));
    if (event.enable) {
      final status = await Permission.notification.status;
      if (status.isDenied || status.isRestricted) {
        final result = await Permission.notification.request();
        if (!result.isGranted) {
          await _prefs.setBool(_prefsKey, false);
          emit(state.copyWith(
              isLoading: false,
              pushEnabled: false,
              message: 'Notification permission denied'));
          return;
        }
      } else if (status.isPermanentlyDenied) {
        emit(state.copyWith(
            isLoading: false,
            pushEnabled: false,
            message: 'Notifications are blocked. Enable them in Settings.'));
        await openAppSettings();
        final after = await Permission.notification.status;
        if (!after.isGranted) {
          await _prefs.setBool(_prefsKey, false);
          return;
        }
      }
      await _prefs.setBool(_prefsKey, true);
      emit(state.copyWith(isLoading: false, pushEnabled: true));
    } else {
      await _prefs.setBool(_prefsKey, false);
      FlutterAppBadger.removeBadge();
      emit(state.copyWith(isLoading: false, pushEnabled: false));
    }
  }
}
