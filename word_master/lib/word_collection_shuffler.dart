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
    var shuffledIds = [];
    for (var entry in entries) {
      ids.add(entry.id);
      shuffledIds.add(entry.id);
    }
    shuffledIds.shuffle();

    // ensure everything is in a different order
    for (var i = 0; i < ids.length; i++) {
      if (ids[i] == shuffledIds[i]) {
        var swapIndex = (i + 1) % shuffledIds.length;
        var temp = shuffledIds[i];
        shuffledIds[i] = shuffledIds[swapIndex];
        shuffledIds[swapIndex] = temp;
      }
    }

    const batchSize = 1000;
    for (var batchStart = 0;
        batchStart < entries.length;
        batchStart += batchSize) {
      db.write(() {
        for (var i = batchStart;
            i < batchStart + batchSize && i < entries.length;
            ++i) {
          entries[i].id = shuffledIds[i];
        }
      });
      progress.value = batchStart / entries.length;
      await Future.delayed(const Duration(milliseconds: 1));
    }
  }
}
