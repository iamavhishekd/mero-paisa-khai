part of 'source_bloc.dart';

enum SourceStatus { initial, loading, success, failure }

class SourceState extends Equatable {
  final List<Source> sources;
  final SourceStatus status;

  const SourceState({
    this.sources = const [],
    this.status = SourceStatus.initial,
  });

  SourceState copyWith({
    List<Source>? sources,
    SourceStatus? status,
  }) {
    return SourceState(
      sources: sources ?? this.sources,
      status: status ?? this.status,
    );
  }

  @override
  List<Object?> get props => [sources, status];
}
