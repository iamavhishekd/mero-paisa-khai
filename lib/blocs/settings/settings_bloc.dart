import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:paisa_khai/hive/hive_service.dart';
import 'package:paisa_khai/services/notification_service.dart';

part 'settings_event.dart';
part 'settings_state.dart';

class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {
  SettingsBloc() : super(_getInitialState()) {
    on<LoadSettings>(_onLoadSettings);
    on<UpdateThemeMode>(_onUpdateThemeMode);
    on<ClearAllAppData>(_onClearAllAppData);
    on<CompleteOnboarding>(_onCompleteOnboarding);
    on<UpdateNotificationSettings>(_onUpdateNotificationSettings);

    add(LoadSettings());
  }

  static SettingsState _getInitialState() {
    final box = HiveService.settingsBoxInstance;
    final savedIndex = box.get('theme_mode_index', defaultValue: 0) as int;
    final hasSeenOnboarding =
        box.get('has_seen_onboarding', defaultValue: false) as bool;
    final notificationsEnabled =
        box.get('notifications_enabled', defaultValue: true) as bool;
    final notificationHour =
        box.get('notification_hour', defaultValue: 20) as int;
    final notificationMinute =
        box.get('notification_minute', defaultValue: 0) as int;

    return SettingsState(
      themeMode: ThemeMode.values[savedIndex],
      hasSeenOnboarding: hasSeenOnboarding,
      notificationsEnabled: notificationsEnabled,
      notificationHour: notificationHour,
      notificationMinute: notificationMinute,
    );
  }

  void _onLoadSettings(LoadSettings event, Emitter<SettingsState> emit) {
    emit(_getInitialState());
  }

  Future<void> _onUpdateThemeMode(
    UpdateThemeMode event,
    Emitter<SettingsState> emit,
  ) async {
    await HiveService.settingsBoxInstance.put(
      'theme_mode_index',
      event.themeMode.index,
    );
    emit(state.copyWith(themeMode: event.themeMode));
  }

  Future<void> _onCompleteOnboarding(
    CompleteOnboarding event,
    Emitter<SettingsState> emit,
  ) async {
    await HiveService.settingsBoxInstance.put('has_seen_onboarding', true);
    emit(state.copyWith(hasSeenOnboarding: true));
  }

  Future<void> _onUpdateNotificationSettings(
    UpdateNotificationSettings event,
    Emitter<SettingsState> emit,
  ) async {
    final box = HiveService.settingsBoxInstance;
    final newState = state.copyWith(
      notificationsEnabled: event.enabled,
      notificationHour: event.hour,
      notificationMinute: event.minute,
    );

    await box.put('notifications_enabled', newState.notificationsEnabled);
    await box.put('notification_hour', newState.notificationHour);
    await box.put('notification_minute', newState.notificationMinute);

    emit(newState);

    // Reschedule notifications
    if (newState.notificationsEnabled) {
      await NotificationService().scheduleDailyReminder(
        hour: newState.notificationHour,
        minute: newState.notificationMinute,
      );
    } else {
      await NotificationService().cancelAllNotifications();
    }
  }

  Future<void> _onClearAllAppData(
    ClearAllAppData event,
    Emitter<SettingsState> emit,
  ) async {
    await HiveService.clearAndReset();
  }
}
