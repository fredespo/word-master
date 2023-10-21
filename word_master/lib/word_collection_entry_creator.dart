import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:realm/realm.dart';
import 'package:word_master/imported_dictionary.dart';
import 'package:word_master/word_collection.dart';
import 'package:word_master/word_collection_entry.dart';

import 'dictionary.dart';
import 'dictionary_definition_creator.dart';
import 'dictionary_entry.dart';

class WordCollectionEntryCreator extends StatefulWidget {
  final Realm db;
  final List<WordCollection> wordCollections;
  final ValueNotifier<int>? wordCollectionSizeNotifier;
  final Function()? onComplete;

  const WordCollectionEntryCreator({
    super.key,
    required this.db,
    required this.wordCollections,
    this.wordCollectionSizeNotifier,
    this.onComplete,
  });

  @override
  State<WordCollectionEntryCreator> createState() =>
      _WordCollectionEntryCreatorState();
}

class _WordCollectionEntryCreatorState
    extends State<WordCollectionEntryCreator> {
  late List<DictionaryDropdownItem> dictionaryDropdownItems;
  String? newDictionaryName;
  String? wordOrPhrase;
  DictionaryDropdownItem? selectedDictionaryDropdownItem;
  bool wordOrPhraseExistsInDictionary = false;
  int pageNum = 1;
  Map<String, List<String>> definitions = {};

  @override
  void initState() {
    super.initState();
    dictionaryDropdownItems = widget.db
        .all<Dictionary>()
        .where((dictionary) => getImportedDictionary(dictionary.id) == null)
        .map((e) => DictionaryDropdownItem(e))
        .toList();
    dictionaryDropdownItems.add(DictionaryDropdownItem(null));
  }

  ImportedDictionary? getImportedDictionary(String dictionaryId) {
    try {
      return widget.db
          .all<ImportedDictionary>()
          .query("dictionaryId = '$dictionaryId'")
          .first;
    } catch (e) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Create a new entry', textAlign: TextAlign.center),
      content:
          SizedBox(height: pageNum == 1 ? 250 : 550, child: _buildContent()),
      actions: _buildActions(),
    );
  }

  Widget _buildContent() {
    if (pageNum == 1) {
      return _buildPageOne();
    }

    return _buildPageTwo();
  }

  Widget _buildPageOne() {
    return Column(
      children: [
        _buildDictionarySelector(),
        const SizedBox(height: 20),
        if (selectedDictionaryDropdownItem != null &&
            selectedDictionaryDropdownItem?.dictionary == null)
          Column(
            children: [
              _buildDictionaryNameField(),
              const SizedBox(height: 20),
            ],
          ),
        _buildWordTextField(),
        if (wordOrPhraseExistsInDictionary)
          const SizedBox(
            width: 200,
            child: Text(
              'That word or phrase already exists in the selected dictionary',
              style: TextStyle(fontSize: 12, color: Colors.red),
              textAlign: TextAlign.center,
            ),
          ),
      ],
    );
  }

  Widget _buildPageTwo() {
    return DictionaryDefinitionCreator(
      existingDefinitions: definitions,
      onDefinitionsChanged: (defs) {
        setState(() {
          definitions = defs;
        });
      },
    );
  }

  Widget _buildDictionaryNameField() {
    return TextFormField(
      initialValue: newDictionaryName,
      decoration: const InputDecoration(
        border: OutlineInputBorder(),
        labelText: 'New dictionary name',
      ),
      onChanged: (value) {
        setState(() {
          newDictionaryName = value;
        });
      },
    );
  }

  Widget _buildWordTextField() {
    return TextFormField(
      initialValue: wordOrPhrase,
      decoration: const InputDecoration(
        border: OutlineInputBorder(),
        labelText: 'Word or phrase',
      ),
      onChanged: (value) {
        setState(() {
          wordOrPhrase = value;
          wordOrPhraseExistsInDictionary = doesWordOrPhraseExistsInDictionary();
        });
      },
    );
  }

  Widget _buildDictionarySelector() {
    return Column(
      children: [
        const SizedBox(
          width: 200,
          child: Text(
            'Select a dictionary where the new entry will be saved',
            textAlign: TextAlign.center,
          ),
        ),
        DropdownButton<DictionaryDropdownItem>(
          value: selectedDictionaryDropdownItem,
          onChanged: (DictionaryDropdownItem? value) {
            setState(() {
              selectedDictionaryDropdownItem = value;
              wordOrPhraseExistsInDictionary =
                  doesWordOrPhraseExistsInDictionary();
            });
          },
          items: _buildDictionaryDropdownItems(),
          alignment: Alignment.center,
        ),
      ],
    );
  }

  List<DropdownMenuItem<DictionaryDropdownItem>>
      _buildDictionaryDropdownItems() {
    return dictionaryDropdownItems.map((DictionaryDropdownItem item) {
      return DropdownMenuItem<DictionaryDropdownItem>(
        value: item,
        child: Center(child: item.label),
      );
    }).toList();
  }

  Widget _buildCancelButton() {
    return TextButton(
      onPressed: () {
        Navigator.of(context).pop();
      },
      child: const Text('Cancel'),
    );
  }

  Widget _buildContinueButton() {
    return ElevatedButton(
      onPressed: isValid()
          ? () {
              setState(() {
                pageNum++;
              });
            }
          : null,
      child: const Text('Continue'),
    );
  }

  bool isValid() {
    if (pageNum == 1) {
      return wordOrPhrase != null &&
          wordOrPhrase!.isNotEmpty &&
          (selectedDictionaryDropdownItem?.dictionary != null ||
              newDictionaryName != null && newDictionaryName!.isNotEmpty) &&
          !wordOrPhraseExistsInDictionary;
    }

    return definitions.isNotEmpty &&
        definitions.values.every(
            (e) => e.isNotEmpty && e.every((e2) => e2.trim().isNotEmpty));
  }

  bool doesWordOrPhraseExistsInDictionary() {
    if (wordOrPhrase == null) {
      return false;
    }

    if (selectedDictionaryDropdownItem?.dictionary == null) {
      return false;
    }

    final dictionary = selectedDictionaryDropdownItem!.dictionary!;
    try {
      widget.db
          .all<DictionaryEntry>()
          .query("dictionaryId == '${dictionary.id}'")
          .query("wordOrPhrase == \$0", [wordOrPhrase!]).first;
      return true;
    } catch (e) {
      return false;
    }
  }

  List<Widget> _buildActions() {
    if (pageNum == 1) {
      return [
        _buildCancelButton(),
        _buildContinueButton(),
      ];
    }

    return [
      Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          _buildBackButton(),
          const Spacer(),
          _buildCancelButton(),
          const SizedBox(width: 20),
          _buildSaveButton(),
        ],
      ),
    ];
  }

  Widget _buildBackButton() {
    return TextButton(
      onPressed: () {
        setState(() {
          pageNum--;
        });
      },
      child: const Text('Back'),
    );
  }

  Widget _buildSaveButton() {
    return ElevatedButton(
      onPressed: isValid() ? _save : null,
      child: const Text('Save'),
    );
  }

  void _save() {
    var creatingNewDictionary =
        selectedDictionaryDropdownItem?.dictionary == null;
    var dictionaryId = creatingNewDictionary
        ? Uuid.v4().toString()
        : selectedDictionaryDropdownItem?.dictionary?.id;
    widget.db.write(
      () {
        // create dictionary (maybe)
        if (creatingNewDictionary) {
          var dictionary = Dictionary(dictionaryId!, newDictionaryName!);
          widget.db.add(dictionary);
        }

        // create dictionary entry
        DictionaryEntry entry = DictionaryEntry(
            dictionaryId!, wordOrPhrase!, jsonEncode(definitions));
        widget.db.add(entry);
        widget.db.find<Dictionary>(dictionaryId)!.size++;

        // add to word collections
        widget.wordCollections.forEach((wordCollection) {
          var wordCollectionEntry = WordCollectionEntry(
            wordCollection.id,
            dictionaryId,
            wordOrPhrase!,
            false,
          );
          widget.db.add(wordCollectionEntry);
          wordCollection.size++;
        });
        if (widget.wordCollectionSizeNotifier != null) {
          widget.wordCollectionSizeNotifier!.value++;
        }
      },
    );
    if (widget.onComplete != null) {
      widget.onComplete!();
    }
    Navigator.of(context).pop();
  }
}

class DictionaryDropdownItem {
  final Text label;
  final Dictionary? dictionary;

  DictionaryDropdownItem(this.dictionary)
      : label = dictionary != null
            ? Text(
                dictionary.name,
                textAlign: TextAlign.center,
              )
            : const Text(
                'Create new',
                textAlign: TextAlign.center,
                style: TextStyle(fontWeight: FontWeight.bold),
              );
}
