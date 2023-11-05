import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:realm/realm.dart';
import 'package:word_master/page_jumper_activation_notifier.dart';
import 'package:word_master/word_collection_entry.dart';
import 'package:word_master/word_collection_page.dart';
import 'package:word_master/word_collection_page_indicator.dart';
import 'package:word_master/page_jumper.dart';

class WordCollectionWidget extends StatefulWidget {
  final Realm db;
  final String name;
  final Color bgColor = const Color.fromARGB(255, 134, 134, 134);
  final int numColumns = 6;
  static const int numWordsPerPage = 192;
  final RealmResults<WordCollectionEntry> entries;
  final ValueNotifier<int> sizeNotifier;
  final ValueNotifier<int> pageHeight = ValueNotifier<int>(1);
  final ValueNotifier<int> totalPages;
  final ScrollController scrollController;
  final ValueNotifier<double> pagesViewportHeight = ValueNotifier<double>(1000);
  final ValueNotifier<int> pageNumNotifier;
  final PageJumperActivationNotifier pageJumperActivationNotifier;
  final ValueNotifier<bool> viewingFavesNotifier;
  final ValueNotifier<double> scrollOffsetNotifier;

  WordCollectionWidget({
    super.key,
    required this.db,
    required this.name,
    required this.entries,
    required this.sizeNotifier,
    required this.viewingFavesNotifier,
    required this.pageJumperActivationNotifier,
    required this.pageNumNotifier,
    required this.scrollController,
    required this.scrollOffsetNotifier,
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
    SchedulerBinding.instance.addPostFrameCallback((_) {
      widget.scrollController.jumpTo(widget.scrollOffsetNotifier.value);
    });
    widget.viewingFavesNotifier.addListener(_onViewingFavesChange);
    _viewingFaves = widget.viewingFavesNotifier.value;
    widget.sizeNotifier.addListener(_onSizeChange);
    super.initState();
  }

  @override
  void dispose() {
    widget.scrollController.removeListener(_onScroll);
    widget.viewingFavesNotifier.removeListener(_onViewingFavesChange);
    widget.sizeNotifier.removeListener(_onSizeChange);
    super.dispose();
  }

  void _onSizeChange() {
    setState(() {});
  }

  void _onViewingFavesChange() {
    setState(() {
      _viewingFaves = widget.viewingFavesNotifier.value;
      if (_viewingFaves) {
        SchedulerBinding.instance.addPostFrameCallback((_) {
          widget.scrollController.jumpTo(favoritesOnlyScrollOffset);
        });
      } else {
        SchedulerBinding.instance.addPostFrameCallback((_) {
          widget.scrollController.jumpTo(normalScrollOffset);
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    SchedulerBinding.instance.addPostFrameCallback(_calcPagesViewportHeight);
    return Stack(
      children: [
        _buildPages(),
        Positioned(
          top: 0,
          left: 0,
          right: 0,
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
      pageNum: index + 1,
      pageHeight: widget.pageHeight,
      pageNumNotifier: widget.pageNumNotifier,
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
    widget.scrollOffsetNotifier.value = widget.scrollController.offset;
  }
}
