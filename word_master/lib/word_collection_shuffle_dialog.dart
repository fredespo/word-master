import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:word_master/word_collection.dart';

class WordCollectionShuffleDialog extends StatefulWidget {
  final WordCollection wordCollection;
  final ValueListenable<double> progress;

  const WordCollectionShuffleDialog({
    super.key,
    required this.wordCollection,
    required this.progress,
  });

  @override
  State<WordCollectionShuffleDialog> createState() =>
      _WordCollectionShuffleDialogState();
}

class _WordCollectionShuffleDialogState
    extends State<WordCollectionShuffleDialog> {
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Shuffling'),
      content: ValueListenableBuilder<double>(
        valueListenable: widget.progress,
        builder: (context, value, child) {
          return LinearProgressIndicator(
            value: value,
          );
        },
      ),
    );
  }
}
