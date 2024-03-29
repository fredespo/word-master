import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:intl/intl.dart';

class WordCollectionPageIndicator extends StatefulWidget {
  final ValueNotifier<ScrollController> scrollController;
  final ValueNotifier<int> pageHeight;
  final ValueNotifier<int> totalPages;
  final ValueNotifier<int> pageNumNotifier;
  final numFormatter = NumberFormat('#,##0');

  WordCollectionPageIndicator({
    super.key,
    required this.scrollController,
    required this.pageHeight,
    required this.totalPages,
    required this.pageNumNotifier,
  });

  @override
  State<WordCollectionPageIndicator> createState() =>
      _WordCollectionPageIndicatorState();
}

class _WordCollectionPageIndicatorState
    extends State<WordCollectionPageIndicator> {
  bool scrolledRecently = false;
  Timer? fadeTimer;
  int pageNum = 1;
  late ScrollController scrollController;

  @override
  void initState() {
    super.initState();
    scrollController = widget.scrollController.value;
    widget.scrollController.value.addListener(onScroll);
    widget.scrollController.addListener(onScrollControllerChange);
  }

  void onScroll() {
    setState(() {
      pageNum = _calcPageNum();
      scrolledRecently = true;
      fadeTimer?.cancel();
      fadeTimer = Timer(const Duration(milliseconds: 1500), () {
        setState(() {
          scrolledRecently = false;
        });
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return scrolledRecently
        ? _buildNormalPageIndicator()
        : _buildFadingPageIndicator();
  }

  Widget _buildNormalPageIndicator() {
    return ValueListenableBuilder(
      valueListenable: widget.totalPages,
      builder: (BuildContext context, value, Widget? child) {
        return ValueListenableBuilder(
          valueListenable: widget.pageHeight,
          builder: (BuildContext context, pageNum, Widget? child) {
            pageNum = _calcPageNum();
            SchedulerBinding.instance.addPostFrameCallback((_) {
              widget.pageNumNotifier.value = pageNum;
            });
            return Container(
              color: const Color.fromARGB(255, 134, 134, 134).withOpacity(0.8),
              child: Align(
                alignment: Alignment.center,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    "Page: ${widget.numFormatter.format(pageNum)} of ${widget.numFormatter.format(widget.totalPages.value)}",
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildFadingPageIndicator() {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 1, end: 0),
      duration: const Duration(milliseconds: 200),
      builder: (BuildContext context, double opacity, Widget? child) {
        return Opacity(
          opacity: opacity,
          child: _buildNormalPageIndicator(),
        );
      },
    );
  }

  int _calcPageNum() {
    int pageHeight = widget.pageHeight.value;
    int scrollOffset = scrollController.offset.toInt();
    int pageNum = (scrollOffset / pageHeight).ceil();
    if (pageNum < 1) {
      pageNum = 1;
    }
    return pageNum;
  }

  @override
  void dispose() {
    fadeTimer?.cancel();
    scrollController.removeListener(onScroll);
    super.dispose();
  }

  void onScrollControllerChange() {
    if (!mounted) {
      return;
    }
    setState(() {
      scrollController.removeListener(onScroll);
      scrollController = widget.scrollController.value;
      widget.scrollController.value.addListener(onScroll);
    });
  }
}
