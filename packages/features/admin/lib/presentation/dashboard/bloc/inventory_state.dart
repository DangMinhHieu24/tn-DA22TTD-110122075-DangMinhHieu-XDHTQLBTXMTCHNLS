import 'package:equatable/equatable.dart';
import '../../../data/models/inventory_model.dart';

abstract class InventoryState extends Equatable {
  const InventoryState();

  @override
  List<Object?> get props => [];
}

class InventoryInitial extends InventoryState {
  const InventoryInitial();
}

class InventoryLoading extends InventoryState {
  const InventoryLoading();
}

class InventoryLoaded extends InventoryState {
  final List<InventoryModel> allItems;
  final List<InventoryModel> filteredItems;
  final String searchQuery;

  const InventoryLoaded({
    required this.allItems,
    required this.filteredItems,
    this.searchQuery = '',
  });

  int get lowStockCount => allItems.where((e) => e.isBelowThreshold).length;

  InventoryLoaded copyWith({
    List<InventoryModel>? allItems,
    List<InventoryModel>? filteredItems,
    String? searchQuery,
  }) {
    return InventoryLoaded(
      allItems: allItems ?? this.allItems,
      filteredItems: filteredItems ?? this.filteredItems,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }

  @override
  List<Object?> get props => [allItems, filteredItems, searchQuery];
}

class InventorySubmitting extends InventoryState {
  const InventorySubmitting();
}

class InventoryError extends InventoryState {
  final String message;
  const InventoryError(this.message);

  @override
  List<Object?> get props => [message];
}
