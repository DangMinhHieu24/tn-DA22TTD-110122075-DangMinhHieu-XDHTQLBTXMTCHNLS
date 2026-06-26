import 'package:equatable/equatable.dart';

abstract class PartsLookupEvent extends Equatable {
  const PartsLookupEvent();

  @override
  List<Object?> get props => [];
}

class LoadParts extends PartsLookupEvent {
  final String? query;

  const LoadParts({this.query});

  @override
  List<Object?> get props => [query];
}

class SearchParts extends PartsLookupEvent {
  final String query;

  const SearchParts({required this.query});

  @override
  List<Object?> get props => [query];
}
