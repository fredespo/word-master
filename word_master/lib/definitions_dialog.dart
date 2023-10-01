import 'package:flutter/material.dart';
import 'package:realm/realm.dart';
import 'package:word_master/definitions.dart';

import 'dictionary_entry.dart';
import 'dictionary_entry_creation_dialog.dart';
import 'package:selectable/selectable.dart';

class DefinitionsDialog extends StatefulWidget {
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
  State<DefinitionsDialog> createState() => _DefinitionsDialogState();
}

class _DefinitionsDialogState extends State<DefinitionsDialog> {
  List<Widget> defs = [];

  @override
  void initState() {
    super.initState();
    defs.add(
      Definitions(
        wordOrPhrase: widget.wordOrPhrase,
        dictionaryId: widget.dictionaryId,
        entry: widget.entry,
        db: widget.db,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.5,
        height: MediaQuery.of(context).size.height * 0.4,
        child: SingleChildScrollView(
          child: Selectable(
            popupMenuItems: [
              SelectableMenuItem(type: SelectableMenuItemType.copy),
              SelectableMenuItem(
                title: 'Define',
                isEnabled: (controller) =>
                    controller!.isTextSelected &&
                    getEntry(controller.getSelection()!.text!) != null,
                handler: (controller) {
                  addDefinition(getEntry(controller!.getSelection()!.text!)!);
                  controller.deselectAll();
                  return true;
                },
              ),
            ],
            child: Column(children: defs),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: const Text('Close'),
        ),
        if (widget.canEdit)
          ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                showDialog(
                    context: context,
                    builder: (context) {
                      return DictionaryEntryCreationDialog(
                        db: widget.db!,
                        dictionaryId: widget.dictionaryId!,
                        entryToEdit: widget.entry,
                      );
                    });
              },
              child: const Text('Edit'))
      ],
    );
  }

  DictionaryEntry? getEntry(String wordOrPhrase) {
    var entryFromThisDict = getEntryFromThisDictionary(wordOrPhrase);
    if (entryFromThisDict != null) {
      return entryFromThisDict;
    }
    var entryFromOtherDict = getEntryFromOtherDictionary(wordOrPhrase);
    return entryFromOtherDict;
  }

  DictionaryEntry? getEntryFromThisDictionary(String wordOrPhrase) {
    try {
      return widget.db!
          .all<DictionaryEntry>()
          .query("dictionaryId == '${widget.dictionaryId}'")
          .query("wordOrPhrase == \$0", [wordOrPhrase]).first;
    } catch (e) {
      return null;
    }
  }

  DictionaryEntry? getEntryFromOtherDictionary(String wordOrPhrase) {
    try {
      return widget.db!
          .all<DictionaryEntry>()
          .query("wordOrPhrase == \$0", [wordOrPhrase]).first;
    } catch (e) {
      return null;
    }
  }

  void addDefinition(DictionaryEntry entry) {
    setState(() {
      defs.add(
        const Divider(thickness: 3),
      );
      defs.add(
        Definitions(
          wordOrPhrase: entry.wordOrPhrase,
          dictionaryId: widget.dictionaryId,
          entry: entry,
          db: widget.db,
        ),
      );
    });
  }
}
