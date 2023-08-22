import 'package:flutter/material.dart';

class WordCollectionActionMenu extends StatelessWidget {
  final Function() onViewFaves;
  static const actionValueViewFaves = 1;
  final Function() onViewAll;
  static const actionValueViewAll = 2;

  const WordCollectionActionMenu({
    super.key,
    required this.onViewFaves,
    required this.onViewAll,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton(
      itemBuilder: (BuildContext context) {
        return [
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
      case actionValueViewFaves:
        onViewFaves();
        break;

      case actionValueViewAll:
        onViewAll();
        break;
    }
  }
}
