import 'package:flutter/material.dart';
import 'package:realm/realm.dart';
import 'package:word_master/random_words_selector.dart';

import 'dictionary.dart';

class WordCollectionCreator extends StatefulWidget {
  final Function(String, Map<String, int>) onCreate;
  final RealmResults<Dictionary> dictionaries;
  final Realm db;

  const WordCollectionCreator({
    super.key,
    required this.onCreate,
    required this.dictionaries,
    required this.db,
  });

  @override
  State<WordCollectionCreator> createState() => _WordCollectionCreatorState();
}

class _WordCollectionCreatorState extends State<WordCollectionCreator> {
  String name = '';
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
            title: const Text('Create a new collection',
                textAlign: TextAlign.center),
            content: IntrinsicHeight(
              child: Column(children: [
                TextField(
                  onChanged: (value) {
                    setState(() {
                      name = value;
                    });
                  },
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Name',
                  ),
                ),
                const SizedBox(height: 20),
                RandomWordsSelector(
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
              ]),
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
                        widget.onCreate(name, numEntriesPerDictionaryId);
                      }
                    : null,
                child: const Text('Create'),
              ),
            ],
          );
  }
}
