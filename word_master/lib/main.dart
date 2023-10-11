import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:realm/realm.dart';
import 'package:word_master/dictionary.dart';
import 'package:word_master/dictionary_data_manager.dart';
import 'package:word_master/imported_dictionary.dart';
import 'package:word_master/random_word_fetcher.dart';
import 'package:word_master/word_collection_adder.dart';
import 'package:word_master/word_collection_creator.dart';
import 'package:word_master/word_collection_data.dart';
import 'package:word_master/word_collection_entry.dart';
import 'package:word_master/word_collection_migration_dialog.dart';
import 'package:word_master/word_collections_list.dart';
import 'package:word_master/word_collection_widget.dart';
import 'package:word_master/word_collection.dart';

import 'data_migration_widget.dart';
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
      ImportedDictionary.schema,
      WordCollectionEntry.schema,
      WordCollection.schema,
    ],
    schemaVersion: 7,
  ));
  bool isMigrating = false;
  String migrationError = '';

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    if (migrationError.isNotEmpty) {
      return _migrationError();
    }
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Colors.grey.shade200,
        appBar: AppBar(
          title: const Text('Word Master'),
          actions: isMigrating
              ? []
              : <Widget>[
                  Builder(
                    builder: (context) => PopupMenuButton(
                      onSelected: (value) {
                        if (value == 'dictionary_data') {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  DictionaryDataManager(db: db),
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
        body: isMigrating
            ? DataMigrationWidget(
                onDone: () {
                  SchedulerBinding.instance.addPostFrameCallback((_) {
                    setState(() {
                      isMigrating = false;
                    });
                  });
                },
                db: db,
                onError: (String errorMessage) {
                  SchedulerBinding.instance.addPostFrameCallback((_) {
                    setState(() {
                      isMigrating = false;
                      migrationError = errorMessage;
                    });
                  });
                },
              )
            : WordCollectionsList(
                wordCollections: db.all<WordCollection>(),
                onTap: (context, wordCollection) {
                  _openWordCollection(context, wordCollection);
                },
                onDismissed: (WordCollection wordCollection) {
                  var entries = db
                      .all<WordCollectionEntry>()
                      .query("wordCollectionId == '${wordCollection.id}'");
                  db.write(() {
                    db.delete(wordCollection);
                    for (var entry in entries) {
                      db.delete(entry);
                    }
                  });
                },
                oldWordCollections: db.all<WordCollectionData>(),
                onOldDismissed: (WordCollectionData oldWordCollection) {
                  db.write(() {
                    db.delete(oldWordCollection);
                  });
                },
                onOldTap: (BuildContext context,
                    WordCollectionData oldWordCollection) {
                  showDialog(
                    barrierDismissible: false,
                    context: context,
                    builder: (context) => WordCollectionMigrationDialog(
                      db: db,
                      oldWordCollection: oldWordCollection,
                      onMigrated: (WordCollection wordCollection) {
                        Navigator.of(context).pop();
                        SchedulerBinding.instance.addPostFrameCallback((_) {
                          _openWordCollection(context, wordCollection);
                        });
                      },
                      onError: (String errorMsg) {
                        Navigator.of(context).pop();
                        SchedulerBinding.instance.addPostFrameCallback((_) {
                          showDialog(
                              barrierDismissible: false,
                              context: context,
                              builder: (context) => AlertDialog(
                                    title: const Text('Migration Error'),
                                    content: Text(errorMsg),
                                    actions: [
                                      TextButton(
                                          onPressed: () {
                                            Navigator.of(context).pop();
                                          },
                                          child: const Text('OK'))
                                    ],
                                  ));
                        });
                      },
                    ),
                  );
                },
              ),
        floatingActionButton: isMigrating
            ? null
            : Padding(
                padding: const EdgeInsets.fromLTRB(0, 0, 30, 30),
                child: Builder(builder: (context) {
                  return CreateWordTableButton(
                      db: db,
                      onNewWordCollection: (wordCollection) {
                        _openWordCollection(context, wordCollection);
                      });
                }),
              ),
      ),
    );
  }

  void _openWordCollection(
    BuildContext context,
    WordCollection wordCollection,
  ) {
    ValueNotifier<int> wordCollectionSizeNotifier = ValueNotifier(
      wordCollection.size,
    );
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => WordCollectionWidget(
          sizeNotifier: wordCollectionSizeNotifier,
          db: db,
          name: wordCollection.name,
          onAddEntries: () {
            showDialog(
              context: context,
              builder: (context) {
                return WordCollectionAdder(
                  wordCollection: wordCollection,
                  dictionaries: db.all<Dictionary>().query("size > 0"),
                  onAddEntries: (numEntriesPerDictionaryId) {
                    db.write(() {
                      wordCollection.size += numEntriesPerDictionaryId.values
                          .reduce((a, b) => a + b);
                      wordCollectionSizeNotifier.value = wordCollection.size;
                      for (var dictionaryId in numEntriesPerDictionaryId.keys) {
                        var numEntries =
                            numEntriesPerDictionaryId[dictionaryId]!;
                        var words = RandomWordFetcher.getRandomWords(
                          db,
                          dictionaryId,
                          numEntries,
                        );
                        for (var word in words) {
                          db.add(WordCollectionEntry(
                            wordCollection.id,
                            dictionaryId,
                            word,
                            false,
                          ));
                        }
                      }
                    });
                  },
                  db: db,
                );
              },
            );
          },
          entries: db
              .all<WordCollectionEntry>()
              .query("wordCollectionId == '${wordCollection.id}'"),
        ),
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
                    isMigrating = false;
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
      db.write(() {
        for (var word in words) {
          db.add(WordCollectionEntry(
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
