import 'dart:async';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:realm/realm.dart';
import 'package:word_master/word_collection_entry.dart';

class WordCollectionPageCell extends StatefulWidget {
  final WordCollectionEntry? entry;
  final Color bgColor;
  final Function(WordCollectionEntry) showDefinitions;
  final Function(String) onMarkedFavorite;
  final Function(String) onUnmarkedFavorite;
  final Realm db;
  final controller = StreamController<RealmObject>();
  final ValueNotifier<bool> inMultiSelectMode;
  final ValueNotifier<int> selectedCount;
  final Set<int> selected;

  WordCollectionPageCell({
    super.key,
    required this.bgColor,
    required this.showDefinitions,
    required this.onMarkedFavorite,
    required this.onUnmarkedFavorite,
    required this.entry,
    required this.db,
    required this.inMultiSelectMode,
    required this.selectedCount,
    required this.selected,
  });

  @override
  State<WordCollectionPageCell> createState() => _WordCollectionPageCellState();
}

class _WordCollectionPageCellState extends State<WordCollectionPageCell> {
  bool isSelected = false;

  @override
  void initState() {
    super.initState();
    if (widget.entry != null) {
      widget.controller.add(widget.entry!);
    }
    widget.selectedCount.addListener(onSelectedCountChange);
  }

  @override
  Widget build(BuildContext context) {
    return widget.entry != null
        ? StreamBuilder<RealmObject>(
            stream: widget.controller.stream,
            builder: (context, snapshot) => getMainBody())
        : getMainBody();
  }

  Widget getMainBody() {
    return Container(
      decoration: BoxDecoration(
        color: widget.bgColor,
      ),
      child: SizedBox(
        height: 50,
        child: InkWell(
          onLongPress: onLongPress,
          onDoubleTap: onDoubleTap,
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(4.0),
            child: Container(
              decoration: BoxDecoration(
                border: isSelected
                    ? Border.all(color: Colors.blue, width: 2.5)
                    : null,
              ),
              child: Stack(
                children: [
                  Center(child: _buildText()),
                  if (widget.entry?.isFavorite == true) _buildHighlight(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void onLongPress() {
    _toggleIsSelected();
    if (!widget.inMultiSelectMode.value) {
      widget.inMultiSelectMode.value = true;
    }
  }

  void onDoubleTap() {
    if (widget.entry != null) {
      _toggleIsFavorite();
    }
  }

  void _toggleIsSelected() {
    if (widget.entry == null) {
      return;
    }
    setState(() {
      isSelected = !isSelected;
      if (isSelected) {
        widget.selectedCount.value++;
        widget.selected.add(widget.entry!.id);
      } else {
        widget.selectedCount.value--;
        widget.selected.remove(widget.entry!.id);
      }
    });
  }

  void onSelectedCountChange() {
    if (isSelected && widget.selectedCount.value == 0) {
      setState(() {
        isSelected = false;
      });
    }
  }

  void onTap() {
    if (widget.inMultiSelectMode.value) {
      _toggleIsSelected();
    } else if (widget.entry != null) {
      widget.showDefinitions(widget.entry!);
    }
  }

  Widget _buildText() {
    final fontWeight =
        widget.entry?.isFavorite == true ? FontWeight.bold : FontWeight.normal;
    return AutoSizeText(
      textAlign: TextAlign.center,
      widget.entry?.wordOrPhrase ?? '',
      maxLines: 2,
      minFontSize: 8,
      maxFontSize: 12,
      style: TextStyle(fontWeight: fontWeight),
    );
  }

  Widget _buildHighlight() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        height: 35,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          gradient: const LinearGradient(
            colors: [
              Color.fromARGB(112, 255, 230, 0),
              Color.fromRGBO(255, 230, 0, 0.09)
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
      ),
    );
  }

  void _toggleIsFavorite() {
    setState(() {
      widget.db.write(() {
        widget.entry!.isFavorite = !widget.entry!.isFavorite;
      });
    });
  }

  @override
  void dispose() {
    widget.controller.close();
    widget.selectedCount.removeListener(onSelectedCountChange);
    super.dispose();
  }
}
