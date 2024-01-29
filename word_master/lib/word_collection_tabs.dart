import 'dart:math';

import 'package:flutter/material.dart';
import 'package:realm/realm.dart';
import 'package:word_master/page_jumper_activation_notifier.dart';
import 'package:word_master/random_word_fetcher.dart';
import 'package:word_master/word_collection.dart';
import 'package:word_master/word_collection_action_menu.dart';
import 'package:word_master/word_collection_adder.dart';
import 'package:word_master/word_collection_creator.dart';
import 'package:word_master/word_collection_entry.dart';
import 'package:word_master/word_collection_entry_creator.dart';
import 'package:word_master/word_collection_manager.dart';
import 'package:word_master/word_collection_selection_dialog.dart';
import 'package:word_master/word_collection_shuffle_dialog.dart';
import 'package:word_master/word_collection_shuffler.dart';
import 'package:word_master/word_collection_tabs_title.dart';
import 'package:word_master/word_collection_widget.dart';

import 'dictionary.dart';

class WordCollectionTabs extends StatefulWidget {
  final List<WordCollection> initialWordCollections;
  final Realm db;

  const WordCollectionTabs({
    super.key,
    required this.initialWordCollections,
    required this.db,
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

  @override
  void initState() {
    _tabController = TabController(length: 0, vsync: this);
    _tabController.addListener(_handleTabChange);
    for (var wordCollection in widget.initialWordCollections) {
      addWordCollection(wordCollection);
    }
    super.initState();
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    super.dispose();
  }

  void addWordCollection(WordCollection wordCollection) {
    var entries = widget.db
        .all<WordCollectionEntry>()
        .query("wordCollectionId == '${wordCollection.id}'");

    if (entries.isNotEmpty && entries.first.id == 0) {
      widget.db.write(() {
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
    var db = widget.db;
    showDialog(
      context: context,
      builder: (context) {
        return WordCollectionAdder(
          wordCollection: wordCollection,
          dictionaries: db.all<Dictionary>().query("size > 0"),
          onAddEntries: addRandomEntries,
          db: db,
        );
      },
    );
  }

  void addRandomEntries(Map<String, int> numEntriesPerDictionaryId) {
    var db = widget.db;
    var wordCollection = getCurrentWordCollection();
    var wordCollectionSizeNotifier = sizeNotifiers[wordCollection.id]!;
    db.write(() {
      wordCollectionSizeNotifier.value = wordCollection.size;
      for (var dictionaryId in numEntriesPerDictionaryId.keys) {
        var numEntries = numEntriesPerDictionaryId[dictionaryId]!;
        var words = RandomWordFetcher.getRandomWords(
          db,
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
      actions: [
        ValueListenableBuilder(
          valueListenable: selectedCount,
          builder: (BuildContext context, int value, Widget? child) {
            return value == 0
                ? _buildNormalActionMenu()
                : _buildSelectedActionMenu(value);
          },
        ),
      ],
    );
  }

  Widget _buildNormalActionMenu() {
    return WordCollectionActionMenu(
      onAddEntries: handleAddRandomEntriesAction,
      onCreateEntry: handleCreateEntryAction,
      onJumpToPage: handleJumpToPageAction,
      onViewAll: handleViewAllAction,
      onViewFaves: handleViewOnlyFavoritesAction,
      onOpenInNewTab: handleOpenInNewTabAction,
      onCloseCurrentTab: handleCloseCurrentTabAction,
      onShuffle: handleShuffleAction,
    );
  }

  Widget _buildSelectedActionMenu(int numSelected) {
    if (numSelected < 2) return Container();
    return IconButton(
      icon: const Icon(Icons.shuffle),
      onPressed: () {
        shuffleSelected();
        deselectAll();
      },
    );
  }

  void shuffleSelected() {
    var wordCollection = getCurrentWordCollection();
    var selectedEntryIds = this.selectedEntryIds[wordCollection.id]!;
    var entries = [];
    for (var entry
        in wordCollectionWidgets[_tabController.index].entries.toList()) {
      if (selectedEntryIds.contains(entry.id)) {
        entries.add(entry);
      }
    }
    var entryData = [];
    for (var entry in entries) {
      entryData.add([entry.wordOrPhrase, entry.isFavorite]);
    }
    entryData.shuffle();
    var i = 0;
    widget.db.write(() {
      for (var entry in entries) {
        entry.wordOrPhrase = entryData[i][0];
        entry.isFavorite = entryData[i][1];
        i++;
      }
    });
  }

  void deselectAll() {
    selectedCounts[getCurrentWordCollection().id]!.value = 0;
    selectedEntryIds[getCurrentWordCollection().id]!.clear();
    selectedCount.value = 0;
  }

  void handleOpenInNewTabAction() {
    var openableWordCollections = widget.db
        .all<WordCollection>()
        .where(
            (collection) => !wordCollections.any((c) => c.id == collection.id))
        .toList();
    showDialog(
        context: context,
        builder: (context) {
          return WordCollectionSelectionDialog(
            wordCollections: openableWordCollections,
            onSelect: _onOpenWordCollection,
            onCreateNewCollection: _handleNewWordCollectionCreation,
          );
        });
  }

  _onOpenWordCollection(WordCollection wordCollection) {
    Navigator.pop(context);
    addWordCollection(wordCollection);
  }

  _handleNewWordCollectionCreation() {
    Navigator.pop(context);
    showDialog(
      context: context,
      builder: (context) {
        return WordCollectionCreator(
          dictionaries: widget.db.all<Dictionary>().query("size > 0"),
          onCreate: createWordCollection,
          db: widget.db,
        );
      },
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
        widget.db,
        dictionaryId,
        numEntries,
      );
      int id = 1;
      widget.db.write(() {
        for (var word in words) {
          widget.db.add(WordCollectionEntry(
            id++,
            wordCollection.id,
            dictionaryId,
            word,
            false,
          ));
        }
      });
    }
    widget.db.write(() {
      widget.db.add(wordCollection);
    });
    addWordCollection(wordCollection);
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
          );
        },
      ),
    );
  }

  void handleShuffleAction() async {
    ValueNotifier<double> progress = new ValueNotifier<double>(0);
    var wordCollection = getCurrentWordCollection();
    showDialog(
        context: context,
        builder: (context) => WordCollectionShuffleDialog(
            wordCollection: wordCollection, progress: progress));
    await WordCollectionShuffler.shuffle(wordCollection, progress, widget.db);

    sizeNotifiers[wordCollection.id]!.value = wordCollection.size - 1;
    sizeNotifiers[wordCollection.id]!.value = wordCollection.size;

    Navigator.pop(context); // Close the progress dialog
  }

  void _handleTabChange() {
    deselectAll();
  }
}
