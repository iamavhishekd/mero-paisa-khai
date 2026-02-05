part of 'settings_bloc.dart';

class SettingsState extends Equatable {
  final ThemeMode themeMode;
  final bool hasSeenOnboarding;

  const SettingsState({
    this.themeMode = ThemeMode.system,
    this.hasSeenOnboarding = false,
  });

  SettingsState copyWith({
    ThemeMode? themeMode,
    bool? hasSeenOnboarding,
  }) {
    return SettingsState(
      themeMode: themeMode ?? this.themeMode,
      hasSeenOnboarding: hasSeenOnboarding ?? this.hasSeenOnboarding,
    );
  }

  @override
  List<Object?> get props => [themeMode, hasSeenOnboarding];
}
