import 'dart:math';

import 'package:flutter/material.dart';
import 'package:realm/realm.dart';
import 'package:word_master/database.dart';
import 'package:word_master/page_jumper_activation_notifier.dart';
import 'package:word_master/page_selection_dialog.dart';
import 'package:word_master/random_word_fetcher.dart';
import 'package:word_master/word_collection.dart';
import 'package:word_master/word_collection_action_menu.dart';
import 'package:word_master/word_collection_action_menu_selecting.dart';
import 'package:word_master/word_collection_adder.dart';
import 'package:word_master/word_collection_creator.dart';
import 'package:word_master/word_collection_entry.dart';
import 'package:word_master/word_collection_entry_creator.dart';
import 'package:word_master/word_collection_entry_mover.dart';
import 'package:word_master/word_collection_manager.dart';
import 'package:word_master/word_collection_shuffle_dialog.dart';
import 'package:word_master/word_collection_shuffler.dart';
import 'package:word_master/word_collection_tabs_title.dart';
import 'package:word_master/word_collection_widget.dart';

import 'dictionary.dart';

class WordCollectionTabs extends StatefulWidget {
  final List<WordCollection> initialWordCollections;
  final Realm db;
  final Realm? externalStorageDb;

  const WordCollectionTabs({
    super.key,
    required this.initialWordCollections,
    required this.db,
    required this.externalStorageDb,
  });

  @override
  State<WordCollectionTabs> createState() => _WordCollectionTabsState();
}

class _WordCollectionTabsState extends State<WordCollectionTabs>
    with TickerProviderStateMixin {
  final List<WordCollection> wordCollections = [];
  final List<WordCollectionWidget> wordCollectionWidgets = [];
  final Map<String, ValueNotifier<bool>> viewingFavesNotifiers = {};
  final Map<String, ValueNotifier<int>> sizeNotifiers = {};
  final Map<String, PageJumperActivationNotifier>
      pageJumperActivationNotifiers = {};
  final Map<String, ValueNotifier<int>> pageNumNotifiers = {};
  final Map<String, ValueNotifier<double>> scrollOffsets = {};
  final Map<String, ValueNotifier<int>> selectedCounts = {};
  late TabController _tabController;
  ValueNotifier<int> selectedCount = ValueNotifier<int>(0);
  final Map<String, Set<int>> selectedEntryIds = {};
  late WordCollectionCreator wordCollectionCreator;

  @override
  void initState() {
    _tabController = TabController(length: 0, vsync: this);
    _tabController.addListener(_handleTabChange);
    for (var wordCollection in widget.initialWordCollections) {
      addWordCollection(wordCollection);
    }
    super.initState();
    wordCollectionCreator = WordCollectionCreator();
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    super.dispose();
  }

  void addWordCollection(WordCollection wordCollection) {
    Realm db = Database.selectDb(
      wordCollection,
      widget.db,
      widget.externalStorageDb,
    );
    var entries = db
        .all<WordCollectionEntry>()
        .query("wordCollectionId == '${wordCollection.id}'");

    if (entries.isNotEmpty && entries.first.id == 0) {
      db.write(() {
        int id = 1;
        for (var entry in entries) {
          entry.id = id++;
        }
      });
    }

    setState(() {
      viewingFavesNotifiers[wordCollection.id] = ValueNotifier<bool>(false);
      sizeNotifiers[wordCollection.id] = ValueNotifier<int>(entries.length);
      pageJumperActivationNotifiers[wordCollection.id] =
          PageJumperActivationNotifier();
      pageNumNotifiers[wordCollection.id] = ValueNotifier<int>(1);
      scrollOffsets[wordCollection.id] = ValueNotifier<double>(0);
      selectedCounts[wordCollection.id] = ValueNotifier<int>(0);
      selectedCounts[wordCollection.id]!.addListener(() {
        selectedCount.value = selectedCounts[wordCollection.id]!.value;
      });
      selectedEntryIds[wordCollection.id] = {};
      wordCollections.add(wordCollection);
      wordCollectionWidgets.add(
        WordCollectionWidget(
          db: widget.db,
          wordCollectionDb: db,
          name: wordCollection.name,
          entries: entries,
          sizeNotifier: sizeNotifiers[wordCollection.id]!,
          viewingFavesNotifier: viewingFavesNotifiers[wordCollection.id]!,
          pageJumperActivationNotifier:
              pageJumperActivationNotifiers[wordCollection.id]!,
          pageNumNotifier: pageNumNotifiers[wordCollection.id]!,
          scrollOffsetNotifier: scrollOffsets[wordCollection.id]!,
          selectedCount: selectedCounts[wordCollection.id]!,
          selected: selectedEntryIds[wordCollection.id]!,
          externalStorageDb: widget.externalStorageDb,
        ),
      );
      _tabController.dispose();
      _tabController = TabController(
        length: wordCollections.length,
        vsync: this,
        initialIndex: wordCollections.length - 1,
      );
      _tabController.addListener(_handleTabChange);
    });
  }

  void handleAddRandomEntriesAction() {
    var wordCollection = getCurrentWordCollection();
    showDialog(
      context: context,
      builder: (context) {
        return WordCollectionAdder(
          wordCollection: wordCollection,
          dictionaries: widget.db.all<Dictionary>().query("size > 0"),
          onAddEntries: addRandomEntries,
          db: widget.db,
        );
      },
    );
  }

  void addRandomEntries(Map<String, int> numEntriesPerDictionaryId) {
    var wordCollection = getCurrentWordCollection();
    var db = Database.selectDb(
      wordCollection,
      widget.db,
      widget.externalStorageDb,
    );
    var wordCollectionSizeNotifier = sizeNotifiers[wordCollection.id]!;
    db.write(() {
      wordCollectionSizeNotifier.value = wordCollection.size;
      for (var dictionaryId in numEntriesPerDictionaryId.keys) {
        var numEntries = numEntriesPerDictionaryId[dictionaryId]!;
        var words = RandomWordFetcher.getRandomWords(
          widget.db,
          dictionaryId,
          numEntries,
        );
        for (var word in words) {
          db.add(WordCollectionEntry(
            wordCollection.size++,
            wordCollection.id,
            dictionaryId,
            word,
            false,
          ));
        }
      }
    });
  }

  void handleCreateEntryAction() {
    var wordCollection = getCurrentWordCollection();
    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (context) {
        return WordCollectionEntryCreator(
          db: widget.db,
          wordCollections: [wordCollection],
          wordCollectionSizeNotifier: sizeNotifiers[wordCollection.id]!,
          allowWordCollectionSelection: true,
          externalStorageDb: widget.externalStorageDb,
        );
      },
    );
  }

  void handleJumpToPageAction() {
    pageJumperActivationNotifiers[getCurrentWordCollection().id]!
        .turnOnPageJumper();
  }

  WordCollection getCurrentWordCollection() {
    return wordCollections[_tabController.index];
  }

  void handleViewOnlyFavoritesAction() {
    var wordCollection = getCurrentWordCollection();
    var viewingFavesNotifier = viewingFavesNotifiers[wordCollection.id]!;
    viewingFavesNotifier.value = true;
  }

  void handleViewAllAction() {
    var wordCollection = getCurrentWordCollection();
    var viewingFavesNotifier = viewingFavesNotifiers[wordCollection.id]!;
    viewingFavesNotifier.value = false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(80),
        child: _buildAppBar(),
      ),
      body: TabBarView(
        key: UniqueKey(),
        controller: _tabController,
        children: wordCollectionWidgets,
      ),
    );
  }

  Widget _buildAppBar() {
    return ValueListenableBuilder(
        valueListenable: selectedCount,
        builder: (BuildContext context, int value, Widget? child) {
          return AppBar(
            leading: IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => selectedCount.value > 0
                  ? deselectAll()
                  : Navigator.of(context).pop(),
            ),
            title: WordCollectionTabsTitle(
              selectedCount: selectedCount,
              onViewAll: _viewAll,
              onSelectAllOnCurrentPage: _onSelectAllOnCurrentPage,
            ),
            bottom: TabBar(
              isScrollable: true,
              controller: _tabController,
              tabs: wordCollectionWidgets
                  .map((e) => Text(
                        e.name.isNotEmpty ? e.name : 'Untitled',
                        style: const TextStyle(fontSize: 18),
                      ))
                  .toList(),
            ),
            actions: value == 0
                ? _buildNormalActionMenu()
                : _buildSelectedActionMenu(value),
          );
        });
  }

  List<Widget> _buildNormalActionMenu() {
    return [
      WordCollectionActionMenu(
        onAddEntries: handleAddRandomEntriesAction,
        onCreateEntry: handleCreateEntryAction,
        onJumpToPage: handleJumpToPageAction,
        onViewAll: handleViewAllAction,
        onViewFaves: handleViewOnlyFavoritesAction,
        onCloseCurrentTab: handleCloseCurrentTabAction,
        onShuffle: handleShuffleAction,
      )
    ];
  }

  List<Widget> _buildSelectedActionMenu(int numSelected) {
    return [
      WordCollectionActionMenuSelecting(
        selectCurrPage: _onSelectAllOnCurrentPage,
        selectPages: _selectPages,
        onShuffle: shuffleSelected,
        onDisperse: disperseSelected,
        deselectAll: deselectAll,
      )
    ];
  }

  Future disperseSelected() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          child: Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: const [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Dispersing selected entries...'),
              ],
            ),
          ),
        );
      },
    );
    await Future.delayed(const Duration(seconds: 1));

    var wordCollection = getCurrentWordCollection();
    var mover = WordCollectionEntryMover(
      Database.selectDb(wordCollection, widget.db, widget.externalStorageDb),
      10000,
      const Duration(microseconds: 1),
    );
    mover.init(wordCollection);

    await Future.delayed(const Duration(seconds: 1));

    var selectedEntryIds = this.selectedEntryIds[wordCollection.id]!;
    await mover.moveToRandPositions(selectedEntryIds.toList());
    refreshWordCollection(wordCollection);
    Navigator.pop(context);
  }

  Future disperse(
    WordCollectionEntry entry,
    WordCollection wordCollection,
    List<WordCollectionEntry> existingEntries,
  ) async {
    var e = existingEntries.where((e) => e.id > entry.id).toList()
      ..sort((a, b) => a.id.compareTo(b.id));

    int batchSize = 10;
    Realm db = Database.selectDb(
      wordCollection,
      widget.db,
      widget.externalStorageDb,
    );
    for (int i = 0; i < e.length; i += batchSize) {
      db.write(() {
        for (int j = i; j < e.length; j++) {
          e[j].id--;
        }
      });
      await Future.delayed(const Duration(milliseconds: 10));
    }

    existingEntries.remove(entry);

    await Future.delayed(const Duration(milliseconds: 100));

    int randomId = Random().nextInt(wordCollection.size - 1) + 1;
    e = existingEntries.where((e) => e.id >= randomId).toList()
      ..sort((a, b) => a.id.compareTo(b.id));

    for (int i = 0; i < e.length; i += batchSize) {
      db.write(() {
        for (int j = i; j < e.length; j++) {
          e[j].id++;
        }
      });
      await Future.delayed(Duration(milliseconds: 10));
    }

    db.write(() {
      entry.id = randomId;
      entry.wordCollectionId = wordCollection.id;
    });
  }

  void shuffleSelected() {
    var entries = getSelectedEntries();
    var entryData = [];
    var shuffled = [];
    for (var entry in entries) {
      entryData.add([entry.wordOrPhrase, entry.isFavorite]);
      shuffled.add([entry.wordOrPhrase, entry.isFavorite]);
    }
    shuffled.shuffle();

    // ensure everything is in a different order
    for (var i = 0; i < entries.length; i++) {
      if (entryData[i][0] == shuffled[i][0]) {
        var swapIndex = (i + 1) % shuffled.length;
        var temp = shuffled[i];
        shuffled[i] = shuffled[swapIndex];
        shuffled[swapIndex] = temp;
      }
    }

    var i = 0;
    Realm db = Database.selectDb(
      getCurrentWordCollection(),
      widget.db,
      widget.externalStorageDb,
    );
    db.write(() {
      for (var entry in entries) {
        entry.wordOrPhrase = shuffled[i][0];
        entry.isFavorite = shuffled[i][1];
        i++;
      }
    });
  }

  List<WordCollectionEntry> getSelectedEntries() {
    var wordCollection = getCurrentWordCollection();
    var selectedEntryIds = this.selectedEntryIds[wordCollection.id]!;
    List<WordCollectionEntry> entries = [];
    for (var entry
        in wordCollectionWidgets[_tabController.index].entries.toList()) {
      if (selectedEntryIds.contains(entry.id)) {
        entries.add(entry);
      }
    }
    return entries;
  }

  void deselectAll() {
    selectedEntryIds[getCurrentWordCollection().id]!.clear();
    selectedCounts[getCurrentWordCollection().id]!.value = 0;
    selectedCount.value = 0;
  }

  handleCloseCurrentTabAction() {
    var wordCollection = getCurrentWordCollection();
    var wordCollectionId = wordCollection.id;
    var wordCollectionIndex = wordCollections.indexOf(wordCollection);
    var wordCollectionSizeNotifier = sizeNotifiers[wordCollectionId]!;
    var viewingFavesNotifier = viewingFavesNotifiers[wordCollectionId]!;
    var pageJumperActivationNotifier =
        pageJumperActivationNotifiers[wordCollectionId]!;
    var pageNumNotifier = pageNumNotifiers[wordCollectionId]!;
    var scrollOffsetNotifier = scrollOffsets[wordCollectionId]!;
    var selectedCount = selectedCounts[wordCollectionId]!;
    setState(() {
      wordCollections.removeAt(wordCollectionIndex);
      wordCollectionWidgets.removeAt(wordCollectionIndex);
      viewingFavesNotifiers.remove(wordCollectionId);
      sizeNotifiers.remove(wordCollectionId);
      pageJumperActivationNotifiers.remove(wordCollectionId);
      pageNumNotifiers.remove(wordCollectionId);
      scrollOffsets.remove(wordCollectionId);
      selectedCounts.remove(wordCollectionId);
      wordCollectionSizeNotifier.dispose();
      viewingFavesNotifier.dispose();
      pageJumperActivationNotifier.dispose();
      pageNumNotifier.dispose();
      scrollOffsetNotifier.dispose();
      _tabController.dispose();
      _tabController = TabController(
        length: wordCollections.length,
        vsync: this,
        initialIndex: wordCollectionIndex == 0 ? 0 : wordCollectionIndex - 1,
      );
      selectedCount.dispose();
      if (wordCollections.isEmpty) {
        Navigator.of(context).pop();
      }
    });
  }

  void _viewAll() {
    // push a new route to show all word collections
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) {
          return WordCollectionManager(
            db: widget.db,
            externalStorageDb: widget.externalStorageDb,
            title: 'All Word Collections',
            onTapWordCollection: (context, wordCollection) {
              Navigator.pop(context);
              // only add if not already added
              if (!wordCollections.any((c) => c.id == wordCollection.id)) {
                addWordCollection(wordCollection);
              }

              // otherwise show the tab
              _tabController.animateTo(
                wordCollections.indexOf(wordCollection),
              );
            },
            wordCollectionCreator: wordCollectionCreator,
          );
        },
      ),
    );
  }

  void handleShuffleAction() async {
    ValueNotifier<double> progress = new ValueNotifier<double>(0);
    var wordCollection = getCurrentWordCollection();
    var db = Database.selectDb(
      wordCollection,
      widget.db,
      widget.externalStorageDb,
    );
    showDialog(
        context: context,
        builder: (context) =>
            ProgressDialog(progress: progress, message: 'Shuffling'));
    await WordCollectionShuffler.shuffle(wordCollection, progress, db);

    refreshWordCollection(wordCollection);
  }

  void refreshWordCollection(WordCollection wordCollection) {
    sizeNotifiers[wordCollection.id]!.value = wordCollection.size - 1;
    sizeNotifiers[wordCollection.id]!.value = wordCollection.size;
  }

  void _handleTabChange() {
    deselectAll();
  }

  _onSelectAllOnCurrentPage() {
    var wordCollection = getCurrentWordCollection();
    var db = Database.selectDb(
      wordCollection,
      widget.db,
      widget.externalStorageDb,
    );
    var currPage = pageNumNotifiers[wordCollection.id]!.value;
    selectPage(wordCollection.id, currPage, db);
  }

  void selectPage(String wordCollectionId, int pageNum, Realm db) {
    var entries = db
        .all<WordCollectionEntry>()
        .query("wordCollectionId == '$wordCollectionId'")
        .query("id >= \$0", [
      (pageNum - 1) * WordCollectionWidget.numWordsPerPage + 1
    ]).query("id <= \$0",
            [pageNum * WordCollectionWidget.numWordsPerPage]).toList();
    for (var entry in entries) {
      selectedEntryIds[wordCollectionId]!.add(entry.id);
    }
    selectedCounts[wordCollectionId]!.value =
        selectedEntryIds[wordCollectionId]!.length;
  }

  Future _selectPages() async {
    await showDialog(
      context: context,
      builder: (context) {
        return PageSelectionDialog(onConfirmed: (List<int> pages) {
          var wordCollection = getCurrentWordCollection();
          var db = Database.selectDb(
            wordCollection,
            widget.db,
            widget.externalStorageDb,
          );
          for (var page in pages) {
            selectPage(wordCollection.id, page, db);
          }
        });
      },
    );
  }
}
