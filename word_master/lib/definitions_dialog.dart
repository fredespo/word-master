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
  final Realm? externalStorageDb;
  final bool canEdit;
  final Function()? onToggleFavorite;
  final ValueNotifier<bool>? isFavoriteNotifier;

  const DefinitionsDialog({
    super.key,
    this.entry,
    this.wordOrPhrase,
    this.dictionaryId,
    this.db,
    this.canEdit = false,
    this.onToggleFavorite,
    this.isFavoriteNotifier,
    this.externalStorageDb,
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
  bool isFavorite = false;

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
    if (widget.isFavoriteNotifier != null) {
      isFavorite = widget.isFavoriteNotifier!.value;
      widget.isFavoriteNotifier!.addListener(() {
        setState(() {
          isFavorite = widget.isFavoriteNotifier!.value;
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: widget.isFavoriteNotifier == null
          ? Container()
          : Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  highlightColor: Colors.transparent,
                  splashColor: Colors.transparent,
                  hoverColor: Colors.transparent,
                  icon: Icon(Icons.star,
                      color: isFavorite ? Colors.yellow : Colors.grey,
                      size: 30),
                  onPressed: widget.onToggleFavorite,
                ),
              ],
            ),
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.6,
        height: MediaQuery.of(context).size.height * 0.5,
        child: SingleChildScrollView(
          child: Selectable(
            popupMenuItems: [
              SelectableMenuItem(type: SelectableMenuItemType.copy),
              SelectableMenuItem(
                title: 'Define',
                isEnabled: (controller) =>
                    controller!.isTextSelected &&
                    getFirstEntry([
                          controller.getSelection()!.text!,
                          controller.getSelection()!.text!.toLowerCase(),
                        ]) !=
                        null,
                handler: (controller) {
                  addDefinition(getFirstEntry([
                    controller!.getSelection()!.text!,
                    controller.getSelection()!.text!.toLowerCase(),
                  ])!);
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
                        externalStorageDb: widget.externalStorageDb,
                      );
                    });
              },
              child: const Text('Edit'))
      ],
    );
  }

  DictionaryEntry? getFirstEntry(List<String> words) {
    for (var word in words) {
      var entry = getEntry(word);
      if (entry != null) {
        return entry;
      }
    }
    return null;
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
