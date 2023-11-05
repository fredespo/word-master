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
  final Function() onOpenInNewTab;
  static const actionValueOpenInNewTab = 6;
  final Function() onCloseCurrentTab;
  static const actionValueCloseCurrentTab = 7;

  const WordCollectionActionMenu({
    super.key,
    required this.onViewFaves,
    required this.onViewAll,
    required this.onAddEntries,
    required this.onCreateEntry,
    required this.onJumpToPage,
    required this.onOpenInNewTab,
    required this.onCloseCurrentTab,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton(
      itemBuilder: (BuildContext context) {
        return [
          const PopupMenuItem(
            value: actionValueOpenInNewTab,
            child: Text('Open in new tab'),
          ),
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

      case actionValueOpenInNewTab:
        onOpenInNewTab();
        break;

      case actionValueCloseCurrentTab:
        onCloseCurrentTab();
        break;
    }
  }
}
