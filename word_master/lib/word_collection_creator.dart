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

    handleLeftover(db);

    while (true) {
      final pendingWordCollection = createOnInternalStorage(db);
      final copyToExternal = createOnExternalStorage(db, externalStorageDb);
      final deleted = deleteOnInternalStorage(db);
      if (pendingWordCollection == null &&
          copyToExternal == null &&
          deleted == null) {
        await Future.delayed(const Duration(seconds: 5));
      }
    }
  }

  static WordCollection? createOnInternalStorage(Realm db) {
    WordCollection? pendingWordCollection;
    try {
      pendingWordCollection = getNextPendingWordCollection(db);
    } catch (e) {
      debugPrint(
          "Could not get next word collection to create on internal storage: $e");
    }

    if (pendingWordCollection != null) {
      try {
        createEntries(pendingWordCollection, db);
      } catch (e) {
        markCollectionAsErrored(pendingWordCollection, db, e.toString());
      }
    }
    return pendingWordCollection;
  }

  static WordCollection? createOnExternalStorage(
    Realm db,
    Realm? externalStorageDb,
  ) {
    WordCollection? copyToExternal;
    try {
      copyToExternal = getNextToCopyToExternal(
        db,
        externalStorageDb,
      );
    } catch (e) {
      debugPrint("Could not get next collection to copy to external: $e");
    }

    if (copyToExternal != null) {
      try {
        _copyToExternalStorage(copyToExternal, db, externalStorageDb!);
      } catch (e) {
        debugPrint("Could not copy to external storage: $e");
      }
    }
    return copyToExternal;
  }

  static WordCollection? deleteOnInternalStorage(Realm db) {
    try {
      WordCollection? toDelete = getNextToDelete(db);
      if (toDelete != null) {
        var id = toDelete.id;
        db.write(() {
          var entries =
              db.all<WordCollectionEntry>().query("wordCollectionId == '$id'");
          for (var entry in entries) {
            db.delete(entry);
          }
          db.delete(toDelete);
        });
      }
      return toDelete;
    } catch (e) {
      debugPrint("Could not delete collection: $e");
      return null;
    }
  }

  static void handleLeftover(Realm db) {
    List<WordCollection> leftover = [];
    try {
      leftover = db
          .all<WordCollection>()
          .where((c) =>
              WordCollectionStatus.getStatus(c) ==
                  WordCollectionStatus.pending ||
              WordCollectionStatus.getStatus(c) ==
                  WordCollectionStatus.inProgress)
          .toList();
    } catch (e) {
      debugPrint("Could not get leftover collections: $e");
    }

    for (final collection in leftover) {
      try {
        if (isOrphaned(collection, db)) {
          db.write(() => db.delete(collection));
        } else {
          createEntries(collection, db);
        }
      } catch (e) {
        markCollectionAsErrored(collection, db, e.toString());
      }
    }
  }

  static WordCollection? getNextToDelete(Realm db) {
    try {
      return db.all<WordCollection>().firstWhere((c) =>
          WordCollectionStatus.getStatus(c) ==
          WordCollectionStatus.markedForDeletion);
    } on StateError {
      return null;
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

    if (wordCollection.name.startsWith("error")) {
      throw Exception("Word collection name starts with error");
    }
    if (wordCollection.name.startsWith("longerror")) {
      throw Exception(
          "Word collection name starts with longerror. fdjaslfj dsa;fhjsd gfdsg fdsg dsgjfd sgfdls gjdfslg jfldsa jflkdsa jfsalkf j ljdslkalkg jsaklfg jdslkg jsaklf; jklf j ;fgjiewa godsfk;ljfla gfjfds gijlrk;raeiog fdsjg;lf dsgkdfls jfgl jklfds jgklfd jsg;k jdfs;kl;g; jfdslk;kgfdsj gklfds; jg klfds jg jior egijlkfd; jgio ;jrlkgj ;i ljfkdsjgfdls jglkfds jglsdjgi ore;alkgj fdislkj;s egjkfd jg;flk;ds jg f irea ;gjlkfdsj gior;dlsjg; iro;djgisdlfjgksgirod gj;ksdffjgklsg;dflig jriosg;fdksgjifodslig jirsdlfjg ;kfds jgirosd jgirlds jgifdskgjf;dslirsjgfdlksir jg;krldf gjirdfs jgilkdsjgfldsjgkdsgjfkdlsgjdflsgj jir sj;gdf jgiorlk;gfidsl gjkrsjgo;il fkdjsgi;o;r esgfdjsk;fj g;i;rsjlkg fdslk;j gifdsgreslkkjgkfldsjgidsf vfisfklds jgflds ifjsl;gjfkdsl gjrigrjg klfds; jgfsdgfdkinlfs;knbfd;skngdf sjjfjjfj fj fjfjfjlkfzjglksdjjjjjjjjjjjjjjjjjj jjjjjjjjjjjjjjjj jjjjjjjjjjjjjjjjjjjjjjjjjjj jjjjjjjjjjjjjjjjjjjj jjjjjjjjjjjjjjjjjjjjjjjjj jjjjjjjjjjjjjjjjjjjj jjjjjjjjjjjjjjjjjjjjjj jjjjjjjjjjjjjjjjjjjjjj jjjjjjjjjjjjjjjjjjjjj jjjjjjjjjjjjjjjjjjjj jfdlg ds;flg dfhsjkg hfdsiogeau gpnlf;kdsjgifdosug dflks gjdios g d fajgoiera;gfdsg dfsii; jg;dfklsgj fdiosg dsgj reagjk;dr s g;fdlis gids gjfdls;sgfds gfdjsk gjfids gdfjs gfdsgi ;fdjgk dsig;jfd;sl gjfdsklg kljfdsg hfdli;kg fdjskghsoi jio");
    }

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

    try {
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
    } finally {
      internalStorageDb.write(() {
        collection.status = WordCollectionStatus.created;
      });
    }
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

  static void markCollectionAsErrored(
    WordCollection collection,
    Realm db,
    String message,
  ) {
    try {
      db.write(() {
        collection.status = WordCollectionStatus.errored;
        collection.errorMessage = message;
      });
    } catch (e) {
      debugPrint("Could not mark collection ${collection.name} as errored: $e");
    }
  }
}
