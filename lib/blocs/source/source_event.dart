part of 'source_bloc.dart';

abstract class SourceEvent extends Equatable {
  const SourceEvent();

  @override
  List<Object?> get props => [];
}

class LoadSources extends SourceEvent {}

class AddSource extends SourceEvent {
  final Source source;
  const AddSource(this.source);

  @override
  List<Object?> get props => [source];
}

class UpdateSource extends SourceEvent {
  final Source source;
  const UpdateSource(this.source);

  @override
  List<Object?> get props => [source];
}

class DeleteSource extends SourceEvent {
  final String sourceId;
  const DeleteSource(this.sourceId);

  @override
  List<Object?> get props => [sourceId];
}
