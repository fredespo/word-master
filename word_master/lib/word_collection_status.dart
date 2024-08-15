import 'package:word_master/word_collection.dart';

class WordCollectionStatus {
  static const String created = 'created';
  static const String pending = 'pending';
  static const String inProgress = 'in_progress';
  static const String pendingCopyToExternalStorage =
      'pending_copy_to_external_storage';
  static const String copyingToExternalStorage = 'copying_to_external_storage';
  static const String errored = 'errored';

  static String getStatus(WordCollection wordCollection) {
    if (wordCollection.status.isEmpty) {
      return created;
    }
    return wordCollection.status;
  }
}
