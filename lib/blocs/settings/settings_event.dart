part of 'settings_bloc.dart';

abstract class SettingsEvent extends Equatable {
  const SettingsEvent();

  @override
  List<Object?> get props => [];
}

class LoadSettings extends SettingsEvent {}

class UpdateThemeMode extends SettingsEvent {
  final ThemeMode themeMode;
  const UpdateThemeMode(this.themeMode);

  @override
  List<Object?> get props => [themeMode];
}

class UpdateNotificationSettings extends SettingsEvent {
  final bool? enabled;
  final int? hour;
  final int? minute;

  const UpdateNotificationSettings({this.enabled, this.hour, this.minute});

  @override
  List<Object?> get props => [enabled, hour, minute];
}

class ClearAllAppData extends SettingsEvent {}

class CompleteOnboarding extends SettingsEvent {}
