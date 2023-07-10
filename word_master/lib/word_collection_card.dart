import 'package:flutter/material.dart';
import 'package:word_master/word_collection_data.dart';

class WordCollectionCard extends StatelessWidget {
  final WordCollectionData wordCollection;
  final Function(WordCollectionData) onTap;
  final double widthFactor;

  const WordCollectionCard({
    super.key,
    required this.wordCollection,
    required this.onTap,
    this.widthFactor = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      child: FractionallySizedBox(
        widthFactor: widthFactor,
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: _buildBody(),
            ),
          ),
        ),
      ),
      onTap: () => onTap(wordCollection),
    );
  }

  List<Widget> _buildBody() {
    final DateTime createdOn = wordCollection.createdOn;
    return [
      Text(wordCollection.name),
      const SizedBox(height: 8),
      Text("${createdOn.month}/${createdOn.day}/${createdOn.year}"),
      const SizedBox(height: 8),
      Text("${wordCollection.words.length} entries"),
    ];
  }
}
