import 'package:core/core.dart';
import 'package:dartz/dartz.dart';
import '../entities/customer_vehicle.dart';
import '../repositories/customer_repository.dart';

class GetCustomerVehicles {
  final CustomerRepository repository;

  GetCustomerVehicles(this.repository);

  Future<Either<Failure, List<CustomerVehicle>>> call({String? ownerId}) {
    return repository.getCustomerVehicles(ownerId: ownerId);
  }
}
