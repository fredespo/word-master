import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:word_master/select_all_notifier.dart';
import 'package:word_master/word_collection.dart';
import 'package:word_master/word_collection_status.dart';

class WordCollectionCard extends StatefulWidget {
  final WordCollection wordCollection;
  final Function(WordCollection) onTap;
  final bool isDismissible;
  final Function(WordCollection)? onDismissed;
  final double widthFactor;
  final Future<bool?> Function(DismissDirection, BuildContext, String)?
      confirmDismiss;
  final ValueNotifier<bool> inMultiSelectMode;
  final SelectAllNotifier? selectAllNotifier;
  final Function(WordCollection) onSelected;
  final Function(WordCollection) onDeselected;
  final bool isSelectedInitially;

  const WordCollectionCard({
    super.key,
    required this.wordCollection,
    required this.onTap,
    this.widthFactor = 1.0,
    this.onDismissed,
    this.confirmDismiss,
    required this.inMultiSelectMode,
    required this.onSelected,
    required this.onDeselected,
    this.selectAllNotifier,
    required this.isDismissible,
    this.isSelectedInitially = false,
  }) : assert(!isDismissible ||
            (isDismissible && onDismissed != null && confirmDismiss != null));

  @override
  State<WordCollectionCard> createState() => _WordCollectionCardState();
}

class _WordCollectionCardState extends State<WordCollectionCard> {
  final NumberFormat _numberFormat = NumberFormat('#,##0');
  bool _selected = false;

  @override
  void initState() {
    super.initState();
    widget.selectAllNotifier?.addListener(_onSelectAll);
    _selected = widget.isSelectedInitially;
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.inMultiSelectMode.value) {
      _selected = false;
    }
    final String status = WordCollectionStatus.getStatus(widget.wordCollection);

    var main = ValueListenableBuilder(
      valueListenable: widget.inMultiSelectMode,
      builder: (
        BuildContext context,
        bool inMultiSelectModeValue,
        Widget? child,
      ) {
        return GestureDetector(
          onTap: getOnTap(inMultiSelectModeValue, status),
          onLongPress: getOnLongPress(inMultiSelectModeValue, status),
          child: FractionallySizedBox(
            widthFactor: widget.widthFactor,
            child: _buildCard(inMultiSelectModeValue, status),
          ),
        );
      },
    );

    return widget.isDismissible && status != WordCollectionStatus.inProgress
        ? Center(
            child: Dismissible(
              key: Key(ObjectKey(widget.wordCollection).toString()),
              direction: DismissDirection.endToStart,
              confirmDismiss: (direction) {
                return widget.confirmDismiss!(
                    direction,
                    context,
                    widget.wordCollection.name.isNotEmpty
                        ? widget.wordCollection.name
                        : "Untitled Word Collection");
              },
              onDismissed: (direction) {
                widget.onDismissed!(widget.wordCollection);
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
              child: main,
            ),
          )
        : Center(child: main);
  }

  void Function()? getOnTap(final bool inMultiSelectMode, final String status) {
    if (status == WordCollectionStatus.created) {
      return inMultiSelectMode
          ? () => _toggleIsSelected()
          : () => widget.onTap(widget.wordCollection);
    }
    return null;
  }

  void Function()? getOnLongPress(
      final bool inMultiSelectMode, final String status) {
    if (status == WordCollectionStatus.created) {
      return inMultiSelectMode
          ? null
          : () {
              widget.inMultiSelectMode.value = true;
              _toggleIsSelected();
            };
    }

    return null;
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

  Widget _buildCard(bool inMultiSelectMode, String status) {
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
                  children: _buildBody(status),
                ),
              ),
            ),
          ),
          if (inMultiSelectMode && status == WordCollectionStatus.created)
            _buildMultiSelectIndicator(),
        ],
      ),
    );
  }

  List<Widget> _buildBody(final String status) {
    final DateTime createdOn = widget.wordCollection.createdOn;
    List<Widget> widgets = [];
    if (widget.wordCollection.name.isNotEmpty) {
      widgets.add(Text(widget.wordCollection.name,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: status == WordCollectionStatus.inProgress
                ? const Color.fromARGB(255, 85, 85, 85)
                : status == WordCollectionStatus.pending
                    ? Colors.grey
                    : Colors.black,
          )));
      widgets.add(const SizedBox(height: 8));
    }

    switch (status) {
      case WordCollectionStatus.pending:
        widgets.add(const Text("Pending"));
        break;
      case WordCollectionStatus.inProgress:
        widgets.add(const LinearProgressIndicator());
        break;
      case WordCollectionStatus.copyingToExternalStorage:
        widgets.add(const Text("Copying to external storage"));
        widgets.add(const LinearProgressIndicator());
        break;
      case WordCollectionStatus.created:
        widgets.add(Text(
            "Created on ${createdOn.month}/${createdOn.day}/${createdOn.year}"));
        widgets.add(const SizedBox(height: 8));
        widgets.add(Text(
            "with ${_numberFormat.format(widget.wordCollection.size)} entries"));
        break;
      case WordCollectionStatus.pendingCopyToExternalStorage:
        widgets.add(const Text("Pending copy to external storage"));
        break;
      case WordCollectionStatus.errored:
        widgets.add(const Text(
          "ERROR",
          style: TextStyle(color: Colors.red),
        ));
        widgets.add(ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 100),
          child: SingleChildScrollView(
            child: Text(
              widget.wordCollection.errorMessage,
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ));
        break;
    }

    if (widget.wordCollection.isOnExternalStorage == true) {
      widgets.add(const SizedBox(height: 8));
      widgets.add(const Text("on external storage"));
    }

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
    final String status = WordCollectionStatus.getStatus(widget.wordCollection);
    if (status == WordCollectionStatus.created) {
      setState(() {
        _selected = true;
      });
    }
  }

  @override
  void dispose() {
    widget.selectAllNotifier?.removeListener(_onSelectAll);
    super.dispose();
  }
}
