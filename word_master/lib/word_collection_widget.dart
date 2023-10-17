import 'dart:math';

import 'package:flutter/material.dart';
import 'package:realm/realm.dart';
import 'package:word_master/word_collection_action_menu.dart';
import 'package:word_master/word_collection_entry.dart';
import 'package:word_master/word_collection_page.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'package:word_master/word_collection_page_indicator.dart';

class WordCollectionWidget extends StatefulWidget {
  final Realm db;
  final String name;
  final Function() onAddEntries;
  final Function() onCreateEntry;
  final Color bgColor = const Color.fromARGB(255, 134, 134, 134);
  final int numColumns = 6;
  final int numWordsPerPage = 192;
  final RealmResults<WordCollectionEntry> entries;
  final ValueNotifier<int> sizeNotifier;
  final ValueNotifier<int> currentPageNum = ValueNotifier<int>(1);
  final ScrollController scrollController = ScrollController();

  WordCollectionWidget({
    super.key,
    required this.db,
    required this.name,
    required this.onAddEntries,
    required this.entries,
    required this.sizeNotifier,
    required this.onCreateEntry,
  });

  @override
  State<WordCollectionWidget> createState() => _WordCollectionWidgetState();
}

class _WordCollectionWidgetState extends State<WordCollectionWidget> {
  bool _viewingFaves = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
            widget.name.isNotEmpty ? widget.name : 'Untitled Word Collection'),
        actions: [
          WordCollectionActionMenu(
            onViewFaves: () {
              setState(() {
                _viewingFaves = true;
              });
            },
            onViewAll: () {
              setState(() {
                _viewingFaves = false;
              });
            },
            onAddEntries: widget.onAddEntries,
            onCreateEntry: widget.onCreateEntry,
          )
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    return Stack(
      children: [
        _buildPages(),
        Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: WordCollectionPageIndicator(
              scrollController: widget.scrollController,
              pageNotifier: widget.currentPageNum,
            )),
      ],
    );
  }

  Widget _buildPages() {
    return InteractiveViewer(
      child: Container(
        decoration: BoxDecoration(color: widget.bgColor),
        child: ValueListenableBuilder(
          valueListenable: widget.sizeNotifier,
          builder: (BuildContext context, pageNum, Widget? child) {
            return _buildPageList();
          },
        ),
      ),
    );
  }

  Widget _buildPageList() {
    final entries = _viewingFaves
        ? widget.entries.query("isFavorite == true").toList()
        : widget.entries.toList();
    return ListView.builder(
      controller: widget.scrollController,
      itemCount: (entries.length / widget.numWordsPerPage).ceil(),
      itemBuilder: (context, index) {
        Widget item = VisibilityDetector(
          key: Key('page_$index'),
          onVisibilityChanged: (VisibilityInfo info) {
            if (info.visibleFraction > 0.5) {
              widget.currentPageNum.value = index + 1;
            }
          },
          child: _buildPage(index, entries),
        );
        return item;
      },
    );
  }

  Widget _buildPage(int index, List<WordCollectionEntry> entries) {
    int startIndex = index * widget.numWordsPerPage;
    int endIndex = min((index + 1) * widget.numWordsPerPage, entries.length);
    Widget page = WordCollectionPage(
      numColumns: widget.numColumns,
      db: widget.db,
      startIndex: startIndex,
      endIndex: endIndex,
      numTotalEntries: widget.numWordsPerPage,
      entries: entries,
    );
    return page;
  }
}
