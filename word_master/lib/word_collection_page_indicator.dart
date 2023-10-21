import 'dart:async';

import 'package:flutter/material.dart';

class WordCollectionPageIndicator extends StatefulWidget {
  final ScrollController scrollController;
  final ValueNotifier<int> pageNotifier;

  const WordCollectionPageIndicator({
    super.key,
    required this.scrollController,
    required this.pageNotifier,
  });

  @override
  State<WordCollectionPageIndicator> createState() =>
      _WordCollectionPageIndicatorState();
}

class _WordCollectionPageIndicatorState
    extends State<WordCollectionPageIndicator> {
  bool scrolledRecently = false;
  Timer? fadeTimer;

  @override
  void initState() {
    super.initState();
    widget.scrollController.addListener(() {
      setState(() {
        scrolledRecently = true;
        fadeTimer?.cancel();
        fadeTimer = Timer(const Duration(milliseconds: 1500), () {
          setState(() {
            scrolledRecently = false;
          });
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
      builder: (BuildContext context, pageNum, Widget? child) {
        return Container(
          color: const Color.fromARGB(255, 134, 134, 134).withOpacity(0.8),
          child: Align(
            alignment: Alignment.center,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                "Page: $pageNum",
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
      valueListenable: widget.pageNotifier,
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

  @override
  void dispose() {
    fadeTimer?.cancel();
    super.dispose();
  }
}
