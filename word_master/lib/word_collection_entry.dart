import 'package:realm/realm.dart';

part 'word_collection_entry.g.dart';

@RealmModel()
class _WordCollectionEntry {
  late int id;
  @Indexed()
  late String wordCollectionId;
  late String dictionaryId;
  late String wordOrPhrase;
  late bool isFavorite;
}
