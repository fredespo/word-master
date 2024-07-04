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
  final Function() onJumpToPage;
  static const actionValueJumpToPage = 5;
  final Function() onCloseCurrentTab;
  static const actionValueCloseCurrentTab = 7;
  final Function() onShuffle;
  static const actionValueShuffle = 8;

  const WordCollectionActionMenu({
    super.key,
    required this.onViewFaves,
    required this.onViewAll,
    required this.onAddEntries,
    required this.onCreateEntry,
    required this.onJumpToPage,
    required this.onCloseCurrentTab,
    required this.onShuffle,
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
          const PopupMenuItem(
            value: actionValueJumpToPage,
            child: Text('Jump to page'),
          ),
          const PopupMenuItem(
            value: actionValueCloseCurrentTab,
            child: Text('Close current tab'),
          ),
          const PopupMenuItem(
            value: actionValueShuffle,
            child: Text('Shuffle'),
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

      case actionValueJumpToPage:
        onJumpToPage();
        break;

      case actionValueCloseCurrentTab:
        onCloseCurrentTab();
        break;

      case actionValueShuffle:
        onShuffle();
        break;
    }
  }
}
