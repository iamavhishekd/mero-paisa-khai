import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:paisa_khai/hive/hive_service.dart';
import 'package:paisa_khai/models/source.dart';

part 'source_event.dart';
part 'source_state.dart';

class SourceBloc extends Bloc<SourceEvent, SourceState> {
  StreamSubscription<BoxEvent>? _sourcesSubscription;

  SourceBloc() : super(const SourceState()) {
    on<LoadSources>(_onLoadSources);
    on<AddSource>(_onAddSource);
    on<UpdateSource>(_onUpdateSource);
    on<DeleteSource>(_onDeleteSource);

    _sourcesSubscription = HiveService.sourcesBoxInstance.watch().listen((_) {
      add(LoadSources());
    });

    add(LoadSources());
  }

  Future<void> _onLoadSources(
    LoadSources event,
    Emitter<SourceState> emit,
  ) async {
    emit(state.copyWith(status: SourceStatus.loading));
    try {
      final sources = HiveService.sourcesBoxInstance.values.toList();
      emit(
        state.copyWith(
          sources: sources,
          status: SourceStatus.success,
        ),
      );
    } catch (e) {
      emit(state.copyWith(status: SourceStatus.failure));
    }
  }

  Future<void> _onAddSource(
    AddSource event,
    Emitter<SourceState> emit,
  ) async {
    await HiveService.sourcesBoxInstance.put(
      event.source.id,
      event.source,
    );
  }

  Future<void> _onUpdateSource(
    UpdateSource event,
    Emitter<SourceState> emit,
  ) async {
    await HiveService.sourcesBoxInstance.put(
      event.source.id,
      event.source,
    );
  }

  Future<void> _onDeleteSource(
    DeleteSource event,
    Emitter<SourceState> emit,
  ) async {
    await HiveService.sourcesBoxInstance.delete(event.sourceId);
  }

  @override
  Future<void> close() async {
    await _sourcesSubscription?.cancel();
    return super.close();
  }
}
