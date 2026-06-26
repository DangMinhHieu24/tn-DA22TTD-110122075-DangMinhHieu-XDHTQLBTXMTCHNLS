import 'package:core/core.dart';
import 'package:dartz/dartz.dart';
import '../../domain/entities/work_item.dart';
import '../../domain/entities/work_item_service.dart';
import '../../domain/repositories/work_repository.dart';
import '../datasources/remote/work_remote_datasource.dart';
import '../datasources/local/work_local_datasource.dart';

class WorkRepositoryImpl implements WorkRepository {
  final WorkRemoteDataSource remoteDataSource;
  final WorkLocalDataSource localDataSource;

  const WorkRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
  });

  @override
  Future<Either<Failure, List<WorkItem>>> getWorkItems({
    String? technicianId,
  }) async {
    try {
      // Try to get from remote
      final remoteItems = await remoteDataSource.getWorkItems(
        technicianId: technicianId,
      );
      
      // Cache the items
      await localDataSource.cacheWorkItems(remoteItems);
      
      // Convert to entities
      final entities = remoteItems.map((model) => model.toEntity()).toList();
      
      return Right(entities);
    } catch (e) {
      // If remote fails, try to get from cache
      try {
        final cachedItems = await localDataSource.getCachedWorkItems();
        final entities = cachedItems.map((model) => model.toEntity()).toList();
        return Right(entities);
      } catch (cacheError) {
        return Left(ServerFailure(e.toString()));
      }
    }
  }

  @override
  Future<Either<Failure, WorkItem>> getWorkItemById(String id) async {
    try {
      final remoteItem = await remoteDataSource.getWorkItemById(id);
      return Right(remoteItem.toEntity());
    } catch (e) {
      // Try cache
      try {
        final cachedItem = await localDataSource.getCachedWorkItemById(id);
        if (cachedItem != null) {
          return Right(cachedItem.toEntity());
        }
        return Left(CacheFailure('Work item not found in cache'));
      } catch (cacheError) {
        return Left(ServerFailure(e.toString()));
      }
    }
  }

  @override
  Future<Either<Failure, WorkItem>> updateWorkStatus(
    String id,
    WorkStatus newStatus,
  ) async {
    try {
      final statusString = _statusToString(newStatus);
      final updatedItem = await remoteDataSource.updateWorkStatus(id, statusString);
      
      // Update cache
      final cachedItems = await localDataSource.getCachedWorkItems();
      final updatedCache = cachedItems.map((item) {
        if (item.id == id) {
          return updatedItem;
        }
        return item;
      }).toList();
      await localDataSource.cacheWorkItems(updatedCache);
      
      return Right(updatedItem.toEntity());
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<WorkItem>>> searchWorkItems(
    String query, {
    String? technicianId,
  }) async {
    try {
      final items = await remoteDataSource.searchWorkItems(
        query,
        technicianId: technicianId,
      );
      final entities = items.map((model) => model.toEntity()).toList();
      return Right(entities);
    } catch (e) {
      // Try to search in cache
      try {
        final cachedItems = await localDataSource.getCachedWorkItems();
        final filtered = cachedItems.where((item) {
          final q = query.toLowerCase();
          return item.licensePlate.toLowerCase().contains(q) ||
              item.customerName.toLowerCase().contains(q) ||
              item.vehicleModel.toLowerCase().contains(q);
        }).toList();
        final entities = filtered.map((model) => model.toEntity()).toList();
        return Right(entities);
      } catch (cacheError) {
        return Left(ServerFailure(e.toString()));
      }
    }
  }

  @override
  Future<Either<Failure, WorkItemService>> updateWorkServiceStatus(
    String workOrderId,
    String serviceId,
    bool isDone,
  ) async {
    try {
      final updatedService = await remoteDataSource.updateWorkServiceStatus(
        workOrderId,
        serviceId,
        isDone,
      );

      // Note: local cache update for service item is omitted (cache model doesn't store services yet)
      return Right(updatedService.toEntity());
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, WorkItemService>> addService(
    String workOrderId,
    String serviceType,
    String description, {
    String? serviceName,
    double? price,
  }) async {
    try {
      final service = await remoteDataSource.addService(
        workOrderId,
        serviceType,
        description,
        serviceName: serviceName,
        price: price,
      );
      return Right(service.toEntity());
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> addParts(
    String workOrderId,
    List<Map<String, dynamic>> parts,
  ) async {
    try {
      await remoteDataSource.addParts(workOrderId, parts);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> addPhoto(
    String workOrderId,
    String photoUrl, {
    String? photoType,
    String? description,
  }) async {
    try {
      await remoteDataSource.addPhoto(workOrderId, photoUrl,
          photoType: photoType, description: description);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateNotes(
    String workOrderId,
    String notes,
  ) async {
    try {
      await remoteDataSource.updateNotes(workOrderId, notes);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  String _statusToString(WorkStatus status) {
    switch (status) {
      case WorkStatus.pending:
        return 'pending';
      case WorkStatus.inProgress:
        return 'in_progress';
      case WorkStatus.inspection:
        return 'inspection';
      case WorkStatus.completed:
        return 'completed';
      case WorkStatus.cancelled:
        return 'cancelled';
    }
  }
}
