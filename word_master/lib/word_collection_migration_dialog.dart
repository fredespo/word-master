import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:realm/realm.dart';
import 'package:word_master/word_collection.dart';
import 'package:word_master/word_collection_data.dart';
import 'package:word_master/word_collection_entry_migration.dart';
import 'package:word_master/word_collection_status.dart';

class WordCollectionMigrationDialog extends StatefulWidget {
  final WordCollectionData oldWordCollection;
  final Realm db;
  final Function(WordCollection) onMigrated;
  final Function(String) onError;

  const WordCollectionMigrationDialog({
    super.key,
    required this.oldWordCollection,
    required this.db,
    required this.onMigrated,
    required this.onError,
  });

  @override
  State<WordCollectionMigrationDialog> createState() =>
      _WordCollectionMigrationDialogState();
}

class _WordCollectionMigrationDialogState
    extends State<WordCollectionMigrationDialog> {
  bool isMigrating = false;
  String message = 'Migrating...';

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Migrate Word Collection'),
      content: _getContent(),
      actions: _getActions(),
    );
  }

  _getContent() {
    if (!isMigrating) {
      return const Text('Migrate this word collection to the new format?');
    }
    return SizedBox(
      height: 100,
      child: Column(
        children: [
          Text(message),
          const SizedBox(height: 10),
          const CircularProgressIndicator(),
        ],
      ),
    );
  }

  List<Widget> _getActions() {
    if (isMigrating) {
      return [];
    }

    return [
      TextButton(
        onPressed: () {
          Navigator.pop(context);
        },
        child: const Text('Cancel'),
      ),
      ElevatedButton(
        onPressed: () {
          setState(() {
            isMigrating = true;
            migrate();
          });
        },
        child: const Text('Yes'),
      ),
    ];
  }

  void migrate() async {
    var newCollection = WordCollection(
      Uuid.v4().toString(),
      widget.oldWordCollection.name,
      DateTime.now(),
      widget.oldWordCollection.words.length,
      WordCollectionStatus.created,
      100,
    );

    await compute(
      WordCollectionEntryMigration.execute,
      WordCollectionEntryMigration(
        id: newCollection.id,
        words: widget.oldWordCollection.words.toList(),
        favorites: widget.oldWordCollection.favorites.toSet(),
        dictionaryId: widget.oldWordCollection.dictionaryId,
      ),
    );

    widget.db.write(() {
      widget.db.add(newCollection);
      widget.db.delete(widget.oldWordCollection);
    });

    setState(() {
      message = "Done!";
    });

    widget.onMigrated(newCollection);
  }
}
