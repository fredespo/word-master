import 'package:flutter/material.dart';
import 'package:realm/realm.dart';
import 'package:word_master/select_all_notifier.dart';
import 'package:word_master/word_collection_card.dart';
import 'package:word_master/word_collection.dart';
import 'package:word_master/word_collection_data.dart';
import 'package:rxdart/rxdart.dart';

class WordCollectionsList extends StatelessWidget {
  final RealmResults<WordCollection> wordCollections;
  final RealmResults<WordCollection>? externalStorageWordCollections;
  final RealmResults<WordCollectionData> oldWordCollections;
  final Function(BuildContext, WordCollection) onTap;
  final Function(BuildContext, WordCollectionData) onOldTap;
  final Function(WordCollection) onDismissed;
  final Function(WordCollectionData) onOldDismissed;
  final ValueNotifier<bool> inMultiSelectMode;
  final SelectAllNotifier selectAllNotifier;
  final Function(WordCollection) onSelected;
  final Function(WordCollection) onDeselected;

  const WordCollectionsList({
    super.key,
    required this.onTap,
    required this.wordCollections,
    this.externalStorageWordCollections,
    required this.onDismissed,
    required this.oldWordCollections,
    required this.onOldTap,
    required this.onOldDismissed,
    required this.inMultiSelectMode,
    required this.onSelected,
    required this.onDeselected,
    required this.selectAllNotifier,
  });

  @override
  Widget build(BuildContext context) {
    return _buildCombinedList();
  }

  Widget _buildCombinedList() {
    return StreamBuilder<List<WordCollection>>(
      stream: _getWordCollectionsStream(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox(
            height: 300,
            child: Center(child: CircularProgressIndicator()),
          );
        }
        return ListView.builder(
          itemCount: snapshot.data!.length,
          itemBuilder: (context, index) {
            return WordCollectionCard(
              wordCollection: snapshot.data![index],
              widthFactor: 0.7,
              onTap: (evaluation) {
                onTap(context, evaluation);
              },
              isDismissible: true,
              onDismissed: (WordCollection wordCollection) {
                onDismissed(wordCollection);
              },
              confirmDismiss: (DismissDirection dir, BuildContext context,
                  String name) async {
                return await confirmDismiss(dir, context, name);
              },
              inMultiSelectMode: inMultiSelectMode,
              onSelected: onSelected,
              onDeselected: onDeselected,
              selectAllNotifier: selectAllNotifier,
            );
          },
        );
      },
    );
  }

  Stream<List<WordCollection>> _getWordCollectionsStream() {
    if (externalStorageWordCollections == null) {
      return wordCollections.changes.map(((event) => event.results.toList()));
    }
    return Rx.combineLatest2(
      wordCollections.changes.map(((event) => event.results.toList())),
      externalStorageWordCollections!.changes
          .map(((event) => event.results.toList())),
      (List<WordCollection> a, List<WordCollection> b) {
        return [...a, ...b];
      },
    ).map((event) => event.toList());
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
