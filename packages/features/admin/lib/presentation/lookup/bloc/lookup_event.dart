import 'package:equatable/equatable.dart';

abstract class LookupEvent extends Equatable {
  const LookupEvent();

  @override
  List<Object?> get props => [];
}

class LoadLookupCategories extends LookupEvent {}

class PerformLookupSearch extends LookupEvent {
  final String categoryId;
  final String? query;

  const PerformLookupSearch({
    required this.categoryId,
    this.query,
  });

  @override
  List<Object?> get props => [categoryId, query];
}
