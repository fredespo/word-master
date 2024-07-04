import 'package:word_master/word_collection.dart';

class WordCollectionStatus {
  static String created = 'created';
  static String pending = 'pending';
  static String inProgress = 'in_progress';

  static String getStatus(WordCollection wordCollection) {
    if (wordCollection.status.isEmpty) {
      return created;
    }
    return wordCollection.status;
  }
}
