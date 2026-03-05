// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'lesson.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Lesson _$LessonFromJson(Map<String, dynamic> json) => _Lesson(
  id: json['id'] as String,
  hook: json['hook'] as String,
  explanation: json['explanation'] as String,
  quizQuestion: json['quizQuestion'] as String,
  options: (json['options'] as List<dynamic>).map((e) => e as String).toList(),
  correctAnswerIndex: (json['correctAnswerIndex'] as num).toInt(),
  category: json['category'] as String,
);

Map<String, dynamic> _$LessonToJson(_Lesson instance) => <String, dynamic>{
  'id': instance.id,
  'hook': instance.hook,
  'explanation': instance.explanation,
  'quizQuestion': instance.quizQuestion,
  'options': instance.options,
  'correctAnswerIndex': instance.correctAnswerIndex,
  'category': instance.category,
};
