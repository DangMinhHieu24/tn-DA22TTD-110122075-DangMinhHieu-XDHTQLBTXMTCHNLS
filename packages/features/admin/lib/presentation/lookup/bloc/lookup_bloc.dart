import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/entities/lookup_category.dart';
import '../../../domain/repositories/lookup_repository.dart';
import '../../../domain/usecases/search_lookup.dart';
import 'lookup_event.dart';
import 'lookup_state.dart';

class LookupBloc extends Bloc<LookupEvent, LookupState> {
  final LookupRepository repository;
  final SearchLookupUseCase searchUseCase;

  LookupBloc({
    required this.repository,
    required this.searchUseCase,
  }) : super(LookupInitial()) {
    on<LoadLookupCategories>(_onLoadLookupCategories);
    on<PerformLookupSearch>(_onPerformLookupSearch);
  }

  Future<void> _onLoadLookupCategories(
    LoadLookupCategories event,
    Emitter<LookupState> emit,
  ) async {
    emit(LookupCategoriesLoading());
    final result = await repository.getLookupCategories();
    result.fold(
      (failure) => emit(LookupCategoriesError(failure.message)),
      (categories) => emit(LookupCategoriesLoaded(categories)),
    );
  }

  Future<void> _onPerformLookupSearch(
    PerformLookupSearch event,
    Emitter<LookupState> emit,
  ) async {
    // Preserve categories if they are loaded
    List<LookupCategory> currentCategories = [];
    if (state is LookupCategoriesLoaded) {
      currentCategories = (state as LookupCategoriesLoaded).categories;
    } else if (state is LookupSearchLoaded) {
      currentCategories = (state as LookupSearchLoaded).categories;
    }

    emit(LookupSearchLoading(currentCategories));
    
    final result = await searchUseCase(SearchLookupParams(
      categoryId: event.categoryId,
      query: event.query,
    ));

    result.fold(
      (failure) => emit(LookupSearchError(
        categories: currentCategories,
        message: failure.message,
      )),
      (results) => emit(LookupSearchLoaded(
        categories: currentCategories,
        results: results,
        selectedCategoryId: event.categoryId,
      )),
    );
  }
}
