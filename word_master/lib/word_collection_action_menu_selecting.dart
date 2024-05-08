import 'package:flutter/material.dart';

class WordCollectionActionMenuSelecting extends StatelessWidget {
  final Function() selectCurrPage;
  static const actionValueSelectCurrPage = 0;
  final Future Function() selectPages;
  static const actionValueSelectPages = 1;
  final Function() onShuffle;
  static const actionValueShuffle = 2;
  final Future Function() onDisperse;
  static const actionValueDisperse = 3;
  final Function() deselectAll;

  const WordCollectionActionMenuSelecting({
    super.key,
    required this.selectCurrPage,
    required this.selectPages,
    required this.onShuffle,
    required this.onDisperse,
    required this.deselectAll,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton(
      itemBuilder: (BuildContext context) {
        return [
          const PopupMenuItem(
            value: actionValueSelectCurrPage,
            child: Text('Select current page'),
          ),
          const PopupMenuItem(
            value: actionValueSelectPages,
            child: Text('Select pages'),
          ),
          const PopupMenuItem(
            value: actionValueShuffle,
            child: Text('Shuffle selected'),
          ),
          const PopupMenuItem(
            value: actionValueDisperse,
            child: Text('Disperse selected'),
          ),
        ];
      },
      onSelected: _handleMenuSelection,
    );
  }

  void _handleMenuSelection(int value) async {
    switch (value) {
      case actionValueSelectCurrPage:
        selectCurrPage();
        break;

      case actionValueSelectPages:
        await selectPages();
        break;

      case actionValueShuffle:
        onShuffle();
        deselectAll();
        break;

      case actionValueDisperse:
        await onDisperse();
        deselectAll();
        break;
    }
  }
}
