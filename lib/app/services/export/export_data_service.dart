import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:wolf_lab/core/db/app_database.dart';

class ExportDataService {
  ExportDataService(this._db);

  final AppDatabase _db;

  // All 32 tables — datetime columns are stored as epoch-ms integers.
  // Note: external_accounts contains OAuth tokens.
  static const _tables = [
    'athlete_profiles',
    'workout_templates',
    'planned_sessions',
    'completed_sessions',
    'training_metrics',
    'training_day_summaries',
    'training_week_summaries',
    'session_stream_points',
    'fueling_strategies',
    'fuel_products',
    'fuel_inventory_items',
    'fuel_product_usages',
    'session_fuel_plans',
    'fuel_session_summaries',
    'meal_templates',
    'meal_entries',
    'day_nutrition_targets',
    'day_nutrition_summaries',
    'supplements',
    'supplement_schedules',
    'supplement_intakes',
    'trips',
    'trip_locations',
    'trip_days',
    'route_refs',
    'ride_protocols',
    'trip_supply_plans',
    'trip_session_links',
    'external_accounts',
    'external_activities',
    'app_settings',
    'report_configs',
  ];

  /// Exports all local data to a JSON file in the app documents directory.
  /// Returns the absolute path of the written file.
  Future<String> export() async {
    final tableData = <String, dynamic>{};
    for (final table in _tables) {
      final rows = await _db.customSelect('SELECT * FROM "$table"').get();
      tableData[table] = rows.map((r) => r.data).toList();
    }

    final payload = <String, dynamic>{
      'exportedAt': DateTime.now().toUtc().toIso8601String(),
      'app': 'WAJE',
      'version': '0.1.0+1',
      'data': tableData,
    };

    final dir = await getApplicationDocumentsDirectory();
    final stamp = DateTime.now()
        .toUtc()
        .toIso8601String()
        .replaceAll(':', '-')
        .replaceAll('.', '-');
    final file = File('${dir.path}/waje_export_$stamp.json');
    await file.writeAsString(jsonEncode(payload));
    return file.path;
  }
}
