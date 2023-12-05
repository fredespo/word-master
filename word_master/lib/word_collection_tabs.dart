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
  final Map<String, ScrollController> scrollControllers = {};
  final Map<String, ValueNotifier<double>> scrollOffsets = {};
  late TabController _tabController;

  @override
  void initState() {
    _tabController = TabController(length: 0, vsync: this);
    for (var wordCollection in widget.initialWordCollections) {
      addWordCollection(wordCollection);
    }
    super.initState();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void addWordCollection(WordCollection wordCollection) {
    var entries = widget.db
        .all<WordCollectionEntry>()
        .query("wordCollectionId == '${wordCollection.id}'");

    setState(() {
      viewingFavesNotifiers[wordCollection.id] = ValueNotifier<bool>(false);
      sizeNotifiers[wordCollection.id] = ValueNotifier<int>(entries.length);
      pageJumperActivationNotifiers[wordCollection.id] =
          PageJumperActivationNotifier();
      pageNumNotifiers[wordCollection.id] = ValueNotifier<int>(1);
      scrollControllers[wordCollection.id] = ScrollController();
      scrollOffsets[wordCollection.id] = ValueNotifier<double>(0);
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
          scrollController: scrollControllers[wordCollection.id]!,
          scrollOffsetNotifier: scrollOffsets[wordCollection.id]!,
        ),
      );
      _tabController.dispose();
      _tabController = TabController(
        length: wordCollections.length,
        vsync: this,
        initialIndex: wordCollections.length - 1,
      );
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
      wordCollection.size +=
          numEntriesPerDictionaryId.values.reduce((a, b) => a + b);
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
        child: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: Row(
            children: [
              const Text('Collections'),
              const SizedBox(width: 20),
              _buildViewAllButton(),
            ],
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
            WordCollectionActionMenu(
              onAddEntries: handleAddRandomEntriesAction,
              onCreateEntry: handleCreateEntryAction,
              onJumpToPage: handleJumpToPageAction,
              onViewAll: handleViewAllAction,
              onViewFaves: handleViewOnlyFavoritesAction,
              onOpenInNewTab: handleOpenInNewTabAction,
              onCloseCurrentTab: handleCloseCurrentTabAction,
            ),
          ],
        ),
      ),
      body: TabBarView(
        key: UniqueKey(),
        controller: _tabController,
        children: wordCollectionWidgets,
      ),
    );
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
      widget.db.write(() {
        for (var word in words) {
          widget.db.add(WordCollectionEntry(
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
    var scrollController = scrollControllers[wordCollectionId]!;
    var scrollOffsetNotifier = scrollOffsets[wordCollectionId]!;
    setState(() {
      wordCollections.removeAt(wordCollectionIndex);
      wordCollectionWidgets.removeAt(wordCollectionIndex);
      viewingFavesNotifiers.remove(wordCollectionId);
      sizeNotifiers.remove(wordCollectionId);
      pageJumperActivationNotifiers.remove(wordCollectionId);
      pageNumNotifiers.remove(wordCollectionId);
      scrollControllers.remove(wordCollectionId);
      scrollOffsets.remove(wordCollectionId);
      wordCollectionSizeNotifier.dispose();
      viewingFavesNotifier.dispose();
      pageJumperActivationNotifier.dispose();
      pageNumNotifier.dispose();
      scrollController.dispose();
      scrollOffsetNotifier.dispose();
      _tabController.dispose();
      _tabController = TabController(
        length: wordCollections.length,
        vsync: this,
        initialIndex: wordCollectionIndex == 0 ? 0 : wordCollectionIndex - 1,
      );
      if (wordCollections.isEmpty) {
        Navigator.of(context).pop();
      }
    });
  }

  _buildViewAllButton() {
    return TextButton(
      onPressed: () {
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
      },
      style: TextButton.styleFrom(
        foregroundColor: Colors.blue,
        backgroundColor: Colors.white,
      ),
      child: const Text(
        "All",
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
