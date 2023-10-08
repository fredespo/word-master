import 'package:flutter/material.dart';

class WordCollectionActionMenu extends StatelessWidget {
  final Function() onAddEntries;
  static const actionValueAddEntries = 1;
  final Function() onViewFaves;
  static const actionValueViewFaves = 2;
  final Function() onViewAll;
  static const actionValueViewAll = 3;

  const WordCollectionActionMenu({
    super.key,
    required this.onViewFaves,
    required this.onViewAll,
    required this.onAddEntries,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton(
      itemBuilder: (BuildContext context) {
        return [
          const PopupMenuItem(
            value: actionValueAddEntries,
            child: Text('Add entries'),
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
    }
  }
}
