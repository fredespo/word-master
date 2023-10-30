import 'package:flutter/material.dart';
import 'package:realm/realm.dart';
import 'package:word_master/definitions_dialog.dart';
import 'package:word_master/word_collection_entry.dart';
import 'package:word_master/word_collection_page_cell.dart';

class WordCollectionPage extends StatelessWidget {
  final int pageNum;
  final int numColumns;
  final int startIndex;
  final int endIndex;
  final int numTotalEntries;
  final List<WordCollectionEntry> entries;
  final Realm db;
  final ScrollController scrollController;
  final ValueNotifier<int> pageHeight;

  const WordCollectionPage({
    super.key,
    required this.numColumns,
    required this.db,
    required this.startIndex,
    required this.endIndex,
    required this.numTotalEntries,
    required this.entries,
    required this.scrollController,
    required this.pageNum,
    required this.pageHeight,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: pageHeight,
      builder: (BuildContext context, pageHeightValue, Widget? child) {
        int scrollOffset = scrollController.offset.toInt();
        int currentPageNum = (scrollOffset / pageHeightValue).ceil();

        return (currentPageNum - pageNum).abs() <= 1
            ? _buildPage(context)
            : Container(
                height: pageHeightValue.toDouble(),
              );
      },
    );
  }

  Widget _buildPage(BuildContext context) {
    List<Widget> rows = [];
    var numRows = numTotalEntries / numColumns;
    for (int i = 0; i < numRows; i++) {
      rows.add(_buildTableRow(context, i));
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
      child: Container(
        decoration: BoxDecoration(border: Border.all()),
        child: Column(children: rows),
      ),
    );
  }

  Widget _buildTableRow(BuildContext context, int rowIndex) {
    List<TableCell> currentRowCells = [];
    var start = startIndex + rowIndex * numColumns;
    var end = startIndex + ((rowIndex + 1) * numColumns);

    for (int i = start; i < end; i++) {
      int colNum = i % numColumns;
      Color bgColor = colNum % 2 == 0 ? Colors.grey.shade100 : Colors.white;
      var entry = i < endIndex ? entries[i] : null;
      currentRowCells.add(TableCell(
        child: _buildTableCellContent(entry, context, bgColor),
      ));
    }

    while (currentRowCells.length < numColumns) {
      currentRowCells.add(TableCell(
          child: _buildTableCellContent(null, context, Colors.white)));
    }

    return Table(
      border: null,
      children: [
        TableRow(
          children: currentRowCells,
        ),
      ],
    );
  }

  Widget _buildTableCellContent(
    WordCollectionEntry? entry,
    BuildContext context,
    Color bgColor,
  ) {
    return WordCollectionPageCell(
      entry: entry,
      bgColor: bgColor,
      showDefinitions: (entry) {
        _showDefinitions(entry, context);
      },
      onMarkedFavorite: (wordOrPhrase) {
        if (entry != null) {
          db.write(() {
            entry.isFavorite = true;
          });
        }
      },
      onUnmarkedFavorite: (wordOrPhrase) {
        if (entry != null) {
          db.write(() {
            entry.isFavorite = false;
          });
        }
      },
      db: db,
    );
  }

  void _showDefinitions(WordCollectionEntry entry, BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return DefinitionsDialog(
          wordOrPhrase: entry.wordOrPhrase,
          db: db,
          dictionaryId: entry.dictionaryId,
        );
      },
    );
  }

  void onFavoriteToggle(WordCollectionEntry entry) {
    db.write(() {
      entry.isFavorite = !entry.isFavorite;
    });
  }
}
