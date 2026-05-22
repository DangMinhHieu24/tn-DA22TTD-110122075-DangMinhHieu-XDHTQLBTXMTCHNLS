import 'package:equatable/equatable.dart';

abstract class InventoryEvent extends Equatable {
  const InventoryEvent();

  @override
  List<Object?> get props => [];
}

class LoadInventory extends InventoryEvent {
  const LoadInventory();
}

class SearchInventory extends InventoryEvent {
  final String query;
  const SearchInventory(this.query);

  @override
  List<Object?> get props => [query];
}

class CreateInventoryItem extends InventoryEvent {
  final Map<String, dynamic> data;
  const CreateInventoryItem(this.data);

  @override
  List<Object?> get props => [data];
}

class UpdateInventoryItem extends InventoryEvent {
  final String id;
  final Map<String, dynamic> data;
  const UpdateInventoryItem(this.id, this.data);

  @override
  List<Object?> get props => [id, data];
}

class AdjustInventoryQuantity extends InventoryEvent {
  final String id;
  final int delta;
  const AdjustInventoryQuantity(this.id, this.delta);

  @override
  List<Object?> get props => [id, delta];
}

class DeleteInventoryItem extends InventoryEvent {
  final String id;
  const DeleteInventoryItem(this.id);

  @override
  List<Object?> get props => [id];
}
