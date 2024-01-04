import 'package:flutter/material.dart';
import 'package:realm/realm.dart';
import 'package:word_master/word_collection.dart';
import 'package:word_master/word_collection_data.dart';
import 'package:word_master/word_collection_entry.dart';

import 'dictionary.dart';
import 'dictionary_entry.dart';
import 'imported_dictionary.dart';
import 'imported_dictionary_source.dart';

class DataMigrationWidget extends StatefulWidget {
  final Realm db;
  final Function() onDone;
  final Function(String) onError;
  static const stateInitial = 'initial';
  static const stateMigratingDictionaries = 'migratingDictionaries';
  static const stateMigratingCollections = 'migratingCollections';
  static const stateReportingResults = 'reportingResults';
  static const stateComplete = 'complete';

  const DataMigrationWidget({
    super.key,
    required this.onDone,
    required this.db,
    required this.onError,
  });

  @override
  State<DataMigrationWidget> createState() => _DataMigrationWidgetState();
}

class _DataMigrationWidgetState extends State<DataMigrationWidget> {
  String state = DataMigrationWidget.stateInitial;
  RealmResults<Dictionary>? dictionaries;
  String message = '';
  bool wasMigrationNeeded = false;

  @override
  Widget build(BuildContext context) {
    _handleState();
    return Center(
      child: _buildBody(),
    );
  }

  Widget _buildBody() {
    switch (state) {
      case DataMigrationWidget.stateInitial:
        return _buildInitial();

      case DataMigrationWidget.stateMigratingDictionaries:
      case DataMigrationWidget.stateMigratingCollections:
        return _buildMigrationProgress();
      case DataMigrationWidget.stateReportingResults:
        return _buildResults();
      default:
        return _buildDefault();
    }
  }

  _handleState() async {
    try {
      switch (state) {
        case DataMigrationWidget.stateInitial:
          _handleStateInitial();
          break;

        case DataMigrationWidget.stateMigratingDictionaries:
          _handleStateMigratingDictionaries();
          break;

        case DataMigrationWidget.stateMigratingCollections:
          _handleMigratingCollectionsState();
          break;

        case DataMigrationWidget.stateReportingResults:
          _handleReportingResultsState();
          break;

        case DataMigrationWidget.stateComplete:
          _handleCompleteState();
          break;
      }
    } catch (e) {
      widget.onError(e.toString());
    }
  }

  Widget _buildInitial() {
    return Center(
        child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: const [
        Text(
          "Checking if data migration is needed...",
          style: TextStyle(fontSize: 20),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 20),
        CircularProgressIndicator(),
      ],
    ));
  }

  Widget _buildMigrationProgress() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          message,
          style: const TextStyle(fontSize: 20),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20),
        const SizedBox(width: 300, child: LinearProgressIndicator()),
      ],
    );
  }

  Widget _buildDefault() {
    return const CircularProgressIndicator();
  }

  void _handleStateInitial() async {
    await Future.delayed(const Duration(seconds: 3));
    setState(() {
      state = DataMigrationWidget.stateMigratingDictionaries;
      message = "Migrating dictionary entries";
    });
  }

  void _handleStateMigratingDictionaries() async {
    dictionaries ??= widget.db.all<Dictionary>();
    if (dictionaries!.isEmpty) {
      wasMigrationNeeded = true;
      var dictionaryId = Uuid.v4().toString();
      var mwDictionary = Dictionary(dictionaryId, 'Merriam Webster');
      var importedDictionary = ImportedDictionary(
        dictionaryId,
        ImportedDictionarySource.merriamWebster,
      );
      widget.db.write(() {
        widget.db.add(mwDictionary);
        widget.db.add(importedDictionary);
      });

      // Consider any pre-existing dictionary entry as being part of MW
      // This is for backward compatibility
      var size = 0;
      var entries = widget.db.all<DictionaryEntry>();
      var sinceLastDelay = 0;
      for (int i = 0; i < entries.length; ++i) {
        setState(() {
          message =
              "Migrating ${i + 1} of ${entries.length} dictionary entries";
        });
        widget.db.write(() => entries[i].dictionaryId = dictionaryId);
        ++size;
        ++sinceLastDelay;
        if (sinceLastDelay >= 100) {
          sinceLastDelay = 0;
          await Future.delayed(const Duration(microseconds: 1));
        }
      }
      widget.db.write(() => mwDictionary.size = size);

      var collectionEntries = widget.db.all<WordCollectionEntry>();
      sinceLastDelay = 0;
      for (int i = 0; i < collectionEntries.length; ++i) {
        setState(() {
          message =
              "Migrating ${i + 1} of ${collectionEntries.length} collection entries' dictionary data";
        });
        widget.db.write(() => collectionEntries[i].dictionaryId = dictionaryId);
        ++sinceLastDelay;
        if (sinceLastDelay >= 100) {
          sinceLastDelay = 0;
          await Future.delayed(const Duration(microseconds: 1));
        }
      }
    }
    await Future.delayed(const Duration(seconds: 1));
    setState(() {
      state = DataMigrationWidget.stateMigratingCollections;
      message = "Migrating word collection entries...";
    });
  }

  void _handleMigratingCollectionsState() async {
    var oldWordCollections = widget.db.all<WordCollectionData>();
    var sinceLastDelay = 0;
    for (int i = 0; i < oldWordCollections.length; ++i) {
      wasMigrationNeeded = true;
      setState(() {
        message =
            "Migrating ${i + 1} of ${oldWordCollections.length} word collections";
      });

      var oldWordCollection = oldWordCollections[i];
      var newWordCollection = WordCollection(
        Uuid.v4().toString(),
        oldWordCollection.name,
        DateTime.now(),
        oldWordCollection.words.length,
      );
      widget.db.write(() {
        try {
          widget.db.add(newWordCollection);
        } catch (e) {
          widget.onError(e.toString());
        }
      });
      await _migrateCollectionEntries(
        i,
        oldWordCollections.length,
        oldWordCollection,
        newWordCollection,
      );
      widget.db.write(() {
        try {
          widget.db.delete(oldWordCollection);
        } catch (e) {
          widget.onError(e.toString());
        }
      });

      ++sinceLastDelay;
      if (sinceLastDelay >= 100) {
        sinceLastDelay = 0;
        Future.delayed(const Duration(microseconds: 1));
      }
    }
    await Future.delayed(const Duration(seconds: 1));
    setState(() {
      state = DataMigrationWidget.stateReportingResults;
      message = "Migration complete";
    });
  }

  _migrateCollectionEntries(
    int collectionIndex,
    int totalCollectionCount,
    WordCollectionData oldCollection,
    WordCollection newCollection,
  ) async {
    var sinceLastDelay = 0;
    var words = oldCollection.words;
    for (var i = 0; i < words.length; ++i) {
      setState(() {
        message =
            "Migrating $collectionIndex of $totalCollectionCount word collections\n ${i + 1} of ${words.length} words";
      });

      widget.db.write(() {
        try {
          widget.db.add(WordCollectionEntry(
            i + 1,
            newCollection.id,
            oldCollection.dictionaryId,
            words[i],
            oldCollection.favorites.contains(words[i]),
          ));
        } catch (e) {
          widget.onError(e.toString());
        }
      });
      ++sinceLastDelay;
      if (sinceLastDelay >= 100) {
        sinceLastDelay = 0;
        Future.delayed(const Duration(microseconds: 1));
      }
    }
  }

  void _handleReportingResultsState() async {
    await Future.delayed(const Duration(seconds: 5));
    setState(() {
      state = DataMigrationWidget.stateComplete;
    });
  }

  void _handleCompleteState() {
    widget.onDone();
  }

  Widget _buildResults() {
    return Text(
      wasMigrationNeeded
          ? "Data migration was successful"
          : "Data migration was not needed",
      style: const TextStyle(fontSize: 20),
    );
  }
}
