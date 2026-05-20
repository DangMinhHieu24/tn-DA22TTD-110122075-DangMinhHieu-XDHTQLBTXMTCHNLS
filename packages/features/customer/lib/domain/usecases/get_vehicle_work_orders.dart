import 'package:core/core.dart';
import 'package:dartz/dartz.dart';
import '../entities/customer_work_order.dart';
import '../repositories/customer_repository.dart';

class GetVehicleWorkOrders {
  final CustomerRepository repository;

  GetVehicleWorkOrders(this.repository);

  Future<Either<Failure, List<CustomerWorkOrder>>> call(String vehicleId) {
    return repository.getWorkOrdersByVehicle(vehicleId);
  }
}
