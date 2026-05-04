import '../../models/work_item_model.dart';

abstract class WorkLocalDataSource {
  Future<List<WorkItemModel>> getCachedWorkItems();
  Future<void> cacheWorkItems(List<WorkItemModel> items);
  Future<WorkItemModel?> getCachedWorkItemById(String id);
  Future<void> clearCache();
}

class WorkLocalDataSourceImpl implements WorkLocalDataSource {
  // TODO: Inject Hive box or SharedPreferences
  
  // In-memory cache for now
  List<WorkItemModel>? _cachedItems;

  @override
  Future<List<WorkItemModel>> getCachedWorkItems() async {
    if (_cachedItems == null) {
      throw Exception('No cached data available');
    }
    return _cachedItems!;
  }

  @override
  Future<void> cacheWorkItems(List<WorkItemModel> items) async {
    // TODO: Save to Hive
    _cachedItems = items;
  }

  @override
  Future<WorkItemModel?> getCachedWorkItemById(String id) async {
    if (_cachedItems == null) return null;
    
    try {
      return _cachedItems!.firstWhere((item) => item.id == id);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> clearCache() async {
    // TODO: Clear Hive box
    _cachedItems = null;
  }
}
