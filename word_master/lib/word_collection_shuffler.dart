import 'package:flutter/foundation.dart';
import 'package:realm/realm.dart';
import 'package:word_master/word_collection.dart';
import 'package:word_master/word_collection_entry.dart';

class WordCollectionShuffler {
  static Future shuffle(
    WordCollection collection,
    ValueNotifier<double> progress,
    Realm db,
  ) async {
    await Future.delayed(const Duration(milliseconds: 500));
    var entries = db
        .all<WordCollectionEntry>()
        .query("wordCollectionId == '${collection.id}'")
        .toList();
    var ids = [];
    for (var entry in entries) {
      ids.add(entry.id);
    }
    ids.shuffle();
    const batchSize = 1000;
    for (var batchStart = 0;
        batchStart < entries.length;
        batchStart += batchSize) {
      db.write(() {
        for (var i = batchStart;
            i < batchStart + batchSize && i < entries.length;
            ++i) {
          entries[i].id = ids[i];
        }
      });
      progress.value = batchStart / entries.length;
      await Future.delayed(const Duration(milliseconds: 1));
    }
  }
}
