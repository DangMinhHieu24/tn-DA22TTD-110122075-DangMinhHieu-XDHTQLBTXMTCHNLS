import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class WorkOrderRealtimeService {
  final SupabaseClient _supabase = Supabase.instance.client;
  RealtimeChannel? _channel;

  PostgresChangeFilter _eqFilter(String column, String value) {
    return PostgresChangeFilter(
      type: PostgresChangeFilterType.eq,
      column: column,
      value: value,
    );
  }

  void subscribeToWorkOrder({
    required String workOrderId,
    required VoidCallback onChanged,
  }) {
    unsubscribe();

    _channel = _supabase.channel('work-order-$workOrderId')
      ..onPostgresChanges(
        event: PostgresChangeEvent.insert,
        schema: 'public',
        table: 'work_orders',
        filter: _eqFilter('id', workOrderId),
        callback: (_) => onChanged(),
      )
      ..onPostgresChanges(
        event: PostgresChangeEvent.update,
        schema: 'public',
        table: 'work_orders',
        filter: _eqFilter('id', workOrderId),
        callback: (_) => onChanged(),
      )
      ..onPostgresChanges(
        event: PostgresChangeEvent.insert,
        schema: 'public',
        table: 'repair_items',
        filter: _eqFilter('order_id', workOrderId),
        callback: (_) => onChanged(),
      )
      ..onPostgresChanges(
        event: PostgresChangeEvent.update,
        schema: 'public',
        table: 'repair_items',
        filter: _eqFilter('order_id', workOrderId),
        callback: (_) => onChanged(),
      )
      ..onPostgresChanges(
        event: PostgresChangeEvent.delete,
        schema: 'public',
        table: 'repair_items',
        filter: _eqFilter('order_id', workOrderId),
        callback: (_) => onChanged(),
      )
      ..onPostgresChanges(
        event: PostgresChangeEvent.insert,
        schema: 'public',
        table: 'work_order_photos',
        filter: _eqFilter('workOrderId', workOrderId),
        callback: (_) => onChanged(),
      )
      ..onPostgresChanges(
        event: PostgresChangeEvent.update,
        schema: 'public',
        table: 'work_order_photos',
        filter: _eqFilter('workOrderId', workOrderId),
        callback: (_) => onChanged(),
      )
      ..onPostgresChanges(
        event: PostgresChangeEvent.insert,
        schema: 'public',
        table: 'parts_used',
        filter: _eqFilter('order_id', workOrderId),
        callback: (_) => onChanged(),
      )
      ..onPostgresChanges(
        event: PostgresChangeEvent.update,
        schema: 'public',
        table: 'parts_used',
        filter: _eqFilter('order_id', workOrderId),
        callback: (_) => onChanged(),
      )
      ..onPostgresChanges(
        event: PostgresChangeEvent.delete,
        schema: 'public',
        table: 'parts_used',
        filter: _eqFilter('order_id', workOrderId),
        callback: (_) => onChanged(),
      );

    _channel!.subscribe();
  }

  void unsubscribe() {
    final channel = _channel;
    if (channel == null) return;

    _supabase.removeChannel(channel);
    _channel = null;
  }
}