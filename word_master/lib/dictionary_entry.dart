import 'package:realm/realm.dart';

part 'dictionary_entry.g.dart';

@RealmModel()
class _DictionaryEntry {
  @PrimaryKey()
  late String wordOrPhrase;
  late String definitions;
}
