import 'dart:io';
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
  WordCollectionCreator();

  static watchForWordCollectionsToCreateInBg(String? extDir) {
    RootIsolateToken token = RootIsolateToken.instance!;
    Isolate.spawn((t) => _createWordCollections(t, extDir), token);
  }

  static Future<void> _createWordCollections(
    RootIsolateToken token,
    String? extDir,
  ) async {
    Realm db = Database.getDbConnection();
    Realm? externalStorageDb =
        extDir != null ? Database.getDbFromDir(Directory(extDir)) : null;

    final leftover = db
        .all<WordCollection>()
        .where((c) =>
            WordCollectionStatus.getStatus(c) == WordCollectionStatus.pending ||
            WordCollectionStatus.getStatus(c) ==
                WordCollectionStatus.inProgress)
        .toList();
    for (final collection in leftover) {
      if (isOrphaned(collection, db)) {
        db.write(() => db.delete(collection));
      } else {
        createEntries(collection, db);
      }
    }

    while (true) {
      final pendingWordCollection = getNextPendingWordCollection(db);
      if (pendingWordCollection != null) {
        createEntries(pendingWordCollection, db);
      }

      final copyToExternal = getNextToCopyToExternal(
        db,
        externalStorageDb,
      );
      if (copyToExternal != null) {
        _copyToExternalStorage(copyToExternal, db, externalStorageDb!);
      }

      if (pendingWordCollection == null && copyToExternal == null) {
        await Future.delayed(const Duration(seconds: 5));
      }
    }
  }

  static WordCollection? getNextPendingWordCollection(Realm db) {
    try {
      return db.all<WordCollection>().firstWhere((c) =>
          WordCollectionStatus.getStatus(c) == WordCollectionStatus.pending ||
          WordCollectionStatus.getStatus(c) == WordCollectionStatus.inProgress);
    } on StateError {
      return null;
    }
  }

  static WordCollection? getNextToCopyToExternal(
    Realm internalStorageDb,
    Realm? externalStorageDb,
  ) {
    if (externalStorageDb == null) {
      return null;
    }

    try {
      return internalStorageDb.all<WordCollection>().firstWhere((c) =>
          WordCollectionStatus.getStatus(c) ==
              WordCollectionStatus.pendingCopyToExternalStorage ||
          WordCollectionStatus.getStatus(c) ==
              WordCollectionStatus.copyingToExternalStorage);
    } on StateError {
      return null;
    }
  }

  static bool isOrphaned(WordCollection wordCollection, Realm db) {
    return db
        .all<WordCollectionAddRandEntriesJob>()
        .where((e) => e.wordCollectionId == wordCollection.id)
        .isEmpty;
  }

  static void createEntries(WordCollection wordCollection, Realm db) {
    db.write(() {
      wordCollection.status = WordCollectionStatus.inProgress;
    });

    final randEntries = db
        .all<WordCollectionAddRandEntriesJob>()
        .where((e) => e.wordCollectionId == wordCollection.id)
        .toList();
    for (final entries in randEntries) {
      db.write(() {
        _createWordCollectionEntries(
          db,
          wordCollection.id,
          entries.dictionaryId,
          entries.numEntries,
        );
        db.delete(entries);
      });
    }

    db.write(() {
      wordCollection.status = WordCollectionStatus.created;
    });
  }

  static void _copyToExternalStorage(
    WordCollection collection,
    Realm internalStorageDb,
    Realm externalStorageDb,
  ) {
    internalStorageDb.write(() {
      collection.status = WordCollectionStatus.copyingToExternalStorage;
    });

    var entries = internalStorageDb
        .all<WordCollectionEntry>()
        .query("wordCollectionId == '${collection.id}'")
        .toList();
    WordCollection newCollection = WordCollection(
      Uuid.v4().toString(),
      collection.name,
      collection.createdOn,
      collection.size,
      WordCollectionStatus.created,
      entries.length.toDouble(),
    );
    newCollection.isOnExternalStorage = true;

    externalStorageDb.write(() {
      for (final entry in entries) {
        externalStorageDb.add(
          WordCollectionEntry(
            entry.id,
            newCollection.id,
            entry.dictionaryId,
            entry.wordOrPhrase,
            entry.isFavorite,
          ),
        );
      }
      externalStorageDb.add(newCollection);
    });

    internalStorageDb.write(() {
      collection.status = WordCollectionStatus.created;
    });
  }

  void createWordCollection(
      String name,
      Map<String, int> numEntriesPerDictionaryId,
      int numCollections,
      BuildContext context,
      Realm db) async {
    for (var i = 0; i < numCollections; ++i) {
      var curName = numCollections > 1 ? '$name ${i + 1}' : name;
      var wordCollection = _createWordCollectionWithoutEntries(
        curName,
        numEntriesPerDictionaryId,
        db,
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
    Realm db,
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

  static void _createWordCollectionEntries(
    Realm db,
    String wordCollectionId,
    String dictionaryId,
    int numEntries,
  ) async {
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
