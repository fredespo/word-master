import 'package:realm/realm.dart';
import 'package:word_master/word_collection_entry.dart';

import 'database.dart';

class WordCollectionEntryMigration {
  String id;
  List<String> words;
  Set<String> favorites;
  String dictionaryId;

  WordCollectionEntryMigration({
    required this.id,
    required this.words,
    required this.favorites,
    required this.dictionaryId,
  });

  static void execute(WordCollectionEntryMigration migration) {
    final Realm db = Database.getDbConnection();
    db.write(() {
      for (var word in migration.words) {
        var entry = WordCollectionEntry(
          0,
          migration.id,
          migration.dictionaryId,
          word,
          migration.favorites.contains(word),
        );
        db.add(entry);
      }
    });
    db.close();
  }
}
