import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:admin/presentation/dashboard/pages/inventory_page.dart';
import 'package:admin/presentation/dashboard/bloc/inventory_bloc.dart';
import 'package:admin/data/datasources/remote/inventory_remote_datasource.dart';
import 'package:admin/data/models/inventory_model.dart';
import 'package:get_it/get_it.dart';

class FakeInventoryDataSource implements InventoryRemoteDataSource {
  final List<InventoryModel> items = [
    const InventoryModel(
      id: '12345678',
      partName: 'Test Part',
      quantity: 10,
      minThreshold: 5,
      unitPrice: 100000,
      sellPrice: 150000,
      warrantyDays: 30,
    ),
  ];

  @override
  Future<List<InventoryModel>> getInventoryItems() async => items;

  @override
  Future<InventoryModel> getInventoryItemById(String id) async =>
      items.firstWhere((item) => item.id == id);

  @override
  Future<InventoryModel> createInventoryItem(Map<String, dynamic> data) async {
    final item = InventoryModel(
      id: 'created',
      partName: data['partName'] as String,
      quantity: data['quantity'] as int,
      minThreshold: data['minThreshold'] as int,
      unitPrice: data['unitPrice'] as double,
      sellPrice: data['sellPrice'] as double,
      warrantyDays: data['warrantyDays'] as int? ?? 0,
    );
    items.add(item);
    return item;
  }

  @override
  Future<InventoryModel> updateInventoryItem(
    String id,
    Map<String, dynamic> data,
  ) async {
    final index = items.indexWhere((item) => item.id == id);
    final current = items[index];
    final updated = current.copyWith(
      partName: data['partName'] as String?,
      quantity: data['quantity'] as int?,
      minThreshold: data['minThreshold'] as int?,
      unitPrice: data['unitPrice'] as double?,
      sellPrice: data['sellPrice'] as double?,
      warrantyDays: data['warrantyDays'] as int?,
    );
    items[index] = updated;
    return updated;
  }

  @override
  Future<InventoryModel> adjustQuantity(String id, int delta) async {
    final index = items.indexWhere((item) => item.id == id);
    final current = items[index];
    final updated = current.copyWith(quantity: current.quantity + delta);
    items[index] = updated;
    return updated;
  }

  @override
  Future<void> deleteInventoryItem(String id) async {
    items.removeWhere((item) => item.id == id);
  }
}

void main() {
  setUp(() async {
    final getIt = GetIt.instance;
    await getIt.reset();
    final ds = FakeInventoryDataSource();
    getIt.registerFactory<InventoryBloc>(() => InventoryBloc(dataSource: ds));
  });

  testWidgets('renders inventory page', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: InventoryPage(),
    ));

    await tester.pumpAndSettle();
    expect(find.byType(InventoryPage), findsOneWidget);
  });
}
