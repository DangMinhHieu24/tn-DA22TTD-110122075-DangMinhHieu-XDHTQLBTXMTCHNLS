import 'package:core/core.dart';
import 'package:dartz/dartz.dart';
import '../entities/customer_vehicle.dart';
import '../entities/customer_work_order.dart';

abstract class CustomerRepository {
  Future<Either<Failure, List<CustomerVehicle>>> getCustomerVehicles({String? ownerId});
  Future<Either<Failure, List<CustomerWorkOrder>>> getWorkOrdersByVehicle(String vehicleId);
}
