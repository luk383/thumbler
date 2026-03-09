/// Single entry point for the entire `core` zone.
///
/// Feature and app code should import this barrel rather than individual
/// sub-barrels, unless a narrower import is intentional (e.g. importing only
/// `core/shared/core_shared.dart` to avoid pulling in DB or network symbols).
///
/// See architecture.md § 3 for barrel usage rules.
library;

export 'network/core_network.dart';
export 'shared/core_shared.dart';
export 'storage/core_storage.dart';
export 'sync/core_sync.dart';

// core/db and core/telemetry are intentionally excluded.
// Import them directly (e.g. core/db/core_db.dart) only in the bootstrap
// layer where the DB engine and telemetry SDK are wired up. This prevents
// DB/telemetry dependencies from leaking into every consumer of core.
