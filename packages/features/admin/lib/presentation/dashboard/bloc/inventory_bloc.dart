import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/repositories/inventory_repository.dart';
import '../../../data/models/inventory_model.dart';
import 'inventory_event.dart';
import 'inventory_state.dart';

class InventoryBloc extends Bloc<InventoryEvent, InventoryState> {
  final InventoryRepository _repository;

  InventoryBloc({required InventoryRepository repository})
      : _repository = repository,
        super(const InventoryInitial()) {
    on<LoadInventory>(_onLoad);
    on<SearchInventory>(_onSearch);
    on<CreateInventoryItem>(_onCreate);
    on<UpdateInventoryItem>(_onUpdate);
    on<AdjustInventoryQuantity>(_onAdjust);
    on<DeleteInventoryItem>(_onDelete);
  }

  Future<void> _onLoad(
      LoadInventory event, Emitter<InventoryState> emit) async {
    final prev = _loadedStateOrNull(state);
    emit(const InventoryLoading());
    final result = await _repository.getInventoryItems();
    result.fold(
      (failure) => emit(InventoryError(failure.message, previous: prev)),
      (items) {
        final sorted = _sortByPriority(items);
        emit(InventoryLoaded(allItems: sorted, filteredItems: sorted));
      },
    );
  }

  void _onSearch(SearchInventory event, Emitter<InventoryState> emit) {
    final current = _loadedStateOrNull(state);
    if (current == null) return;

    final q = event.query.toLowerCase().trim();
    final filtered = q.isEmpty
        ? current.allItems
        : current.allItems
            .where((e) => e.partName.toLowerCase().contains(q))
            .toList();
    final sorted = _sortByPriority(filtered);

    emit(current.copyWith(filteredItems: sorted, searchQuery: event.query));
  }

  Future<void> _onCreate(
      CreateInventoryItem event, Emitter<InventoryState> emit) async {
    final prev = _loadedStateOrNull(state);
    emit(InventorySubmitting(previous: prev));
    final result = await _repository.createInventoryItem(event.data);
    result.fold(
      (failure) => emit(InventoryError(failure.message, previous: prev)),
      (newItem) {
        if (prev != null) {
          final updated = _sortByPriority([newItem, ...prev.allItems]);
          emit(_applySearch(prev, updated));
        } else {
          add(const LoadInventory());
        }
      },
    );
  }

  Future<void> _onUpdate(
      UpdateInventoryItem event, Emitter<InventoryState> emit) async {
    final prev = _loadedStateOrNull(state);
    emit(InventorySubmitting(previous: prev));
    final result = await _repository.updateInventoryItem(event.id, event.data);
    result.fold(
      (failure) => emit(InventoryError(failure.message, previous: prev)),
      (updatedItem) {
        if (prev != null) {
          final updated = prev.allItems
              .map((e) => e.id == event.id ? updatedItem : e)
              .toList();
          final sorted = _sortByPriority(updated);
          emit(_applySearch(prev, sorted));
        } else {
          add(const LoadInventory());
        }
      },
    );
  }

  Future<void> _onAdjust(
      AdjustInventoryQuantity event, Emitter<InventoryState> emit) async {
    final prev = _loadedStateOrNull(state);
    if (prev == null) return;
    final result = await _repository.adjustQuantity(event.id, event.delta);
    result.fold(
      (failure) => emit(InventoryError(failure.message, previous: prev)),
      (adjustedItem) {
        final updated = prev.allItems
            .map((e) => e.id == event.id ? adjustedItem : e)
            .toList();
        final sortedAll = _sortByPriority(updated);
        emit(_applySearch(prev, sortedAll));
      },
    );
  }

  Future<void> _onDelete(
      DeleteInventoryItem event, Emitter<InventoryState> emit) async {
    final prev = _loadedStateOrNull(state);
    emit(InventorySubmitting(previous: prev));
    final result = await _repository.deleteInventoryItem(event.id);
    result.fold(
      (failure) => emit(InventoryError(failure.message, previous: prev)),
      (_) {
        if (prev != null) {
          final updated = prev.allItems.where((e) => e.id != event.id).toList();
          final sorted = _sortByPriority(updated);
          emit(_applySearch(prev, sorted));
        } else {
          add(const LoadInventory());
        }
      },
    );
  }

  InventoryLoaded? _loadedStateOrNull(InventoryState state) {
    if (state is InventoryLoaded) return state;
    if (state is InventorySubmitting) return state.previous;
    if (state is InventoryError) return state.previous;
    return null;
  }

  InventoryLoaded _applySearch(
      InventoryLoaded previous, List<InventoryModel> allItems) {
    final sortedAll = _sortByPriority(allItems);
    final q = previous.searchQuery.toLowerCase().trim();
    final filtered = q.isEmpty
        ? sortedAll
        : sortedAll.where((e) => e.partName.toLowerCase().contains(q)).toList();

    return previous.copyWith(
      allItems: sortedAll,
      filteredItems: _sortByPriority(filtered),
    );
  }

  List<InventoryModel> _sortByPriority(List<InventoryModel> items) {
    final sorted = List<InventoryModel>.from(items);
    sorted.sort((a, b) {
      final pa = _priorityOf(a);
      final pb = _priorityOf(b);
      if (pa != pb) return pa.compareTo(pb);
      if (a.quantity != b.quantity) return a.quantity.compareTo(b.quantity);
      return a.partName.compareTo(b.partName);
    });
    return sorted;
  }

  int _priorityOf(InventoryModel item) {
    if (item.quantity == 0) return 0; // Het hang
    if (item.isBelowThreshold) return 1; // Sap het
    return 2; // Con hang
  }
}
