import 'package:flutter/material.dart';
import 'package:realm/realm.dart';
import 'package:word_master/random_words_selector.dart';
import 'package:word_master/word_collection.dart';

import 'dictionary.dart';

class WordCollectionAdder extends StatefulWidget {
  final Function(Map<String, int>) onAddEntries;
  final RealmResults<Dictionary> dictionaries;
  final Realm db;
  final WordCollection wordCollection;

  const WordCollectionAdder({
    super.key,
    required this.onAddEntries,
    required this.dictionaries,
    required this.db,
    required this.wordCollection,
  });

  @override
  State<WordCollectionAdder> createState() => _WordCollectionAdderState();
}

class _WordCollectionAdderState extends State<WordCollectionAdder> {
  Map<String, int> numEntriesPerDictionaryId = {};

  @override
  Widget build(BuildContext context) {
    return widget.dictionaries.isEmpty ||
            widget.dictionaries.every((element) => element.size == 0)
        ? AlertDialog(
            title: const Text('No words found'),
            content: const Text('Please add or import dictionary data first.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('OK'),
              ),
            ],
          )
        : AlertDialog(
            title: const Text('Add entries', textAlign: TextAlign.center),
            content: IntrinsicHeight(
              child: RandomWordsSelector(
                existingWordCollection: widget.wordCollection,
                dictionaries: widget.dictionaries,
                db: widget.db,
                onNumEntriesChanged: (Dictionary dict, int numEntries) {
                  setState(() {
                    if (numEntries == 0) {
                      numEntriesPerDictionaryId.remove(dict.id);
                      return;
                    }
                    numEntriesPerDictionaryId[dict.id] = numEntries;
                  });
                },
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: numEntriesPerDictionaryId.isNotEmpty
                    ? () {
                        Navigator.of(context).pop();
                        widget.onAddEntries(numEntriesPerDictionaryId);
                      }
                    : null,
                child: const Text('Add'),
              ),
            ],
          );
  }
}
