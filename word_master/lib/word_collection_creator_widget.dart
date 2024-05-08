import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:realm/realm.dart';
import 'package:word_master/random_words_selector.dart';

import 'dictionary.dart';

class WordCollectionCreatorWidget extends StatefulWidget {
  final Function(String, Map<String, int>, int, BuildContext) onCreate;
  final RealmResults<Dictionary> dictionaries;
  final Realm db;

  const WordCollectionCreatorWidget({
    super.key,
    required this.onCreate,
    required this.dictionaries,
    required this.db,
  });

  @override
  State<WordCollectionCreatorWidget> createState() =>
      _WordCollectionCreatorWidgetState();
}

class _WordCollectionCreatorWidgetState
    extends State<WordCollectionCreatorWidget> {
  String name = '';
  Map<String, int> numEntriesPerDictionaryId = {};
  final TextEditingController numCollectionsController =
      TextEditingController();
  final FocusNode numCollectionsFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    numCollectionsController.text = '1';
    numCollectionsFocusNode.addListener(() {
      if (!numCollectionsFocusNode.hasFocus) {
        if (numCollectionsController.text.isEmpty) {
          numCollectionsController.text = '1';
        }
      }
    });
  }

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
                TextField(
                  controller: numCollectionsController,
                  focusNode: numCollectionsFocusNode,
                  keyboardType: TextInputType.number,
                  inputFormatters: <TextInputFormatter>[
                    FilteringTextInputFormatter.digitsOnly,
                    LeadingZeroTextInputFormatter(),
                  ],
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Number of collections',
                  ),
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
                        widget.onCreate(
                          name,
                          numEntriesPerDictionaryId,
                          int.parse(numCollectionsController.text),
                          context,
                        );
                      }
                    : null,
                child: const Text('Create'),
              ),
            ],
          );
  }
}

class LeadingZeroTextInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.startsWith('0')) {
      String newText = newValue.text.replaceFirst(RegExp('^0+'), '');
      return TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(
            offset: min(newValue.selection.start, newText.length)),
      );
    }
    return newValue;
  }
}
