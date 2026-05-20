part of 'customer_work_order_bloc.dart';

abstract class CustomerWorkOrderState extends Equatable {
  const CustomerWorkOrderState();

  @override
  List<Object?> get props => [];
}

class CustomerWorkOrderInitial extends CustomerWorkOrderState {}

class CustomerWorkOrderLoading extends CustomerWorkOrderState {}

class CustomerWorkOrderLoaded extends CustomerWorkOrderState {
  final List<CustomerWorkOrder> workOrders;

  const CustomerWorkOrderLoaded(this.workOrders);

  @override
  List<Object?> get props => [workOrders];
}

class CustomerWorkOrderError extends CustomerWorkOrderState {
  final String message;

  const CustomerWorkOrderError(this.message);

  @override
  List<Object?> get props => [message];
}
