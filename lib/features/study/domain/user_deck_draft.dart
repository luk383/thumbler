import 'dart:convert';

class UserDeckQuestionDraft {
  UserDeckQuestionDraft({
    required this.question,
    required List<String> answers,
    required this.correctIndex,
    this.explanation = '',
    this.domain = '',
  }) : answers = List<String>.from(answers);

  String question;
  List<String> answers;
  int correctIndex;
  String explanation;
  String domain;

  UserDeckQuestionDraft copy() => UserDeckQuestionDraft(
    question: question,
    answers: answers,
    correctIndex: correctIndex,
    explanation: explanation,
    domain: domain,
  );
}

class UserDeckDraft {
  UserDeckDraft({
    required this.id,
    required this.title,
    required this.category,
    this.description = '',
    List<UserDeckQuestionDraft>? questions,
  }) : questions = questions ?? <UserDeckQuestionDraft>[];

  String id;
  String title;
  String category;
  String description;
  List<UserDeckQuestionDraft> questions;

  List<String> validate() {
    final issues = <String>[];
    if (title.trim().isEmpty) issues.add('Deck title is required');
    if (category.trim().isEmpty) issues.add('Deck category is required');
    if (questions.isEmpty) issues.add('Add at least one question');

    for (var i = 0; i < questions.length; i++) {
      final question = questions[i];
      final label = 'Question ${i + 1}';
      if (question.question.trim().isEmpty) {
        issues.add('$label is missing text');
      }
      if (question.answers.length != 4) {
        issues.add('$label must have exactly 4 answers');
      }
      final hasBlankAnswer = question.answers.any(
        (answer) => answer.trim().isEmpty,
      );
      if (hasBlankAnswer) {
        issues.add('$label has empty answer options');
      }
      if (question.correctIndex < 0 ||
          question.correctIndex >= question.answers.length) {
        issues.add('$label has an invalid correct answer');
      }
    }

    return issues;
  }

  String toNormalizedJson() {
    final normalizedCategory = category.trim();
    final domains = <String>{
      normalizedCategory,
      for (final question in questions)
        if (question.domain.trim().isNotEmpty) question.domain.trim(),
    }.toList();
    final deckMap = <String, Object?>{
      'id': id,
      'title': title.trim(),
      'category': normalizedCategory,
      'description': description.trim(),
      'version': '1',
      'domains': domains,
      'questionCount': questions.length,
      'defaultContentType': 'exam_question',
      'questions': [
        for (var i = 0; i < questions.length; i++)
          {
            'id': 'q_${(i + 1).toString().padLeft(3, '0')}',
            'question': questions[i].question.trim(),
            'answers': questions[i].answers
                .map((answer) => answer.trim())
                .toList(),
            'correctIndex': questions[i].correctIndex,
            'explanation': questions[i].explanation.trim(),
            'domain': questions[i].domain.trim().isEmpty
                ? normalizedCategory
                : questions[i].domain.trim(),
          },
      ],
    };

    return const JsonEncoder.withIndent('  ').convert(deckMap);
  }
}
