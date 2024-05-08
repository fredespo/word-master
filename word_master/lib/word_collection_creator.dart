import 'package:flutter/material.dart';
import 'package:realm/realm.dart';
import 'package:word_master/random_word_fetcher.dart';
import 'package:word_master/word_collection.dart';
import 'package:word_master/word_collection_entry.dart';
import 'package:word_master/word_collection_shuffle_dialog.dart';

class WordCollectionCreator {
  final Realm db;
  final int batchSize;

  WordCollectionCreator(this.db, this.batchSize);

  void createWordCollection(
    String name,
    Map<String, int> numEntriesPerDictionaryId,
    int numCollections,
    BuildContext context,
    Function(WordCollection)? onNewWordCollection,
  ) async {
    var progress = ValueNotifier<double>(0.0);
    showDialog(
      context: context,
      builder: (context) => ProgressDialog(
        progress: progress,
        message:
            'Creating word ${numCollections > 1 ? 'collections' : 'collection'}',
      ),
    );
    for (var i = 0; i < numCollections; ++i) {
      var curName = numCollections > 1 ? '$name ${i + 1}' : name;
      var curProgress = ValueNotifier<double>(0.0);
      curProgress.addListener(() {
        progress.value =
            (i / numCollections) + (curProgress.value / numCollections);
      });
      var wordCollection = await _createWordCollection(
          curName, numEntriesPerDictionaryId, curProgress);
      if (onNewWordCollection != null) onNewWordCollection(wordCollection);
    }
    progress.value = 1.0;
  }

  Future<WordCollection> _createWordCollection(
    String name,
    Map<String, int> numEntriesPerDictionaryId,
    ValueNotifier<double> progress,
  ) async {
    var totalEntryCount =
        numEntriesPerDictionaryId.values.reduce((a, b) => a + b);
    var wordCollection = WordCollection(
      Uuid.v4().toString(),
      name,
      DateTime.now(),
      totalEntryCount,
    );
    var curEntryCount = 0;
    for (var dictionaryId in numEntriesPerDictionaryId.keys) {
      var numEntries = numEntriesPerDictionaryId[dictionaryId]!;
      var words = RandomWordFetcher.getRandomWords(
        db,
        dictionaryId,
        numEntries,
      );
      int id = 1;
      int batchSize = 1000;
      for (int batchStart = 0;
          batchStart < words.length;
          batchStart += batchSize) {
        db.write(() {
          for (var i = batchStart;
              i < batchStart + batchSize && i < words.length;
              ++i) {
            var word = words[i];
            db.add(WordCollectionEntry(
              id++,
              wordCollection.id,
              dictionaryId,
              word,
              false,
            ));
            ++curEntryCount;
          }
        });
        progress.value = curEntryCount / totalEntryCount;
        await Future.delayed(const Duration(milliseconds: 1));
      }
    }
    db.write(() {
      db.add(wordCollection);
    });
    progress.value = 1.0;
    return wordCollection;
  }
}
