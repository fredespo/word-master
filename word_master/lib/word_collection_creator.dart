import 'package:flutter/material.dart';
import 'package:realm/realm.dart';
import 'package:word_master/slider_with_value.dart';

import 'dictionary_entry.dart';

class WordCollectionCreator extends StatefulWidget {
  final Function(String, int) onCreate;
  final RealmResults<DictionaryEntry> entries;

  const WordCollectionCreator({
    super.key,
    required this.onCreate,
    required this.entries,
  });

  @override
  State<WordCollectionCreator> createState() => _WordCollectionCreatorState();
}

class _WordCollectionCreatorState extends State<WordCollectionCreator> {
  String name = '';
  int numberOfWords = 1;
  int maxNumberOfWords = 0;

  @override
  void initState() {
    super.initState();
    maxNumberOfWords = widget.entries.length;
  }

  @override
  Widget build(BuildContext context) {
    return maxNumberOfWords == 0
        ? AlertDialog(
            title: const Text('No words found'),
            content: const Text('Please import dictionary data first.'),
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
            title: const Text('Create a new collection'),
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
                const Text('Number of words:', style: TextStyle(fontSize: 16)),
                SliderWithValue(
                  min: 1,
                  max: maxNumberOfWords,
                  onChanged: (int value) {
                    setState(() {
                      numberOfWords = value;
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
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  widget.onCreate(name, numberOfWords);
                },
                child: const Text('Create'),
              ),
            ],
          );
  }
}
