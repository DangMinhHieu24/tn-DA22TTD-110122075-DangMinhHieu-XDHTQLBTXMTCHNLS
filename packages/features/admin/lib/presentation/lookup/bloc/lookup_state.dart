import 'package:equatable/equatable.dart';
import '../../../domain/entities/lookup_category.dart';
import '../../../domain/entities/lookup_result.dart';

abstract class LookupState extends Equatable {
  const LookupState();

  @override
  List<Object?> get props => [];
}

class LookupInitial extends LookupState {}

class LookupCategoriesLoading extends LookupState {}

class LookupCategoriesLoaded extends LookupState {
  final List<LookupCategory> categories;

  const LookupCategoriesLoaded(this.categories);

  @override
  List<Object?> get props => [categories];
}

class LookupCategoriesError extends LookupState {
  final String message;

  const LookupCategoriesError(this.message);

  @override
  List<Object?> get props => [message];
}

class LookupSearchLoading extends LookupState {
  final List<LookupCategory> categories;

  const LookupSearchLoading(this.categories);

  @override
  List<Object?> get props => [categories];
}

class LookupSearchLoaded extends LookupState {
  final List<LookupCategory> categories;
  final List<LookupResult> results;
  final String selectedCategoryId;

  const LookupSearchLoaded({
    required this.categories,
    required this.results,
    required this.selectedCategoryId,
  });

  @override
  List<Object?> get props => [categories, results, selectedCategoryId];
}

class LookupSearchError extends LookupState {
  final List<LookupCategory> categories;
  final String message;

  const LookupSearchError({
    required this.categories,
    required this.message,
  });

  @override
  List<Object?> get props => [categories, message];
}
