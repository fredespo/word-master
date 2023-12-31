import 'package:realm/realm.dart';

part 'word_collection_data.g.dart';

@RealmModel()
class _WordCollectionData {
  late String name;
  late DateTime createdOn;
  late String dictionaryId;
  late List<String> words;
  late Set<String> favorites;
}
