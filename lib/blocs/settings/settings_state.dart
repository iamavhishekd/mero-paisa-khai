part of 'settings_bloc.dart';

class SettingsState extends Equatable {
  final ThemeMode themeMode;
  final bool hasSeenOnboarding;
  final bool notificationsEnabled;
  final int notificationHour;
  final int notificationMinute;

  const SettingsState({
    this.themeMode = ThemeMode.system,
    this.hasSeenOnboarding = false,
    this.notificationsEnabled = true,
    this.notificationHour = 20,
    this.notificationMinute = 0,
  });

  SettingsState copyWith({
    ThemeMode? themeMode,
    bool? hasSeenOnboarding,
    bool? notificationsEnabled,
    int? notificationHour,
    int? notificationMinute,
  }) {
    return SettingsState(
      themeMode: themeMode ?? this.themeMode,
      hasSeenOnboarding: hasSeenOnboarding ?? this.hasSeenOnboarding,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      notificationHour: notificationHour ?? this.notificationHour,
      notificationMinute: notificationMinute ?? this.notificationMinute,
    );
  }

  @override
  List<Object?> get props => [
    themeMode,
    hasSeenOnboarding,
    notificationsEnabled,
    notificationHour,
    notificationMinute,
  ];
}
