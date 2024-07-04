import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:realm/realm.dart';
import 'package:word_master/imported_dictionary.dart';
import 'package:word_master/select_all_notifier.dart';
import 'package:word_master/word_collection.dart';
import 'package:word_master/word_collection_card.dart';
import 'package:word_master/word_collection_entry.dart';
import 'package:word_master/word_collection_status.dart';

import 'dictionary.dart';
import 'dictionary_definition_creator.dart';
import 'dictionary_entry.dart';

class WordCollectionEntryCreator extends StatefulWidget {
  final Realm db;
  final List<WordCollection> wordCollections;
  final ValueNotifier<int>? wordCollectionSizeNotifier;
  final Function()? onComplete;
  final bool allowWordCollectionSelection;
  final SelectAllNotifier selectAllNotifier = SelectAllNotifier();

  WordCollectionEntryCreator({
    super.key,
    required this.db,
    required this.wordCollections,
    this.wordCollectionSizeNotifier,
    this.onComplete,
    this.allowWordCollectionSelection = false,
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
  Set<String> selectedWordCollectionIds = {};

  @override
  void initState() {
    super.initState();
    dictionaryDropdownItems = widget.db
        .all<Dictionary>()
        .where((dictionary) => getImportedDictionary(dictionary.id) == null)
        .map((e) => DictionaryDropdownItem(e))
        .toList();
    dictionaryDropdownItems.add(DictionaryDropdownItem(null));
    if (widget.allowWordCollectionSelection) {
      selectedWordCollectionIds =
          widget.wordCollections.map((e) => e.id).toSet();
    }
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
      return _buildDictionarySelectionPage();
    }

    if (pageNum == 2) {
      return widget.allowWordCollectionSelection
          ? _buildWordCollectionSelectionPage()
          : _buildEntryCreationPage();
    }

    return _buildEntryCreationPage();
  }

  Widget _buildDictionarySelectionPage() {
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

  Widget _buildWordCollectionSelectionPage() {
    // select multiple word collections
    var allWordCollections = widget.db.all<WordCollection>();
    return StreamBuilder<RealmResultsChanges<RealmObject>>(
        stream: allWordCollections.changes,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const SizedBox(
              height: 300,
              child: Center(child: CircularProgressIndicator()),
            );
          }
          var completeWordCollections = allWordCollections.where((e) =>
              WordCollectionStatus.getStatus(e) ==
              WordCollectionStatus.created);
          return SizedBox(
            width: 300,
            child: Column(
              children: [
                const SizedBox(
                  width: 200,
                  child: Text(
                    'Select word collections where the new entry will be saved',
                    textAlign: TextAlign.center,
                  ),
                ),
                _buildSelectAllButton(completeWordCollections),
                Expanded(
                  child: ListView.builder(
                    itemCount: allWordCollections.length,
                    itemBuilder: (context, index) {
                      var wordCollection = allWordCollections[index];
                      return WordCollectionCard(
                        wordCollection: wordCollection,
                        isSelectedInitially: selectedWordCollectionIds
                            .contains(wordCollection.id),
                        onTap: (WordCollection collection) {},
                        isDismissible: false,
                        inMultiSelectMode: ValueNotifier<bool>(true),
                        onSelected: (WordCollection collection) {
                          setState(() {
                            selectedWordCollectionIds.add(collection.id);
                          });
                        },
                        onDeselected: (WordCollection collection) {
                          setState(() {
                            selectedWordCollectionIds.remove(collection.id);
                          });
                        },
                        selectAllNotifier: widget.selectAllNotifier,
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        });
  }

  Widget _buildEntryCreationPage() {
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

  Widget _buildSelectAllButton(Iterable<WordCollection> allWordCollections) {
    if (selectedWordCollectionIds.length == allWordCollections.length) {
      return const SizedBox(height: 58);
    }
    return Padding(
      padding: const EdgeInsets.all(15),
      child: ElevatedButton(
        onPressed: () {
          widget.selectAllNotifier.triggerSelectAll();
          setState(() {
            selectedWordCollectionIds.clear();
            for (WordCollection w in allWordCollections) {
              selectedWordCollectionIds.add(w.id);
            }
          });
        },
        child: const Text(
          "Select All",
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
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

    if (pageNum == 2 && widget.allowWordCollectionSelection) {
      return selectedWordCollectionIds.isNotEmpty;
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

    if (pageNum == 2 && widget.allowWordCollectionSelection) {
      return [
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            _buildBackButton(),
            const Spacer(),
            _buildCancelButton(),
            const SizedBox(width: 20),
            _buildContinueButton(),
          ],
        ),
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
        var collections = widget.allowWordCollectionSelection
            ? widget.db
                .all<WordCollection>()
                .where((e) => selectedWordCollectionIds.contains(e.id))
            : widget.wordCollections;
        for (var wordCollection in collections) {
          int randomId = Random().nextInt(wordCollection.size) + 1;
          var existingEntries = widget.db
              .all<WordCollectionEntry>()
              .query("wordCollectionId == '${wordCollection.id}'")
              .query("id >= \$0", [randomId]).toList();
          for (var entry in existingEntries) {
            entry.id++;
          }
          var wordCollectionEntry = WordCollectionEntry(
            randomId,
            wordCollection.id,
            dictionaryId,
            wordOrPhrase!,
            false,
          );
          widget.db.add(wordCollectionEntry);
          wordCollection.size++;
        }
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
