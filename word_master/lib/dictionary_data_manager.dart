import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:realm/realm.dart';
import 'package:word_master/dictionary.dart';
import 'package:word_master/dictionary_data_importer.dart';
import 'package:word_master/dictionary_editor.dart';
import 'package:word_master/imported_dictionary.dart';

import 'dictionary_creation_dialog.dart';

class DictionaryDataManager extends StatefulWidget {
  final Realm db;
  final Realm? externalStorageDb;

  const DictionaryDataManager({
    super.key,
    required this.db,
    required this.externalStorageDb,
  });

  @override
  State<DictionaryDataManager> createState() => _DictionaryDataManagerState();
}

class _DictionaryDataManagerState extends State<DictionaryDataManager> {
  final NumberFormat _numberFormat = NumberFormat('#,##0');
  RealmResults<Dictionary>? dictionaries;

  @override
  void initState() {
    super.initState();
    dictionaries = widget.db.all<Dictionary>();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dictionaries'),
      ),
      body: _buildBody(),
      floatingActionButton: Padding(
        padding: const EdgeInsets.fromLTRB(0, 0, 30, 30),
        child: FloatingActionButton(
          onPressed: () {
            _createNewDictionary();
          },
          child: const Icon(Icons.add),
        ),
      ),
    );
  }

  Widget _buildBody() {
    return dictionaries == null
        ? const Center(child: CircularProgressIndicator())
        : Center(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(0, 30, 0, 0),
              child: FractionallySizedBox(
                widthFactor: 0.5,
                child: _buildDictionaryList(),
              ),
            ),
          );
  }

  Widget _buildDictionaryList() {
    return StreamBuilder<RealmResultsChanges<RealmObject>>(
      stream: dictionaries!.changes,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        return ListView.builder(
          itemCount: dictionaries!.length,
          itemBuilder: (context, index) {
            return Padding(
              padding: const EdgeInsets.all(2),
              child: _buildDictionaryCard(dictionaries![index]),
            );
          },
        );
      },
    );
  }

  Widget _buildDictionaryCard(Dictionary dictionary) {
    var children = [
      Text(
        dictionary.name,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      const SizedBox(height: 8),
      Text(
          "${_numberFormat.format(dictionary.size)} ${dictionary.size == 1 ? "entry" : "entries"}"),
    ];
    var isImported = widget.db
        .all<ImportedDictionary>()
        .where((element) => element.dictionaryId == dictionary.id)
        .isNotEmpty;
    if (isImported) {
      children.add(const SizedBox(height: 8));
      children.add(DictionaryDataImporter(
        db: widget.db,
        dictionaryId: dictionary.id,
      ));
    }
    return Dismissible(
      key: Key(dictionary.id),
      confirmDismiss: (direction) async {
        if (isImported) {
          return false;
        }

        return await showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text("Confirm"),
              content: Text(
                  "Are you sure you want to delete the dictionary \"${dictionary.name}\"?"),
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
          widget.db.delete(dictionary);
        });
      },
      child: InkWell(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => DictionaryEditor(
              dictionary: dictionary,
              db: widget.db,
              externalStorageDb: widget.externalStorageDb,
            ),
          ),
        ),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: children,
            ),
          ),
        ),
      ),
    );
  }

  void _createNewDictionary() {
    showDialog(
      context: context,
      builder: (context) {
        return DictionaryCreationDialog(
          onCreated: (String name) {
            widget.db.write(() {
              var id = Uuid.v4().toString();
              var dictionary = Dictionary(id, name);
              widget.db.add(dictionary);
            });
          },
        );
      },
    );
  }
}
