import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:word_master/page_jumper_activation_notifier.dart';

class PageJumper extends StatefulWidget {
  final ValueNotifier<int> totalPageCount;
  final Function(int) onGoToPage;
  final ValueNotifier<double> parentHeight;
  final ValueNotifier<int> pageNumNotifier;
  final PageJumperActivationNotifier activationNotifier;
  final ScrollController scrollController;

  const PageJumper({
    super.key,
    required this.totalPageCount,
    required this.onGoToPage,
    required this.parentHeight,
    required this.pageNumNotifier,
    required this.activationNotifier,
    required this.scrollController,
  });

  @override
  State<PageJumper> createState() => _PageJumperState();
}

class _PageJumperState extends State<PageJumper> {
  double _dragPosition = 0;
  double _maxDragPosition = 0;
  int _pageNum = 1;
  bool _isOn = false;
  Timer? turnOffTimer;
  DateTime? lastPageNumUpdate;
  bool _scrollingFromPageIncrementOrDecrement = false;
  bool _showLabel = false;
  int totalPageCount = 0;

  @override
  void initState() {
    super.initState();
    widget.pageNumNotifier.addListener(_onPageNumUpdate);
    widget.activationNotifier.addListener(_turnOn);
    widget.scrollController.addListener(_onScroll);
    widget.parentHeight.addListener(_calcMaxDragPosition);
    widget.totalPageCount.addListener(_onTotalPageCountChange);
    totalPageCount = widget.totalPageCount.value;
  }

  @override
  void dispose() {
    widget.pageNumNotifier.removeListener(_onPageNumUpdate);
    widget.activationNotifier.removeListener(_turnOn);
    widget.scrollController.removeListener(_onScroll);
    widget.parentHeight.removeListener(_calcMaxDragPosition);
    widget.totalPageCount.removeListener(_onTotalPageCountChange);
    super.dispose();
  }

  void _onPageNumUpdate() {
    int newPageNum = widget.pageNumNotifier.value;
    if (_pageNum == newPageNum) {
      return;
    }

    if (lastPageNumUpdate != null && !_isOn) {
      var diff = DateTime.now().difference(lastPageNumUpdate!);
      if (diff < const Duration(milliseconds: 2500)) {
        _turnOn();
        turnOffAfterSeconds(3);
      }
    }
    lastPageNumUpdate = DateTime.now();
    SchedulerBinding.instance.addPostFrameCallback((_) {
      setState(() {
        _pageNum = newPageNum;
        _dragPosition = (newPageNum / totalPageCount) * _maxDragPosition;
      });
    });
  }

  void _onScroll() {
    if (_isOn && !_scrollingFromPageIncrementOrDecrement) {
      turnOffAfterSeconds(2);
    }
    _scrollingFromPageIncrementOrDecrement = false;
  }

  void _turnOn() {
    setState(() {
      _isOn = true;
    });
  }

  void _turnOff() {
    setState(() {
      _isOn = false;
    });
  }

  void turnOffAfterSeconds(int seconds) {
    turnOffTimer?.cancel();
    turnOffTimer = Timer(Duration(seconds: seconds), _turnOff);
  }

  @override
  Widget build(BuildContext context) {
    return _isOn
        ? ValueListenableBuilder(
            valueListenable: widget.pageNumNotifier,
            builder: (
              BuildContext context,
              pageNumNotifierValue,
              Widget? child,
            ) {
              return Positioned(
                top: _dragPosition,
                right: 10,
                child: _buildVisibleWidgets(),
              );
            },
          )
        : Container();
  }

  Widget _buildVisibleWidgets() {
    return Row(
      children: [
        if (_showLabel) _buildLabel(),
        const SizedBox(width: 5),
        _buildHandle(),
      ],
    );
  }

  Widget _buildHandle() {
    return addStyle(
      GestureDetector(
        onVerticalDragStart: _onVerticalDragStart,
        onVerticalDragUpdate: _onVerticalDragUpdate,
        onVerticalDragEnd: _onVerticalDragEnd,
        child: Column(
          children: [
            _buildPreviousPageButton(),
            const Icon(Icons.drag_handle),
            _buildNextPageButton(),
          ],
        ),
      ),
    );
  }

  void _onVerticalDragStart(DragStartDetails details) {
    setState(() {
      _showLabel = true;
    });
  }

  void _onVerticalDragUpdate(DragUpdateDetails details) {
    setState(() {
      turnOffTimer?.cancel();
      _dragPosition += details.delta.dy;
      if (_dragPosition < 0) {
        _dragPosition = 0;
      } else if (_dragPosition > _maxDragPosition) {
        _dragPosition = _maxDragPosition;
      }
      _pageNum = _calcPageNumFromDragPos();
    });
  }

  int _calcPageNumFromDragPos() {
    var fraction = _dragPosition / _maxDragPosition;
    var pageNum = (fraction * totalPageCount).round();
    if (pageNum < 1) {
      pageNum = 1;
    }
    if (pageNum > totalPageCount) {
      pageNum = totalPageCount;
    }
    return pageNum;
  }

  void _onVerticalDragEnd(DragEndDetails details) {
    setState(() {
      _showLabel = false;
    });
    widget.onGoToPage(_pageNum);
    turnOffAfterSeconds(3);
  }

  Widget _buildPreviousPageButton() {
    return IconButton(
      icon: const Icon(Icons.keyboard_arrow_up),
      onPressed: () {
        if (widget.pageNumNotifier.value > 1) {
          _scrollingFromPageIncrementOrDecrement = true;
          widget.onGoToPage(widget.pageNumNotifier.value - 1);
        }
        turnOffAfterSeconds(7);
      },
    );
  }

  Widget _buildNextPageButton() {
    return IconButton(
      icon: const Icon(Icons.keyboard_arrow_down),
      onPressed: () {
        if (widget.pageNumNotifier.value < totalPageCount) {
          _scrollingFromPageIncrementOrDecrement = true;
          widget.onGoToPage(widget.pageNumNotifier.value + 1);
        }
        turnOffAfterSeconds(7);
      },
    );
  }

  Widget _buildLabel() {
    return addStyle(
      Padding(
        padding: const EdgeInsets.all(8.0),
        child: Text(
          "Page $_pageNum",
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  Widget addStyle(Widget child) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.blue,
        boxShadow: const [BoxShadow(offset: Offset(0, 2), blurRadius: 2.0)],
        borderRadius: BorderRadius.circular(16.0),
      ),
      child: child,
    );
  }

  void _calcMaxDragPosition() {
    setState(() {
      _maxDragPosition = widget.parentHeight.value - 110;
    });
  }

  void _onTotalPageCountChange() {
    setState(() {
      totalPageCount = widget.totalPageCount.value;
      _pageNum = _calcPageNumFromDragPos();
    });
  }
}
