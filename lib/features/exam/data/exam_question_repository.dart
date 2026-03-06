import '../../study/data/study_storage.dart';
import '../../study/domain/study_item.dart';

/// Reads exam questions from the shared study_box.
/// Only returns items with contentType == examQuestion.
class ExamQuestionRepository {
  List<StudyItem> loadAll({String? deckId}) => StudyStorage()
      .allForDeck(deckId)
      .where((i) => i.contentType == ContentType.examQuestion)
      .toList();
}
