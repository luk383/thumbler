enum ReadingType { book, course, article, podcast }

enum ReadingStatus { wishlist, reading, completed }

extension ReadingTypeExt on ReadingType {
  String get emoji => switch (this) {
        ReadingType.book => '📚',
        ReadingType.course => '🎓',
        ReadingType.article => '📄',
        ReadingType.podcast => '🎙️',
      };
  String get label => switch (this) {
        ReadingType.book => 'Libro',
        ReadingType.course => 'Corso',
        ReadingType.article => 'Articolo',
        ReadingType.podcast => 'Podcast',
      };
}

extension ReadingStatusExt on ReadingStatus {
  String get label => switch (this) {
        ReadingStatus.wishlist => 'Lista desideri',
        ReadingStatus.reading => 'In corso',
        ReadingStatus.completed => 'Completato',
      };
  String get emoji => switch (this) {
        ReadingStatus.wishlist => '⭐',
        ReadingStatus.reading => '🔖',
        ReadingStatus.completed => '✅',
      };
}

class ReadingItem {
  const ReadingItem({
    required this.id,
    required this.title,
    this.author,
    this.type = ReadingType.book,
    this.status = ReadingStatus.wishlist,
    this.totalPages,
    this.currentPage,
    this.notes,
    this.thumbnailUrl,
    this.sourceUrl,
    this.startedAt,
    this.completedAt,
    required this.createdAt,
  });

  final String id;
  final String title;
  final String? author;
  final ReadingType type;
  final ReadingStatus status;
  final int? totalPages;
  final int? currentPage;
  final String? notes;
  final String? thumbnailUrl; // book cover or video thumbnail
  final String? sourceUrl;   // original URL (YouTube, Spotify, etc.)
  final DateTime? startedAt;
  final DateTime? completedAt;
  final DateTime createdAt;

  double get progress {
    if (totalPages == null || totalPages == 0 || currentPage == null) return 0;
    return (currentPage! / totalPages!).clamp(0.0, 1.0);
  }

  ReadingItem copyWith({
    String? title,
    String? author,
    ReadingType? type,
    ReadingStatus? status,
    int? totalPages,
    int? currentPage,
    String? notes,
    String? thumbnailUrl,
    String? sourceUrl,
    DateTime? startedAt,
    DateTime? completedAt,
  }) => ReadingItem(
        id: id,
        title: title ?? this.title,
        author: author ?? this.author,
        type: type ?? this.type,
        status: status ?? this.status,
        totalPages: totalPages ?? this.totalPages,
        currentPage: currentPage ?? this.currentPage,
        notes: notes ?? this.notes,
        thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
        sourceUrl: sourceUrl ?? this.sourceUrl,
        startedAt: startedAt ?? this.startedAt,
        completedAt: completedAt ?? this.completedAt,
        createdAt: createdAt,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'author': author,
        'type': type.index,
        'status': status.index,
        'totalPages': totalPages,
        'currentPage': currentPage,
        'notes': notes,
        'thumbnailUrl': thumbnailUrl,
        'sourceUrl': sourceUrl,
        'startedAt': startedAt?.toIso8601String(),
        'completedAt': completedAt?.toIso8601String(),
        'createdAt': createdAt.toIso8601String(),
      };

  factory ReadingItem.fromMap(Map map) => ReadingItem(
        id: map['id'] as String,
        title: map['title'] as String,
        author: map['author'] as String?,
        type: ReadingType.values[(map['type'] as num?)?.toInt() ?? 0],
        status: ReadingStatus.values[(map['status'] as num?)?.toInt() ?? 0],
        totalPages: (map['totalPages'] as num?)?.toInt(),
        currentPage: (map['currentPage'] as num?)?.toInt(),
        notes: map['notes'] as String?,
        thumbnailUrl: map['thumbnailUrl'] as String?,
        sourceUrl: map['sourceUrl'] as String?,
        startedAt: map['startedAt'] != null
            ? DateTime.tryParse(map['startedAt'] as String)
            : null,
        completedAt: map['completedAt'] != null
            ? DateTime.tryParse(map['completedAt'] as String)
            : null,
        createdAt: DateTime.tryParse(map['createdAt'] as String? ?? '') ??
            DateTime.now(),
      );
}
