import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:admin/presentation/dashboard/widgets/inventory_form_sheet.dart';
import 'package:admin/data/models/inventory_model.dart';

void main() {
  testWidgets('renders inventory form sheet for edit', (tester) async {
    const item = InventoryModel(
      id: '123',
      partName: 'Test Part',
      quantity: 10,
      minThreshold: 5,
      unitPrice: 100000,
      sellPrice: 150000,
      warrantyDays: 30,
    );
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) {
            return ElevatedButton(
              onPressed: () {
                InventoryFormSheet.showEdit(context, item, (data) {});
              },
              child: const Text('Show'),
            );
          },
        ),
      ),
    ));

    await tester.tap(find.text('Show'));
    await tester.pumpAndSettle();

    expect(find.byType(InventoryFormSheet), findsOneWidget);
  });
}
