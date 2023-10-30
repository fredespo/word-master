import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:realm/realm.dart';
import 'package:word_master/page_jumper_activation_notifier.dart';
import 'package:word_master/word_collection_action_menu.dart';
import 'package:word_master/word_collection_entry.dart';
import 'package:word_master/word_collection_page.dart';
import 'package:word_master/word_collection_page_indicator.dart';
import 'package:word_master/page_jumper.dart';

class WordCollectionWidget extends StatefulWidget {
  final Realm db;
  final String name;
  final Function() onAddEntries;
  final Function() onCreateEntry;
  final Color bgColor = const Color.fromARGB(255, 134, 134, 134);
  final int numColumns = 6;
  static const int numWordsPerPage = 192;
  final RealmResults<WordCollectionEntry> entries;
  final ValueNotifier<int> sizeNotifier;
  final ValueNotifier<int> pageHeight = ValueNotifier<int>(1);
  final ValueNotifier<int> totalPages;
  final ScrollController scrollController = ScrollController();
  final ValueNotifier<double> pagesViewportHeight = ValueNotifier<double>(1000);
  final ValueNotifier<int> pageNumNotifier = ValueNotifier<int>(1);
  final pageJumperActivationNotifier = PageJumperActivationNotifier();

  WordCollectionWidget({
    super.key,
    required this.db,
    required this.name,
    required this.onAddEntries,
    required this.entries,
    required this.sizeNotifier,
    required this.onCreateEntry,
  }) : totalPages =
            ValueNotifier<int>((entries.length / numWordsPerPage).ceil());

  @override
  State<WordCollectionWidget> createState() => _WordCollectionWidgetState();
}

class _WordCollectionWidgetState extends State<WordCollectionWidget> {
  bool _viewingFaves = false;
  final GlobalKey firstPageKey = GlobalKey();
  final pagesKey = GlobalKey();
  double normalScrollOffset = 0;
  double favoritesOnlyScrollOffset = 0;

  @override
  void initState() {
    widget.scrollController.addListener(_onScroll);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    SchedulerBinding.instance.addPostFrameCallback(_calcPagesViewportHeight);
    return Scaffold(
      appBar: AppBar(
        title: Text(
            widget.name.isNotEmpty ? widget.name : 'Untitled Word Collection'),
        actions: [
          WordCollectionActionMenu(
            onViewFaves: () {
              setState(() {
                _viewingFaves = true;
                widget.scrollController.jumpTo(favoritesOnlyScrollOffset);
              });
            },
            onViewAll: () {
              setState(() {
                _viewingFaves = false;
                widget.scrollController.jumpTo(normalScrollOffset);
              });
            },
            onAddEntries: widget.onAddEntries,
            onCreateEntry: widget.onCreateEntry,
            onJumpToPage: () {
              widget.pageJumperActivationNotifier.turnOnPageJumper();
            },
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
          right: 32,
          child: WordCollectionPageIndicator(
            scrollController: widget.scrollController,
            pageHeight: widget.pageHeight,
            totalPages: widget.totalPages,
            pageNumNotifier: widget.pageNumNotifier,
          ),
        ),
        PageJumper(
          totalPageCount: widget.totalPages,
          onGoToPage: _jumpToPage,
          parentHeight: widget.pagesViewportHeight,
          pageNumNotifier: widget.pageNumNotifier,
          activationNotifier: widget.pageJumperActivationNotifier,
          scrollController: widget.scrollController,
        ),
      ],
    );
  }

  Widget _buildPages() {
    return Container(
      key: pagesKey,
      decoration: BoxDecoration(color: widget.bgColor),
      child: _buildPageList(),
    );
  }

  Widget _buildPageList() {
    final entries = _viewingFaves
        ? widget.entries.query("isFavorite == true").toList()
        : widget.entries.toList();
    var pageCount =
        (entries.length / WordCollectionWidget.numWordsPerPage).ceil();
    SchedulerBinding.instance.addPostFrameCallback((_) {
      widget.totalPages.value = pageCount;
    });
    return ListView.builder(
      controller: widget.scrollController,
      itemCount: pageCount,
      itemBuilder: (context, index) {
        return _buildPage(index, entries);
      },
    );
  }

  Widget _buildPage(int index, List<WordCollectionEntry> entries) {
    int startIndex = index * WordCollectionWidget.numWordsPerPage;
    int endIndex =
        min((index + 1) * WordCollectionWidget.numWordsPerPage, entries.length);
    Widget page = WordCollectionPage(
      key: index == 0 ? firstPageKey : null,
      numColumns: widget.numColumns,
      db: widget.db,
      startIndex: startIndex,
      endIndex: endIndex,
      numTotalEntries: WordCollectionWidget.numWordsPerPage,
      entries: entries,
      scrollController: widget.scrollController,
      pageNum: index + 1,
      pageHeight: widget.pageHeight,
    );
    if (index == 0) {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        final RenderObject? renderObject =
            firstPageKey.currentContext?.findRenderObject();
        if (renderObject == null) {
          return;
        }
        RenderBox renderBox = renderObject as RenderBox;
        final height = renderBox.size.height;
        widget.pageHeight.value = height.toInt();
      });
    }
    return page;
  }

  void _calcPagesViewportHeight(Duration _) {
    final RenderObject? renderObject =
        pagesKey.currentContext?.findRenderObject();
    if (renderObject == null) {
      return;
    }
    RenderBox renderBox = renderObject as RenderBox;
    widget.pagesViewportHeight.value = renderBox.size.height;
  }

  void _jumpToPage(int pageNum) {
    widget.scrollController.jumpTo(
      ((pageNum - 1) * widget.pageHeight.value.toDouble()) + 10,
    );
  }

  void _onScroll() {
    if (_viewingFaves) {
      favoritesOnlyScrollOffset = widget.scrollController.offset;
    } else {
      normalScrollOffset = widget.scrollController.offset;
    }
  }
}
