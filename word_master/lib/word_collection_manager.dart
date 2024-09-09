import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:realm/realm.dart';
import 'package:word_master/database.dart';
import 'package:word_master/select_all_notifier.dart';
import 'package:word_master/word_collection.dart';
import 'package:word_master/word_collection_creator.dart';
import 'package:word_master/word_collection_data.dart';
import 'package:word_master/word_collection_entry.dart';
import 'package:word_master/word_collection_entry_creator.dart';
import 'package:word_master/word_collection_migration_dialog.dart';
import 'package:word_master/word_collection_status.dart';
import 'package:word_master/word_collection_tabs.dart';
import 'package:word_master/word_collections_list.dart';

import 'data_migration_widget.dart';
import 'dictionary_data_manager.dart';
import 'main.dart';

class WordCollectionManager extends StatefulWidget {
  final Realm db;
  final Realm? externalStorageDb;
  final String title;
  final Function(BuildContext, WordCollection) onTapWordCollection;
  final WordCollectionCreator wordCollectionCreator;

  const WordCollectionManager({
    super.key,
    required this.db,
    required this.title,
    required this.onTapWordCollection,
    required this.wordCollectionCreator,
    required this.externalStorageDb,
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
    var allCollections = widget.db
        .all<WordCollection>()
        .query("status != \"${WordCollectionStatus.markedForDeletion}\"");

    var extCollections = widget.externalStorageDb?.all<WordCollection>();
    var completeCollections = allCollections.where((e) =>
        WordCollectionStatus.getStatus(e) == WordCollectionStatus.created);
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
                      if (selectedCollections.length <
                          completeCollections.length)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(15, 3, 10, 0),
                          child: TextButton(
                            onPressed: () {
                              selectAllNotifier.triggerSelectAll();
                              setState(() {
                                selectedCollections.clear();
                                selectedCollections.addAll(completeCollections);
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
                            builder: (context) => DictionaryDataManager(
                              db: widget.db,
                              externalStorageDb: widget.externalStorageDb,
                            ),
                          ),
                        );
                      } else if (value == 'cancel_all_pending') {
                        var pendingInternal = getPending(widget.db);
                        for (WordCollection wordCollection in pendingInternal) {
                          widget.db.write(() => wordCollection.status =
                              WordCollectionStatus.markedForDeletion);
                        }
                      } else if (value == 'copy_to_external_storage') {
                        try {
                          widget.db.write(
                            () {
                              for (var collection in selectedCollections) {
                                collection.status = WordCollectionStatus
                                    .pendingCopyToExternalStorage;
                              }
                            },
                          );
                        } catch (e) {
                          showDialog(
                            context: context,
                            builder: (context) {
                              return AlertDialog(
                                title: const Text('Error'),
                                content: Text(
                                    "❌ Could not copy to external storage: $e"),
                                actions: <Widget>[
                                  TextButton(
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                    },
                                    child: const Text('OK'),
                                  ),
                                ],
                              );
                            },
                          );
                        } finally {
                          _exitMultiSelectMode();
                        }
                      } else if (value ==
                          'create_entry_in_selected_collections') {
                        // ignore: use_build_context_synchronously
                        await showDialog(
                          barrierDismissible: false,
                          context: context,
                          builder: (context) {
                            return WordCollectionEntryCreator(
                              db: widget.db,
                              wordCollections: selectedCollections,
                              onComplete: _exitMultiSelectMode,
                              externalStorageDb: widget.externalStorageDb,
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
                              const PopupMenuItem(
                                value: 'cancel_all_pending',
                                child: Text('Cancel All Pending'),
                              ),
                            ]
                          : [
                              const PopupMenuItem(
                                value: 'create_entry_in_selected_collections',
                                child: Text('Create Entry'),
                              ),
                              if (selectedCollections.length == 1 &&
                                  selectedCollections[0].isOnExternalStorage !=
                                      true &&
                                  widget.externalStorageDb != null)
                                const PopupMenuItem(
                                  value: 'copy_to_external_storage',
                                  child: Text('Copy to External Storage'),
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
              externalStorageWordCollections: extCollections,
              onTap: widget.onTapWordCollection,
              onDismissed: (WordCollection wordCollection) {
                var status = WordCollectionStatus.getStatus(wordCollection);
                if (status == WordCollectionStatus.inProgress) {
                  return;
                }

                var id = wordCollection.id;

                Realm db = Database.selectDb(
                  wordCollection,
                  widget.db,
                  widget.externalStorageDb,
                );

                db.write(() {
                  db.delete(wordCollection);
                });

                var entries = db
                    .all<WordCollectionEntry>()
                    .query("wordCollectionId == '$id'");
                db.write(() {
                  for (var entry in entries) {
                    db.delete(entry);
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
                  },
                  wordCollectionCreator: widget.wordCollectionCreator,
                );
              }),
            ),
    );
  }

  List<WordCollection> getPending(Realm db) {
    return db
        .all<WordCollection>()
        .query("status == \"${WordCollectionStatus.pending}\"")
        .toList();
  }

  void _exitMultiSelectMode() {
    setState(() {
      selectedCollections.clear();
      inMultiSelectMode.value = false;
    });
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
          externalStorageDb: widget.externalStorageDb,
        ),
      ),
    );
  }
}
