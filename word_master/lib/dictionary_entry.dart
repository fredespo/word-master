import 'package:realm/realm.dart';

part 'dictionary_entry.g.dart';

@RealmModel()
class _DictionaryEntry {
  late String dictionaryId;
  late String wordOrPhrase;
  late String definitions;
}
