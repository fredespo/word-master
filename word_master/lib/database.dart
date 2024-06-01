import 'package:realm/realm.dart';
import 'package:word_master/word_collection.dart';
import 'package:word_master/word_collection_data.dart';
import 'package:word_master/word_collection_entry.dart';

import 'dictionary.dart';
import 'dictionary_entry.dart';
import 'imported_dictionary.dart';

class Database {
  static Realm getDbConnection() {
    return Realm(Configuration.local(
      [
        DictionaryEntry.schema,
        WordCollectionData.schema,
        Dictionary.schema,
        ImportedDictionary.schema,
        WordCollectionEntry.schema,
        WordCollection.schema,
      ],
      schemaVersion: 10,
    ));
  }
}
