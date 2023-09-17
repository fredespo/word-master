import 'dart:math';

import 'package:flutter/material.dart';
import 'package:realm/realm.dart';
import 'package:word_master/word_collection_action_menu.dart';
import 'package:word_master/word_collection_page.dart';
import 'package:visibility_detector/visibility_detector.dart';

class WordCollection extends StatefulWidget {
  final Realm db;
  final String name;
  final List<String> words;
  final Set<String> favorites;
  final Function() onViewFavorites;
  final Function() onViewAll;
  final Color bgColor = const Color.fromARGB(255, 134, 134, 134);
  final int numColumns = 6;
  final int numWordsPerPage = 192;
  final Map<int, Widget> pages = {};

  WordCollection({
    super.key,
    required this.db,
    required this.name,
    required this.words,
    required this.favorites,
    required this.onViewFavorites,
    required this.onViewAll,
  });

  @override
  State<WordCollection> createState() => _WordCollectionState();
}

class _WordCollectionState extends State<WordCollection> {
  int _currentPageNum = 1;
  bool _listScrolledRecently = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
            widget.name.isNotEmpty ? widget.name : 'Untitled Word Collection'),
        actions: [
          WordCollectionActionMenu(
            onViewFaves: widget.onViewFavorites,
            onViewAll: widget.onViewAll,
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
          child: _buildPageIndicator(),
        ),
      ],
    );
  }

  Widget _buildPageIndicator() {
    Widget indicator = Container(
      color: widget.bgColor.withOpacity(0.8),
      child: Align(
        alignment: Alignment.center,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            "Page: $_currentPageNum",
            style: const TextStyle(
              color: Colors.black,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
    return _listScrolledRecently
        ? indicator
        : TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 1, end: 0),
            duration: const Duration(milliseconds: 200),
            builder: (BuildContext context, double opacity, Widget? child) {
              return Opacity(
                opacity: opacity,
                child: indicator,
              );
            },
          );
  }

  Widget _buildPages() {
    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification is ScrollUpdateNotification) {
          setState(() {
            _listScrolledRecently = true;
            Future.delayed(const Duration(milliseconds: 2000), () {
              setState(() {
                _listScrolledRecently = false;
              });
            });
          });
        }
        return true;
      },
      child: InteractiveViewer(
        child: Container(
          decoration: BoxDecoration(color: widget.bgColor),
          child: _buildPageList(),
        ),
      ),
    );
  }

  Widget _buildPageList() {
    return ListView.builder(
      itemCount: (widget.words.length / widget.numWordsPerPage).ceil(),
      itemBuilder: (context, index) {
        Widget item = VisibilityDetector(
          key: Key('page_$index'),
          onVisibilityChanged: (VisibilityInfo info) {
            if (info.visibleFraction > 0.5) {
              setState(() {
                _currentPageNum = index + 1;
              });
            }
          },
          child: _buildPage(index),
        );
        return item;
      },
    );
  }

  Widget _buildPage(int index) {
    if (widget.pages.containsKey(index)) {
      return widget.pages[index]!;
    }

    int startIndex = index * widget.numWordsPerPage;
    int endIndex =
        min((index + 1) * widget.numWordsPerPage, widget.words.length);
    Widget page = WordCollectionPage(
      numColumns: widget.numColumns,
      words: widget.words,
      db: widget.db,
      startIndex: startIndex,
      endIndex: endIndex,
      numTotalEntries: widget.numWordsPerPage,
      favorites: widget.favorites,
    );
    widget.pages[index] = page;
    return page;
  }
}
