class CertificationCatalog {
  const CertificationCatalog({required this.certifications});

  final List<CertificationTrack> certifications;

  factory CertificationCatalog.fromJson(Map<String, dynamic> json) {
    final certifications =
        (json['certifications'] as List<dynamic>? ?? const [])
            .whereType<Map>()
            .map(
              (entry) =>
                  CertificationTrack.fromJson(entry.cast<String, dynamic>()),
            )
            .toList(growable: false);
    return CertificationCatalog(certifications: certifications);
  }
}

class CertificationTrack {
  const CertificationTrack({
    required this.id,
    required this.provider,
    required this.title,
    required this.shortTitle,
    required this.examCode,
    required this.order,
    this.description,
    this.domains = const [],
    this.deckIds = const [],
    this.tags = const [],
  });

  final String id;
  final String provider;
  final String title;
  final String shortTitle;
  final String examCode;
  final int order;
  final String? description;
  final List<CertificationDomain> domains;
  final List<String> deckIds;
  final List<String> tags;

  factory CertificationTrack.fromJson(Map<String, dynamic> json) {
    return CertificationTrack(
      id: json['id'] as String,
      provider: json['provider'] as String,
      title: json['title'] as String,
      shortTitle: json['shortTitle'] as String? ?? json['title'] as String,
      examCode: json['examCode'] as String,
      order: (json['order'] as num?)?.toInt() ?? 0,
      description: json['description'] as String?,
      domains: (json['domains'] as List<dynamic>? ?? const [])
          .whereType<Map>()
          .map(
            (entry) =>
                CertificationDomain.fromJson(entry.cast<String, dynamic>()),
          )
          .toList(growable: false),
      deckIds: (json['deckIds'] as List<dynamic>? ?? const [])
          .whereType<String>()
          .toList(growable: false),
      tags: (json['tags'] as List<dynamic>? ?? const [])
          .whereType<String>()
          .toList(growable: false),
    );
  }
}

class CertificationDomain {
  const CertificationDomain({
    required this.id,
    required this.title,
    required this.order,
    this.description,
  });

  final String id;
  final String title;
  final int order;
  final String? description;

  factory CertificationDomain.fromJson(Map<String, dynamic> json) {
    return CertificationDomain(
      id: json['id'] as String,
      title: json['title'] as String,
      order: (json['order'] as num?)?.toInt() ?? 0,
      description: json['description'] as String?,
    );
  }
}
