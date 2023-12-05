import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:realm/realm.dart';
import 'package:word_master/select_all_notifier.dart';
import 'package:word_master/word_collection.dart';
import 'package:word_master/word_collection_data.dart';
import 'package:word_master/word_collection_entry.dart';
import 'package:word_master/word_collection_entry_creator.dart';
import 'package:word_master/word_collection_migration_dialog.dart';
import 'package:word_master/word_collection_tabs.dart';
import 'package:word_master/word_collections_list.dart';

import 'data_migration_widget.dart';
import 'dictionary_data_manager.dart';
import 'main.dart';

class WordCollectionManager extends StatefulWidget {
  final Realm db;
  final String title;
  final Function(BuildContext, WordCollection) onTapWordCollection;

  const WordCollectionManager({
    super.key,
    required this.db,
    required this.title,
    required this.onTapWordCollection,
  });

  @override
  State<WordCollectionManager> createState() => _WordCollectionManagerState();
}

class _WordCollectionManagerState extends State<WordCollectionManager> {
  ValueNotifier<bool> inMultiSelectMode = ValueNotifier(false);
  List<WordCollection> selectedCollections = [];
  SelectAllNotifier selectAllNotifier = SelectAllNotifier();
  bool isMigrating = false;
  String migrationError = '';

  @override
  Widget build(BuildContext context) {
    var allCollections = widget.db.all<WordCollection>();
    return Scaffold(
      backgroundColor: Colors.grey.shade200,
      appBar: AppBar(
        title: ValueListenableBuilder(
          valueListenable: inMultiSelectMode,
          builder:
              (BuildContext context, inMultiSelectModeValue, Widget? child) {
            return inMultiSelectModeValue
                ? Row(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(0, 3, 10, 0),
                        child: IconButton(
                          onPressed: () {
                            setState(() {
                              selectedCollections.clear();
                              inMultiSelectMode.value = false;
                            });
                          },
                          icon: const Icon(Icons.clear_rounded),
                        ),
                      ),
                      Text("${selectedCollections.length} selected"),
                      if (selectedCollections.length < allCollections.length)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(15, 3, 10, 0),
                          child: TextButton(
                            onPressed: () {
                              selectAllNotifier.triggerSelectAll();
                              setState(() {
                                selectedCollections.clear();
                                selectedCollections.addAll(allCollections);
                              });
                            },
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.blue,
                              backgroundColor: Colors.white,
                            ),
                            child: const Text(
                              "Select All",
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                    ],
                  )
                : Text(widget.title);
          },
        ),
        actions: isMigrating
            ? []
            : <Widget>[
                Builder(
                  builder: (context) => PopupMenuButton(
                    onSelected: (value) async {
                      if (value == 'dictionary_data') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                DictionaryDataManager(db: widget.db),
                          ),
                        );
                      }

                      if (value == 'create_entry_in_selected_collections') {
                        await showDialog(
                          barrierDismissible: false,
                          context: context,
                          builder: (context) {
                            return WordCollectionEntryCreator(
                              db: widget.db,
                              wordCollections: selectedCollections,
                              onComplete: () => setState(() {
                                selectedCollections.clear();
                                inMultiSelectMode.value = false;
                              }),
                            );
                          },
                        );
                      }
                    },
                    itemBuilder: (BuildContext context) {
                      return selectedCollections.isEmpty
                          ? [
                              const PopupMenuItem(
                                value: 'dictionary_data',
                                child: Text('Dictionaries'),
                              ),
                            ]
                          : [
                              const PopupMenuItem(
                                value: 'create_entry_in_selected_collections',
                                child: Text('Create Entry'),
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
              db: widget.db,
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
              wordCollections: allCollections,
              onTap: widget.onTapWordCollection,
              onDismissed: (WordCollection wordCollection) {
                var entries = widget.db
                    .all<WordCollectionEntry>()
                    .query("wordCollectionId == '${wordCollection.id}'");
                widget.db.write(() {
                  widget.db.delete(wordCollection);
                  for (var entry in entries) {
                    widget.db.delete(entry);
                  }
                });
              },
              oldWordCollections: widget.db.all<WordCollectionData>(),
              onOldDismissed: (WordCollectionData oldWordCollection) {
                widget.db.write(() {
                  widget.db.delete(oldWordCollection);
                });
              },
              onOldTap:
                  (BuildContext context, WordCollectionData oldWordCollection) {
                showDialog(
                  barrierDismissible: false,
                  context: context,
                  builder: (context) => WordCollectionMigrationDialog(
                    db: widget.db,
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
              inMultiSelectMode: inMultiSelectMode,
              onSelected: (WordCollection wordCollection) {
                setState(() {
                  selectedCollections.add(wordCollection);
                });
              },
              onDeselected: (WordCollection wordCollection) {
                setState(() {
                  selectedCollections.remove(wordCollection);
                  if (selectedCollections.isEmpty) {
                    inMultiSelectMode.value = false;
                  }
                });
              },
              selectAllNotifier: selectAllNotifier,
            ),
      floatingActionButton: isMigrating
          ? null
          : Padding(
              padding: const EdgeInsets.fromLTRB(0, 0, 30, 30),
              child: Builder(builder: (context) {
                return CreateWordTableButton(
                    db: widget.db,
                    onNewWordCollection: (wordCollection) {
                      _openWordCollection(context, wordCollection);
                    });
              }),
            ),
    );
  }

  void _openWordCollection(
    BuildContext context,
    WordCollection wordCollection,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => WordCollectionTabs(
          db: widget.db,
          initialWordCollections: [wordCollection],
        ),
      ),
    );
  }
}
