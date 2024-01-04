import 'package:flutter/material.dart';
import 'package:realm/realm.dart';
import 'package:word_master/dictionary.dart';
import 'package:word_master/random_word_fetcher.dart';
import 'package:word_master/word_collection_creator.dart';
import 'package:word_master/word_collection_entry.dart';
import 'package:word_master/word_collection_manager.dart';
import 'package:word_master/word_collection.dart';
import 'package:word_master/word_collection_tabs.dart';

import 'database.dart';
import 'dictionary_entry.dart';
import 'imported_dictionary.dart';
import 'imported_dictionary_source.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  final Realm db = Database.getDbConnection();
  String migrationError = '';

  @override
  void initState() {
    super.initState();
    initDictionaries();
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

        db.all<WordCollectionEntry>().forEach((wordCollectionEntry) {
          wordCollectionEntry.dictionaryId = dictionaryId;
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (migrationError.isNotEmpty) {
      return _migrationError();
    }
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: WordCollectionManager(
        db: db,
        title: 'Word Master',
        onTapWordCollection:
            (BuildContext context, WordCollection wordCollection) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => WordCollectionTabs(
                db: db,
                initialWordCollections: [wordCollection],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _migrationError() {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Colors.grey.shade200,
        appBar: AppBar(
          title: const Text('Word Master'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text("Migration Error:", style: TextStyle(fontSize: 20)),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Text(migrationError),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    migrationError = '';
                  });
                },
                child: const Text('Continue'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CreateWordTableButton extends StatelessWidget {
  final Realm db;
  final Function(WordCollection wordCollection) onNewWordCollection;

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
              dictionaries: db.all<Dictionary>().query("size > 0"),
              onCreate: createWordCollection,
              db: db,
            );
          },
        );
      },
      child: const Icon(Icons.add),
    );
  }

  void createWordCollection(
    String name,
    Map<String, int> numEntriesPerDictionaryId,
  ) {
    var wordCollection = WordCollection(
      Uuid.v4().toString(),
      name,
      DateTime.now(),
      numEntriesPerDictionaryId.values.reduce((a, b) => a + b),
    );
    for (var dictionaryId in numEntriesPerDictionaryId.keys) {
      var numEntries = numEntriesPerDictionaryId[dictionaryId]!;
      var words = RandomWordFetcher.getRandomWords(
        db,
        dictionaryId,
        numEntries,
      );
      int id = 1;
      db.write(() {
        for (var word in words) {
          db.add(WordCollectionEntry(
            id++,
            wordCollection.id,
            dictionaryId,
            word,
            false,
          ));
        }
      });
    }
    db.write(() {
      db.add(wordCollection);
    });
    onNewWordCollection(wordCollection);
  }
}
