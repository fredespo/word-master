import 'package:flutter/material.dart';
import 'package:realm/realm.dart';
import 'package:word_master/word_collection.dart';
import 'package:word_master/word_collection_data.dart';
import 'package:word_master/word_collection_entry.dart';

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
    try {
      var newCollection = WordCollection(
        Uuid.v4().toString(),
        widget.oldWordCollection.name,
        DateTime.now(),
        widget.oldWordCollection.words.length,
      );

      int count = 0;
      int sinceLastDelay = 0;
      for (var word in widget.oldWordCollection.words) {
        var entry = WordCollectionEntry(
          newCollection.id,
          widget.oldWordCollection.dictionaryId,
          word,
          widget.oldWordCollection.favorites.contains(word),
        );
        widget.db.write(() {
          try {
            widget.db.add(entry);
          } catch (e) {
            widget.onError(e.toString());
          }
        });
        ++count;
        ++sinceLastDelay;
        if (sinceLastDelay >= 4) {
          setState(() {
            message =
                'Migrating $count of ${widget.oldWordCollection.words.length} entries';
          });
          sinceLastDelay = 0;
          await Future.delayed(const Duration(microseconds: 10));
        }
      }
      setState(() {
        message = "Done!";
      });

      widget.db.write(() {
        try {
          widget.db.add(newCollection);
          widget.db.delete(widget.oldWordCollection);
        } catch (e) {
          widget.onError(e.toString());
        }
      });

      widget.onMigrated(newCollection);
    } catch (e) {
      widget.onError(e.toString());
    }
  }
}
