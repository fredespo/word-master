import 'package:flutter/material.dart';
import 'package:realm/realm.dart';
import 'package:word_master/definitions.dart';

import 'dictionary_entry.dart';
import 'dictionary_entry_creation_dialog.dart';

class DefinitionsDialog extends StatelessWidget {
  final DictionaryEntry? entry;
  final String? wordOrPhrase;
  final String? dictionaryId;
  final Realm? db;
  final bool canEdit;

  const DefinitionsDialog({
    super.key,
    this.entry,
    this.wordOrPhrase,
    this.dictionaryId,
    this.db,
    this.canEdit = false,
  }) : assert(
          (db != null && wordOrPhrase != null && dictionaryId != null) ||
              entry != null,
          'Either wordOrPhrase and dictionaryId must not be null or entry must not be null',
        );

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(wordOrPhrase ?? entry!.wordOrPhrase),
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.5,
        height: MediaQuery.of(context).size.height * 0.4,
        child: Definitions(
          wordOrPhrase: wordOrPhrase,
          dictionaryId: dictionaryId,
          entry: entry,
          db: db,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: const Text('Close'),
        ),
        if (canEdit)
          ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                showDialog(
                    context: context,
                    builder: (context) {
                      return DictionaryEntryCreationDialog(
                        db: db!,
                        dictionaryId: dictionaryId!,
                        entryToEdit: entry,
                      );
                    });
              },
              child: const Text('Edit'))
      ],
    );
  }
}
