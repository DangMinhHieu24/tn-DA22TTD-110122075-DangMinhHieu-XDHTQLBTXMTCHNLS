import 'package:equatable/equatable.dart';
import '../../../domain/entities/inventory_part.dart';

abstract class PartsLookupState extends Equatable {
  const PartsLookupState();

  @override
  List<Object?> get props => [];
}

class PartsLookupInitial extends PartsLookupState {
  const PartsLookupInitial();
}

class PartsLookupLoading extends PartsLookupState {
  const PartsLookupLoading();
}

class PartsLookupLoaded extends PartsLookupState {
  final List<InventoryPart> parts;
  final String? query;

  const PartsLookupLoaded({required this.parts, this.query});

  @override
  List<Object?> get props => [parts, query];
}

class PartsLookupError extends PartsLookupState {
  final String message;

  const PartsLookupError({required this.message});

  @override
  List<Object?> get props => [message];
}
