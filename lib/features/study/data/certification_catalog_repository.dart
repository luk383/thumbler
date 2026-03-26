import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/certification_catalog.dart';

class CertificationCatalogRepository {
  const CertificationCatalogRepository();

  static const _assetPath = 'assets/content/certifications_catalog.json';

  Future<CertificationCatalog> load() async {
    final raw = await rootBundle.loadString(_assetPath);
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    return CertificationCatalog.fromJson(decoded);
  }
}

final certificationCatalogRepositoryProvider =
    Provider<CertificationCatalogRepository>(
      (_) => const CertificationCatalogRepository(),
    );

final certificationCatalogProvider = FutureProvider<CertificationCatalog>((
  ref,
) async {
  return ref.read(certificationCatalogRepositoryProvider).load();
});
