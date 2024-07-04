import 'dart:isolate';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:realm/realm.dart';
import 'package:word_master/random_word_fetcher.dart';
import 'package:word_master/word_collection.dart';
import 'package:word_master/word_collection_add_rand_entries_job.dart';
import 'package:word_master/word_collection_entry.dart';
import 'package:word_master/word_collection_status.dart';

import 'database.dart';

class WordCollectionCreator {
  final Realm db;

  WordCollectionCreator(this.db);

  static watchForWordCollectionsToCreateInBg() {
    RootIsolateToken token = RootIsolateToken.instance!;
    Isolate.spawn(_createWordCollections, token);
  }

  static Future<void> _createWordCollections(RootIsolateToken token) async {
    Realm db = Database.getDbConnection();
    final leftover = db
        .all<WordCollection>()
        .where((c) =>
            WordCollectionStatus.getStatus(c) != WordCollectionStatus.created)
        .toList();
    for (final collection in leftover) {
      if (isOrphaned(collection, db)) {
        db.write(() => db.delete(collection));
      } else {
        createEntries(collection, db);
      }
    }

    while (true) {
      try {
        final wordCollection = db
            .all<WordCollection>()
            .where((c) =>
                WordCollectionStatus.getStatus(c) ==
                WordCollectionStatus.pending)
            .first;
        createEntries(wordCollection, db);
      } on StateError {
        await Future.delayed(const Duration(seconds: 5));
        continue;
      }
    }
  }

  static bool isOrphaned(WordCollection wordCollection, Realm db) {
    return db
        .all<WordCollectionAddRandEntriesJob>()
        .where((e) => e.wordCollectionId == wordCollection.id)
        .isEmpty;
  }

  static void createEntries(WordCollection wordCollection, Realm db) {
    final randEntries = db
        .all<WordCollectionAddRandEntriesJob>()
        .where((e) => e.wordCollectionId == wordCollection.id)
        .toList();
    db.write(() {
      WordCollectionStatus.getStatus(c) = WordCollectionStatus.inProgress;
    });
    db.write(() {
      for (final entries in randEntries) {
        _createWordCollectionEntries(
          db,
          wordCollection.id,
          entries.dictionaryId,
          entries.numEntries,
        );
        db.delete(entries);
      }
      wordCollection.status = WordCollectionStatus.created;
    });
  }

  void createWordCollection(
      String name,
      Map<String, int> numEntriesPerDictionaryId,
      int numCollections,
      BuildContext context) async {
    for (var i = 0; i < numCollections; ++i) {
      var curName = numCollections > 1 ? '$name ${i + 1}' : name;
      var wordCollection = _createWordCollectionWithoutEntries(
        curName,
        numEntriesPerDictionaryId,
      );
      db.write(() {
        for (final entries in numEntriesPerDictionaryId.entries) {
          db.add(WordCollectionAddRandEntriesJob(
            wordCollection.id,
            entries.key,
            entries.value,
          ));
        }
      });
    }
  }

  WordCollection _createWordCollectionWithoutEntries(
    String name,
    Map<String, int> numEntriesPerDictionaryId,
  ) {
    var totalEntryCount =
        numEntriesPerDictionaryId.values.reduce((a, b) => a + b);
    var wordCollection = WordCollection(
      Uuid.v4().toString(),
      name,
      DateTime.now(),
      totalEntryCount,
      WordCollectionStatus.pending,
      0,
    );
    db.write(() {
      db.add(wordCollection);
    });
    return wordCollection;
  }

  static void _createWordCollectionEntries(Realm db, String wordCollectionId,
      String dictionaryId, int numEntries) async {
    var words = RandomWordFetcher.getRandomWords(
      db,
      dictionaryId,
      numEntries,
    );
    var id = 1;
    for (final word in words) {
      db.add(WordCollectionEntry(
        id++,
        wordCollectionId,
        dictionaryId,
        word,
        false,
      ));
    }
  }
}
