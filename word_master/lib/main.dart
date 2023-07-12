import 'dart:math';

import 'package:flutter/material.dart';
import 'package:realm/realm.dart';
import 'package:word_master/dictionary_data_manager.dart';
import 'package:word_master/word_collection_creator.dart';
import 'package:word_master/word_collection_data.dart';
import 'package:word_master/word_collections_list.dart';
import 'package:word_master/word_collection.dart';

import 'dictionary_entry.dart';

void main() {
  runApp(MainApp());
}

class MainApp extends StatelessWidget {
  final Realm db = Realm(Configuration.local([
    DictionaryEntry.schema,
    WordCollectionData.schema,
  ]));

  MainApp({super.key});

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
                      child: Text('Dictionary Data'),
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
            _openWordCollection(context, wordCollection);
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
                  _openWordCollection(context, wordCollectionData);
                });
          }),
        ),
      ),
    );
  }

  void _openWordCollection(
    BuildContext context,
    WordCollectionData wordCollectionData,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => WordCollection(
          data: wordCollectionData,
          db: db,
        ),
      ),
    );
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
              entries: db.all<DictionaryEntry>(),
              onCreate: (String name, int wordCount) {
                var wordCollectionData = WordCollectionData(
                  name,
                  DateTime.now(),
                  words: getRandomWords(wordCount),
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

  List<String> getRandomWords(int count) {
    var all = db.all<DictionaryEntry>();
    var random = Random();
    var words = <String>[];
    for (int i = 0; i < count; i++) {
      words.add(all[random.nextInt(all.length)].wordOrPhrase);
    }
    return words;
  }
}
