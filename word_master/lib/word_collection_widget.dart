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
  final Realm? externalStorageDb;
  final Realm wordCollectionDb;
  final String name;
  final Color bgColor = const Color.fromARGB(255, 134, 134, 134);
  final int numColumns = 6;
  static const int numWordsPerPage = 192;
  final RealmResults<WordCollectionEntry> entries;
  final ValueNotifier<int> sizeNotifier;
  final ValueNotifier<int> pageHeight = ValueNotifier<int>(1);
  final ValueNotifier<int> totalPages;
  final ValueNotifier<ScrollController> scrollController =
      ValueNotifier(ScrollController());
  final ValueNotifier<double> pagesViewportHeight = ValueNotifier<double>(1000);
  final ValueNotifier<int> pageNumNotifier;
  final PageJumperActivationNotifier pageJumperActivationNotifier;
  final ValueNotifier<bool> viewingFavesNotifier;
  final ValueNotifier<double> scrollOffsetNotifier;
  final ValueNotifier<bool> inMultiSelectMode = ValueNotifier<bool>(false);
  final ValueNotifier<int> selectedCount;
  final Set<int> selected;

  WordCollectionWidget({
    super.key,
    required this.db,
    required this.externalStorageDb,
    required this.name,
    required this.entries,
    required this.sizeNotifier,
    required this.viewingFavesNotifier,
    required this.pageJumperActivationNotifier,
    required this.pageNumNotifier,
    required this.scrollOffsetNotifier,
    required this.selectedCount,
    required this.selected,
    required this.wordCollectionDb,
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
    widget.scrollController.value.addListener(_onScroll);
    SchedulerBinding.instance.addPostFrameCallback((_) {
      widget.scrollController.value.jumpTo(widget.scrollOffsetNotifier.value);
    });
    widget.viewingFavesNotifier.addListener(_onViewingFavesChange);
    _viewingFaves = widget.viewingFavesNotifier.value;
    widget.sizeNotifier.addListener(_onSizeChange);
    widget.selectedCount.addListener(_onSelectedCountChange);
    super.initState();
  }

  @override
  void dispose() {
    widget.scrollController.removeListener(_onScroll);
    widget.viewingFavesNotifier.removeListener(_onViewingFavesChange);
    widget.sizeNotifier.removeListener(_onSizeChange);
    widget.selectedCount.removeListener(_onSelectedCountChange);
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
          widget.scrollController.value.jumpTo(favoritesOnlyScrollOffset);
        });
      } else {
        SchedulerBinding.instance.addPostFrameCallback((_) {
          widget.scrollController.value.jumpTo(normalScrollOffset);
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
          scrollController: widget.scrollController.value,
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
    final sortedEntries = widget.entries.query("TRUEPREDICATE SORT(id ASC)");
    final entries = _viewingFaves
        ? sortedEntries.query("isFavorite == true")
        : sortedEntries;
    var pageCount =
        (entries.length / WordCollectionWidget.numWordsPerPage).ceil();
    SchedulerBinding.instance.addPostFrameCallback((_) {
      widget.totalPages.value = pageCount;
    });

    if (widget.scrollController.value.hasClients) {
      widget.scrollController.value.dispose();
    }
    widget.scrollController.value = ScrollController();

    return ListView.builder(
      controller: widget.scrollController.value,
      itemCount: pageCount,
      itemBuilder: (context, index) {
        return _buildPage(index, entries);
      },
    );
  }

  Widget _buildPage(int index, RealmResults<WordCollectionEntry> entries) {
    int startIndex = index * WordCollectionWidget.numWordsPerPage;
    int endIndex =
        min((index + 1) * WordCollectionWidget.numWordsPerPage, entries.length);
    Widget page = WordCollectionPage(
      key: index == 0 ? firstPageKey : null,
      numColumns: widget.numColumns,
      db: widget.db,
      wordCollectionDb: widget.wordCollectionDb,
      startIndex: startIndex,
      endIndex: endIndex,
      numTotalEntries: WordCollectionWidget.numWordsPerPage,
      entries: entries,
      pageNum: index + 1,
      pageHeight: widget.pageHeight,
      pageNumNotifier: widget.pageNumNotifier,
      inMultiSelectMode: widget.inMultiSelectMode,
      selectedCount: widget.selectedCount,
      selected: widget.selected,
      externalStorageDb: widget.externalStorageDb,
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
    widget.scrollController.value.jumpTo(
      ((pageNum - 1) * widget.pageHeight.value.toDouble()) + 10,
    );
  }

  void _onScroll() {
    if (_viewingFaves) {
      favoritesOnlyScrollOffset = widget.scrollController.value.offset;
    } else {
      normalScrollOffset = widget.scrollController.value.offset;
    }
    widget.scrollOffsetNotifier.value = widget.scrollController.value.offset;
  }

  void _onSelectedCountChange() {
    if (widget.selectedCount.value == 0) {
      widget.inMultiSelectMode.value = false;
    }
  }
}
