import 'dart:math';

import 'package:flutter/material.dart';
import 'package:realm/realm.dart';
import 'package:word_master/dictionary.dart';
import 'package:word_master/dictionary_data_manager.dart';
import 'package:word_master/imported_dictionary.dart';
import 'package:word_master/imported_dictionary_source.dart';
import 'package:word_master/word_collection_creator.dart';
import 'package:word_master/word_collection_data.dart';
import 'package:word_master/word_collections_list.dart';
import 'package:word_master/word_collection.dart';

import 'dictionary_entry.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  final Realm db = Realm(Configuration.local(
    [
      DictionaryEntry.schema,
      WordCollectionData.schema,
      Dictionary.schema,
      ImportedDictionary.schema
    ],
    schemaVersion: 5,
  ));

  @override
  void initState() {
    super.initState();
    initDictionaries();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Colors.grey.shade200,
        appBar: AppBar(
          title: const Text('Word Master'),
          actions: <Widget>[
            Builder(
              builder: (context) => PopupMenuButton(
                onSelected: (value) {
                  if (value == 'dictionary_data') {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => DictionaryDataManager(db: db),
                      ),
                    );
                  }
                },
                itemBuilder: (BuildContext context) {
                  return [
                    const PopupMenuItem(
                      value: 'dictionary_data',
                      child: Text('Dictionaries'),
                    ),
                  ];
                },
              ),
            ),
          ],
        ),
        body: WordCollectionsList(
          wordCollections: db.all<WordCollectionData>(),
          onTap: (context, wordCollection) {
            _openWordCollection(context, wordCollection, false);
          },
          onDismissed: (WordCollectionData wordCollection) {
            db.write(() => db.delete(wordCollection));
          },
        ),
        floatingActionButton: Padding(
          padding: const EdgeInsets.fromLTRB(0, 0, 30, 30),
          child: Builder(builder: (context) {
            return CreateWordTableButton(
                db: db,
                onNewWordCollection: (wordCollectionData) {
                  _openWordCollection(context, wordCollectionData, false);
                });
          }),
        ),
      ),
    );
  }

  void _openWordCollection(
    BuildContext context,
    WordCollectionData wordCollectionData,
    bool onlyFavorites,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => WordCollection(
          db: db,
          name: wordCollectionData.name,
          words: onlyFavorites
              ? wordCollectionData.favorites.toList()
              : wordCollectionData.words,
          favorites: wordCollectionData.favorites,
          onViewFavorites: () {
            Navigator.pop(context);
            _openWordCollection(context, wordCollectionData, true);
          },
          onViewAll: () {
            Navigator.pop(context);
            _openWordCollection(context, wordCollectionData, false);
          },
          dictionaryId: db.all<Dictionary>().first.id,
        ),
      ),
    );
  }

  void initDictionaries() {
    var dictionaries = db.all<Dictionary>();
    if (dictionaries.isEmpty) {
      var dictionaryId = Uuid.v4().toString();
      db.write(() {
        var mwDictionary = Dictionary(dictionaryId, 'Merriam Webster');
        var importedDictionary = ImportedDictionary(
          dictionaryId,
          ImportedDictionarySource.merriamWebster,
        );
        db.add(mwDictionary);
        db.add(importedDictionary);

        // Consider any pre-existing dictionary entry as being part of MW
        // This is for backward compatibility
        var size = 0;
        db.all<DictionaryEntry>().forEach((entry) {
          entry.dictionaryId = dictionaryId;
          ++size;
        });
        mwDictionary.size = size;
      });
    }
  }
}

class CreateWordTableButton extends StatelessWidget {
  final Realm db;
  final Function(WordCollectionData wordCollectionData) onNewWordCollection;

  const CreateWordTableButton({
    super.key,
    required this.db,
    required this.onNewWordCollection,
  });

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: () {
        // show dialog for creating a new word collection
        showDialog(
          context: context,
          builder: (context) {
            return WordCollectionCreator(
              dictionaries: db.all<Dictionary>(),
              onCreate:
                  (String name, List<Dictionary> dictionaries, int wordCount) {
                var wordCollectionData = WordCollectionData(
                  name,
                  DateTime.now(),
                  words: getRandomWords(dictionaries, wordCount),
                );
                db.write(() => db.add(wordCollectionData));
                onNewWordCollection(wordCollectionData);
              },
            );
          },
        );
      },
      child: const Icon(Icons.add),
    );
  }

  List<String> getRandomWords(List<Dictionary> dictionaries, int count) {
    List<String> all = [];
    for (var dictionary in dictionaries) {
      var entries =
          db.all<DictionaryEntry>().query("dictionaryId = '${dictionary.id}'");
      for (var entry in entries) {
        all.add(entry.wordOrPhrase);
      }
    }
    var random = Random();
    var words = <String>[];
    for (int i = 0; i < count; i++) {
      words.add(all[random.nextInt(all.length)]);
    }
    return words;
  }
}
