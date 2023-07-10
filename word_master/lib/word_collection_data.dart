import 'package:realm/realm.dart';

part 'word_collection_data.g.dart';

@RealmModel()
class _WordCollectionData {
  late String name;
  late DateTime createdOn;
  late List<String> words;
}
