import 'package:flutter/material.dart';
import 'package:realm/realm.dart';
import 'package:word_master/dictionary_entry.dart';
import 'package:word_master/imported_dictionary.dart';

import 'definitions_dialog.dart';
import 'dictionary.dart';
import 'dictionary_entry_creation_dialog.dart';

class DictionaryEditor extends StatefulWidget {
  final Dictionary dictionary;
  final Realm db;
  final Realm? externalStorageDb;

  const DictionaryEditor({
    super.key,
    required this.dictionary,
    required this.db,
    required this.externalStorageDb,
  });

  @override
  State<DictionaryEditor> createState() => _DictionaryEditorState();
}

class _DictionaryEditorState extends State<DictionaryEditor> {
  RealmResults<DictionaryEntry>? entries;
  late bool isDictionaryImported;

  @override
  void initState() {
    super.initState();
    entries = widget.db.all<DictionaryEntry>().query(
        "dictionaryId == '${widget.dictionary.id}' SORT(wordOrPhrase ASC)");
    try {
      widget.db
          .all<ImportedDictionary>()
          .query("dictionaryId == '${widget.dictionary.id}'")
          .first;
      isDictionaryImported = true;
    } catch (e) {
      isDictionaryImported = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${isDictionaryImported ? 'Viewing' : 'Editing'} Dictionary "${widget.dictionary.name}"',
        ),
      ),
      body: Center(
        child: _buildEntriesList(),
      ),
      floatingActionButton: isDictionaryImported
          ? null
          : Padding(
              padding: const EdgeInsets.fromLTRB(0, 0, 30, 30),
              child: Builder(builder: (context) {
                return FloatingActionButton(
                  child: const Icon(Icons.add),
                  onPressed: () => showDialog(
                      context: context,
                      builder: (context) {
                        return DictionaryEntryCreationDialog(
                          db: widget.db,
                          dictionaryId: widget.dictionary.id,
                          externalStorageDb: widget.externalStorageDb,
                        );
                      }),
                );
              }),
            ),
    );
  }

  Widget _buildEntriesList() {
    return StreamBuilder<RealmResultsChanges<RealmObject>>(
      stream: entries!.changes,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        return ListView.builder(
          itemCount: entries!.length,
          itemBuilder: (context, index) {
            return Padding(
              padding: const EdgeInsets.all(2),
              child: _buildEntry(entries![index]),
            );
          },
        );
      },
    );
  }

  Widget _buildEntry(DictionaryEntry entry) {
    return Dismissible(
      key: Key(entry.dictionaryId + entry.wordOrPhrase),
      confirmDismiss: (direction) async {
        return await showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text("Confirm"),
              content: Text(
                  "Are you sure you want to delete the entry \"${entry.wordOrPhrase}\"?"),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text("Cancel"),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                  ),
                  child: const Text(
                    "DELETE",
                  ),
                ),
              ],
            );
          },
        );
      },
      onDismissed: (direction) {
        widget.db.write(() {
          widget.db.delete(entry);
          widget.dictionary.size--;
        });
      },
      child: FractionallySizedBox(
        widthFactor: 0.4,
        child: InkWell(
          onTap: () {
            showDialog(
              context: context,
              builder: (context) {
                return DefinitionsDialog(
                  entry: entry,
                  db: widget.db,
                  dictionaryId: widget.dictionary.id,
                  canEdit: !isDictionaryImported,
                );
              },
            );
          },
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                entry.wordOrPhrase,
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
