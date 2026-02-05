import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:paisa_khai/hive/hive_service.dart';

part 'settings_event.dart';
part 'settings_state.dart';

class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {
  SettingsBloc() : super(const SettingsState()) {
    on<LoadSettings>(_onLoadSettings);
    on<UpdateThemeMode>(_onUpdateThemeMode);
    on<ClearAllAppData>(_onClearAllAppData);

    add(LoadSettings());
  }

  void _onLoadSettings(LoadSettings event, Emitter<SettingsState> emit) {
    final box = HiveService.settingsBoxInstance;
    final savedIndex = box.get('theme_mode_index', defaultValue: 0) as int;
    emit(state.copyWith(themeMode: ThemeMode.values[savedIndex]));
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

  Future<void> _onClearAllAppData(
    ClearAllAppData event,
    Emitter<SettingsState> emit,
  ) async {
    await HiveService.clearAndReset();
    // After clearing, we might want to tell other blocs to reload.
    // Usually, this is handled by Hive listeners in other blocs.
  }
}
