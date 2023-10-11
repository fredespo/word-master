import 'package:flutter/material.dart';
import 'package:realm/realm.dart';
import 'package:word_master/word_collection_card.dart';
import 'package:word_master/word_collection.dart';
import 'package:word_master/word_collection_card_old.dart';
import 'package:word_master/word_collection_data.dart';

class WordCollectionsList extends StatelessWidget {
  final RealmResults<WordCollection> wordCollections;
  final RealmResults<WordCollectionData> oldWordCollections;
  final Function(BuildContext, WordCollection) onTap;
  final Function(BuildContext, WordCollectionData) onOldTap;
  final Function(WordCollection) onDismissed;
  final Function(WordCollectionData) onOldDismissed;

  const WordCollectionsList({
    super.key,
    required this.onTap,
    required this.wordCollections,
    required this.onDismissed,
    required this.oldWordCollections,
    required this.onOldTap,
    required this.onOldDismissed,
  });

  @override
  Widget build(BuildContext context) {
    return _buildCombinedList();
  }

  Widget _buildCombinedList() {
    return StreamBuilder<RealmResultsChanges<RealmObject>>(
      stream: wordCollections.changes,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox(
            height: 300,
            child: Center(child: CircularProgressIndicator()),
          );
        }
        return ListView.builder(
          itemCount: wordCollections.length + oldWordCollections.length,
          itemBuilder: (context, index) {
            if (index < wordCollections.length) {
              return Padding(
                padding: const EdgeInsets.all(2),
                child: WordCollectionCard(
                  wordCollection: wordCollections[index],
                  widthFactor: 0.7,
                  onTap: (evaluation) {
                    onTap(context, evaluation);
                  },
                  onDismissed: (WordCollection wordCollection) {
                    onDismissed(wordCollection);
                  },
                  confirmDismiss: (DismissDirection dir, BuildContext context,
                      String name) async {
                    return await confirmDismiss(dir, context, name);
                  },
                ),
              );
            } else {
              final oldIndex = index - wordCollections.length;
              return Padding(
                padding: const EdgeInsets.all(2),
                child: OldWordCollectionCard(
                  oldWordCollection: oldWordCollections[oldIndex],
                  widthFactor: 0.7,
                  onTap: (WordCollectionData oldWordCollection) {
                    onOldTap(context, oldWordCollection);
                  },
                  onDismissed: (WordCollectionData oldWordCollection) {
                    onOldDismissed(oldWordCollection);
                  },
                  confirmDismiss: (DismissDirection dir, BuildContext context,
                      String name) async {
                    return await confirmDismiss(dir, context, name);
                  },
                ),
              );
            }
          },
        );
      },
    );
  }

  Future<bool?> confirmDismiss(direction, context, name) async {
    return await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Confirm"),
          content: Text(
              "Are you sure you want to delete the word collection \"$name\"?"),
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
  }
}
