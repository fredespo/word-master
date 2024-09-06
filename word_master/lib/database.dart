import 'dart:io';

import 'package:realm/realm.dart';
import 'package:word_master/word_collection.dart';
import 'package:word_master/word_collection_add_rand_entries_job.dart';
import 'package:word_master/word_collection_data.dart';
import 'package:word_master/word_collection_entry.dart';

import 'dictionary.dart';
import 'dictionary_entry.dart';
import 'imported_dictionary.dart';
import 'package:path_provider/path_provider.dart';

class Database {
  static final List<SchemaObject> _schema = [
    DictionaryEntry.schema,
    WordCollectionData.schema,
    Dictionary.schema,
    ImportedDictionary.schema,
    WordCollectionEntry.schema,
    WordCollection.schema,
    WordCollectionAddRandEntriesJob.schema
  ];
  static const _schemaVersion = 14;

  static Realm getDbConnection() {
    return Realm(Configuration.local(
      _schema,
      schemaVersion: _schemaVersion,
    ));
  }

  static Future<String?> getExternalStoragePath() async {
    if (!Platform.isAndroid) {
      return null;
    }

    var dirs = await getExternalStorageDirectories();
    if (dirs == null || dirs.length < 2) {
      return null;
    }

    return dirs[1].path;
  }

  static Future<Realm?> getExternalStorageDb() async {
    var extPath = await getExternalStoragePath();
    if (extPath == null) return null;
    return getDbFromDir(Directory(extPath));
  }

  static Realm? getDbFromDir(Directory dir) {
    try {
      return Realm(Configuration.local(
        _schema,
        schemaVersion: _schemaVersion,
        path: '${dir.path}/word_master.realm',
      ));
    } catch (e) {
      return null;
    }
  }

  static Realm selectDb(
    WordCollection wordCollection,
    Realm internalStorageDb,
    Realm? externalStorageDb,
  ) {
    return wordCollection.isOnExternalStorage == true &&
            externalStorageDb != null
        ? externalStorageDb
        : internalStorageDb;
  }

  static Future<Map<String, String>> getStoragePaths() async {
    Map<String, String> storagePaths = {};
    if (!Platform.isAndroid) {
      return storagePaths;
    }
    var newExternalDirs = await getExternalStorageDirectories();
    for (var i = 0; i < newExternalDirs!.length; i++) {
      storagePaths['New external $i'] = newExternalDirs[i].path;
    }
    return storagePaths;
  }
}
