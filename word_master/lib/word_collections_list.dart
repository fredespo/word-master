import 'package:flutter/material.dart';
import 'package:realm/realm.dart';
import 'package:word_master/word_collection_card.dart';
import 'package:word_master/word_collection_data.dart';

class WordCollectionsList extends StatelessWidget {
  final RealmResults<WordCollectionData> wordCollections;
  final Function(BuildContext, WordCollectionData) onTap;

  const WordCollectionsList({
    super.key,
    required this.onTap,
    required this.wordCollections,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<RealmResultsChanges<RealmObject>>(
      stream: wordCollections.changes,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        return ListView.builder(
          itemCount: wordCollections.length,
          itemBuilder: (context, index) {
            return Padding(
              padding: const EdgeInsets.all(2),
              child: WordCollectionCard(
                wordCollection: wordCollections[index],
                widthFactor: 0.7,
                onTap: (evaluation) {
                  onTap(context, evaluation);
                },
              ),
            );
          },
        );
      },
    );
  }
}
