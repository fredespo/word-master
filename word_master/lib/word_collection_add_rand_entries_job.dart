import 'package:realm/realm.dart';

part 'word_collection_add_rand_entries_job.g.dart';

@RealmModel()
class _WordCollectionAddRandEntriesJob {
  late String wordCollectionId;
  late String dictionaryId;
  late int numEntries;
}
