import 'package:wolf_lab/app/bootstrap/app_config.dart';
import 'package:wolf_lab/app/bootstrap/dependency_container.dart';
import 'package:wolf_lab/core/db/app_database.dart';
import 'package:wolf_lab/features/food/data/datasources/food_local_datasource.dart';
import 'package:wolf_lab/features/food/data/repositories_impl/food_repository_impl.dart';
import 'package:wolf_lab/features/food/domain/repositories/food_repository.dart';
import 'package:wolf_lab/features/fuel/data/datasources/fuel_local_datasource.dart';
import 'package:wolf_lab/features/fuel/data/repositories_impl/fuel_repository_impl.dart';
import 'package:wolf_lab/features/fuel/domain/repositories/fuel_repository.dart';
import 'package:wolf_lab/features/nutrition/data/datasources/nutrition_local_datasource.dart';
import 'package:wolf_lab/features/nutrition/data/repositories_impl/nutrition_repository_impl.dart';
import 'package:wolf_lab/features/nutrition/domain/repositories/nutrition_repository.dart';
import 'package:wolf_lab/features/reports/data/datasources/reports_local_datasource.dart';
import 'package:wolf_lab/features/reports/data/repositories_impl/reports_repository_impl.dart';
import 'package:wolf_lab/features/reports/domain/repositories/reports_repository.dart';
import 'package:wolf_lab/features/settings/data/datasources/settings_local_datasource.dart';
import 'package:wolf_lab/features/settings/data/repositories_impl/settings_repository_impl.dart';
import 'package:wolf_lab/features/settings/domain/repositories/settings_repository.dart';
import 'package:wolf_lab/features/strava/data/datasources/strava_local_datasource.dart';
import 'package:wolf_lab/features/strava/data/repositories_impl/strava_repository_impl.dart';
import 'package:wolf_lab/features/strava/domain/repositories/strava_repository.dart';
import 'package:wolf_lab/features/supplements/data/datasources/supplements_local_datasource.dart';
import 'package:wolf_lab/features/supplements/data/repositories_impl/supplements_repository_impl.dart';
import 'package:wolf_lab/features/supplements/domain/repositories/supplements_repository.dart';
import 'package:wolf_lab/features/training/data/datasources/training_local_datasource.dart';
import 'package:wolf_lab/features/training/data/repositories_impl/training_repository_impl.dart';
import 'package:wolf_lab/features/training/domain/repositories/training_repository.dart';
import 'package:wolf_lab/features/trips/data/datasources/trips_local_datasource.dart';
import 'package:wolf_lab/features/trips/data/repositories_impl/routes_repository_impl.dart';
import 'package:wolf_lab/features/trips/data/repositories_impl/trips_repository_impl.dart';
import 'package:wolf_lab/features/trips/domain/repositories/routes_repository.dart';
import 'package:wolf_lab/features/trips/domain/repositories/trips_repository.dart';

/// Initialises all application-level singletons before the widget tree runs.
///
/// Call this from [main] — before [runApp] — so that every dependency is
/// available the moment the first widget is built.
Future<void> appBootstrap(AppConfig config) async {
  final container = DependencyContainer.instance;

  final db = AppDatabase();
  container.register<AppDatabase>(db);

  final foodDs = FoodLocalDataSource(db);
  container.register<FoodRepository>(FoodRepositoryImpl(foodDs));

  final trainingDs = TrainingLocalDataSource(db);
  final fuelDs = FuelLocalDataSource(db);
  final nutritionDs = NutritionLocalDataSource(db);
  final supplementsDs = SupplementsLocalDataSource(db);
  final tripsDs = TripsLocalDataSource(db);
  final stravaDs = StravaLocalDataSource(db);
  final settingsDs = SettingsLocalDataSource(db);
  final reportsDs = ReportsLocalDataSource(db);

  container.register<TrainingRepository>(TrainingRepositoryImpl(trainingDs));
  container.register<FuelRepository>(FuelRepositoryImpl(fuelDs));
  container.register<NutritionRepository>(NutritionRepositoryImpl(nutritionDs));
  container.register<SupplementsRepository>(
    SupplementsRepositoryImpl(supplementsDs),
  );
  container.register<TripsRepository>(TripsRepositoryImpl(tripsDs));
  container.register<RoutesRepository>(RoutesRepositoryImpl(tripsDs));
  container.register<StravaRepository>(StravaRepositoryImpl(stravaDs));
  container.register<SettingsRepository>(SettingsRepositoryImpl(settingsDs));
  container.register<ReportsRepository>(ReportsRepositoryImpl(reportsDs));
}
