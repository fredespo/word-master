import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:realm/realm.dart';
import 'package:word_master/database.dart';
import 'package:word_master/word_collection.dart';
import 'package:word_master/word_collection_add_rand_entries_job.dart';
import 'package:word_master/word_collection_data.dart';
import 'package:word_master/word_collection_entry.dart';
import 'package:word_master/word_collection_status.dart';

import 'dictionary.dart';
import 'dictionary_entry.dart';
import 'imported_dictionary.dart';

class ExternalStorageChecker {
  static checkExternalStorage(BuildContext context) async {
    var message = await _checkExternalStorageAndGetMessage();
    // show dialog with message
    // ignore: use_build_context_synchronously
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('External Storage Check'),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  static Future<String> _checkExternalStorageAndGetMessage() async {
    if (!Platform.isAndroid) {
      return "❌ Not on Android";
    }

    try {
      var dir = await getExternalStorageDirectory();
      Realm(Configuration.local(
        [
          DictionaryEntry.schema,
          WordCollectionData.schema,
          Dictionary.schema,
          ImportedDictionary.schema,
          WordCollectionEntry.schema,
          WordCollection.schema,
          WordCollectionAddRandEntriesJob.schema
        ],
        schemaVersion: 12,
        path: '${dir?.path}/word_master.realm',
      ));
      return '✅ Can successfully use external storage at ${dir?.path}';
    } catch (e) {
      return "🚫 Error: ${e.toString()}";
    }
  }
}
