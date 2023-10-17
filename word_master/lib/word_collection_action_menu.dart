import 'package:flutter/material.dart';

class WordCollectionActionMenu extends StatelessWidget {
  final Function() onAddEntries;
  static const actionValueAddEntries = 1;
  final Function() onViewFaves;
  static const actionValueViewFaves = 2;
  final Function() onViewAll;
  static const actionValueViewAll = 3;
  final Function() onCreateEntry;
  static const actionValueCreateEntry = 4;

  const WordCollectionActionMenu({
    super.key,
    required this.onViewFaves,
    required this.onViewAll,
    required this.onAddEntries,
    required this.onCreateEntry,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton(
      itemBuilder: (BuildContext context) {
        return [
          const PopupMenuItem(
            value: actionValueAddEntries,
            child: Text('Add random entries'),
          ),
          const PopupMenuItem(
            value: actionValueCreateEntry,
            child: Text('Create entry'),
          ),
          const PopupMenuItem(
            value: actionValueViewFaves,
            child: Text('View only favorites'),
          ),
          const PopupMenuItem(
            value: actionValueViewAll,
            child: Text('View all'),
          ),
        ];
      },
      onSelected: _handleMenuSelection,
    );
  }

  void _handleMenuSelection(int value) {
    switch (value) {
      case actionValueAddEntries:
        onAddEntries();
        break;

      case actionValueViewFaves:
        onViewFaves();
        break;

      case actionValueViewAll:
        onViewAll();
        break;

      case actionValueCreateEntry:
        onCreateEntry();
        break;
    }
  }
}
