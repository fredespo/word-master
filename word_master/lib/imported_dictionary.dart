import 'package:realm/realm.dart';

part 'imported_dictionary.g.dart';

@RealmModel()
class _ImportedDictionary {
  late String dictionaryId;
  late String source;
}
