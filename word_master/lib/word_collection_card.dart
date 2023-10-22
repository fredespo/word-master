import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:word_master/select_all_notifier.dart';
import 'package:word_master/word_collection.dart';

class WordCollectionCard extends StatefulWidget {
  final WordCollection wordCollection;
  final Function(WordCollection) onTap;
  final Function(WordCollection) onDismissed;
  final double widthFactor;
  final Future<bool?> Function(DismissDirection, BuildContext, String)
      confirmDismiss;
  final ValueNotifier<bool> inMultiSelectMode;
  final SelectAllNotifier selectAllNotifier;
  final Function(WordCollection) onSelected;
  final Function(WordCollection) onDeselected;

  const WordCollectionCard({
    super.key,
    required this.wordCollection,
    required this.onTap,
    this.widthFactor = 1.0,
    required this.onDismissed,
    required this.confirmDismiss,
    required this.inMultiSelectMode,
    required this.onSelected,
    required this.onDeselected,
    required this.selectAllNotifier,
  });

  @override
  State<WordCollectionCard> createState() => _WordCollectionCardState();
}

class _WordCollectionCardState extends State<WordCollectionCard> {
  final NumberFormat _numberFormat = NumberFormat('#,##0');
  bool _selected = false;

  @override
  void initState() {
    super.initState();
    widget.selectAllNotifier.addListener(_onSelectAll);
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.inMultiSelectMode.value) {
      _selected = false;
    }
    return Center(
      child: Dismissible(
        key: Key(ObjectKey(widget.wordCollection).toString()),
        direction: DismissDirection.endToStart,
        confirmDismiss: (direction) {
          return widget.confirmDismiss(
              direction,
              context,
              widget.wordCollection.name.isNotEmpty
                  ? widget.wordCollection.name
                  : "Untitled Word Collection");
        },
        onDismissed: (direction) {
          widget.onDismissed(widget.wordCollection);
        },
        background: Container(
          color: Colors.red,
          child: const Align(
            alignment: Alignment.centerRight,
            child: Padding(
              padding: EdgeInsets.only(right: 16),
              child: Icon(
                Icons.delete,
                color: Colors.white,
              ),
            ),
          ),
        ),
        child: ValueListenableBuilder(
          valueListenable: widget.inMultiSelectMode,
          builder: (
            BuildContext context,
            bool inMultiSelectModeValue,
            Widget? child,
          ) {
            return GestureDetector(
              onTap: inMultiSelectModeValue
                  ? () => _toggleIsSelected()
                  : () => widget.onTap(widget.wordCollection),
              onLongPress: inMultiSelectModeValue
                  ? null
                  : () {
                      widget.inMultiSelectMode.value = true;
                      _toggleIsSelected();
                    },
              child: FractionallySizedBox(
                widthFactor: widget.widthFactor,
                child: _buildCard(inMultiSelectModeValue),
              ),
            );
          },
        ),
      ),
    );
  }

  void _toggleIsSelected() {
    setState(() {
      _selected = !_selected;
    });
    if (_selected) {
      widget.onSelected(widget.wordCollection);
    } else {
      widget.onDeselected(widget.wordCollection);
    }
  }

  Widget _buildCard(bool inMultiSelectMode) {
    return Card(
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              border: _selected
                  ? Border.all(color: Colors.blue)
                  : Border.all(color: Colors.transparent),
            ),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: _buildBody(),
                ),
              ),
            ),
          ),
          if (inMultiSelectMode) _buildMultiSelectIndicator(),
        ],
      ),
    );
  }

  List<Widget> _buildBody() {
    final DateTime createdOn = widget.wordCollection.createdOn;
    List<Widget> widgets = [];
    if (widget.wordCollection.name.isNotEmpty) {
      widgets.add(Text(widget.wordCollection.name,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          )));
      widgets.add(const SizedBox(height: 8));
    }
    widgets.add(Text(
        "Created on ${createdOn.month}/${createdOn.day}/${createdOn.year}"));
    widgets.add(const SizedBox(height: 8));
    widgets.add(Text(
        "with ${_numberFormat.format(widget.wordCollection.size)} entries"));
    return widgets;
  }

  Widget _buildMultiSelectIndicator() {
    return Positioned(
      top: 10,
      left: 10,
      child: Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: _selected ? Colors.blue : Colors.transparent,
          border: Border.all(
            color: _selected ? Colors.blue : Colors.grey,
            width: 2,
          ),
        ),
        child: const Icon(
          Icons.check,
          color: Colors.white,
          size: 16,
        ),
      ),
    );
  }

  void _onSelectAll() {
    setState(() {
      _selected = true;
    });
  }

  @override
  void dispose() {
    widget.selectAllNotifier.removeListener(_onSelectAll);
    super.dispose();
  }
}
