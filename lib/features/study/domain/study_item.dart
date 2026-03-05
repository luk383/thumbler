class StudyItem {
  const StudyItem({
    required this.lessonId,
    required this.category,
    required this.addedAt,
    this.againCount = 0,
    this.goodCount = 0,
  });

  final String lessonId;
  final String category;
  final String addedAt; // yyyy-MM-dd
  final int againCount;
  final int goodCount;

  StudyItem copyWith({int? againCount, int? goodCount}) => StudyItem(
        lessonId: lessonId,
        category: category,
        addedAt: addedAt,
        againCount: againCount ?? this.againCount,
        goodCount: goodCount ?? this.goodCount,
      );

  Map<String, dynamic> toMap() => {
        'lessonId': lessonId,
        'category': category,
        'addedAt': addedAt,
        'againCount': againCount,
        'goodCount': goodCount,
      };

  factory StudyItem.fromMap(Map map) => StudyItem(
        lessonId: map['lessonId'] as String,
        category: map['category'] as String,
        addedAt: map['addedAt'] as String,
        againCount: (map['againCount'] as num?)?.toInt() ?? 0,
        goodCount: (map['goodCount'] as num?)?.toInt() ?? 0,
      );
}
