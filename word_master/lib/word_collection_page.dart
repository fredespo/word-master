import 'package:flutter/material.dart';
import 'package:realm/realm.dart';
import 'package:word_master/definitions_dialog.dart';
import 'package:word_master/word_collection_entry.dart';
import 'package:word_master/word_collection_page_cell.dart';

class WordCollectionPage extends StatefulWidget {
  final int pageNum;
  final int numColumns;
  final int startIndex;
  final int endIndex;
  final int numTotalEntries;
  final RealmResults<WordCollectionEntry> entries;
  final Realm db;
  final Realm? externalStorageDb;
  final Realm wordCollectionDb;
  final ValueNotifier<int> pageNumNotifier;
  final ValueNotifier<int> pageHeight;
  final ValueNotifier<bool> inMultiSelectMode;
  final ValueNotifier<int> selectedCount;
  final Set<int> selected;

  const WordCollectionPage({
    super.key,
    required this.numColumns,
    required this.db,
    required this.externalStorageDb,
    required this.wordCollectionDb,
    required this.startIndex,
    required this.endIndex,
    required this.numTotalEntries,
    required this.entries,
    required this.pageNum,
    required this.pageHeight,
    required this.pageNumNotifier,
    required this.inMultiSelectMode,
    required this.selectedCount,
    required this.selected,
  });

  @override
  State<WordCollectionPage> createState() => _WordCollectionPageState();
}

class _WordCollectionPageState extends State<WordCollectionPage> {
  int currentPageNum = 1;

  @override
  void initState() {
    super.initState();
    widget.pageNumNotifier.addListener(onPageNumChange);
    currentPageNum = widget.pageNumNotifier.value;
  }

  @override
  void dispose() {
    widget.pageNumNotifier.removeListener(onPageNumChange);
    super.dispose();
  }

  void onPageNumChange() {
    setState(() {
      currentPageNum = widget.pageNumNotifier.value;
    });
  }

  @override
  Widget build(BuildContext context) {
    return (currentPageNum - widget.pageNum).abs() <= 1
        ? _buildPage(context)
        : ValueListenableBuilder(
            valueListenable: widget.pageHeight,
            builder: (BuildContext context, pageHeightValue, Widget? child) {
              return Container(
                height: pageHeightValue.toDouble(),
              );
            },
          );
  }

  Widget _buildPage(BuildContext context) {
    List<Widget> rows = [];
    var numRows = widget.numTotalEntries / widget.numColumns;
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
    var start = widget.startIndex + rowIndex * widget.numColumns;
    var end = widget.startIndex + ((rowIndex + 1) * widget.numColumns);

    for (int i = start; i < end; i++) {
      int colNum = i % widget.numColumns;
      Color bgColor = colNum % 2 == 0 ? Colors.grey.shade100 : Colors.white;
      var entry = i < widget.endIndex ? widget.entries[i] : null;
      currentRowCells.add(TableCell(
        child: _buildTableCellContent(entry, context, bgColor),
      ));
    }

    while (currentRowCells.length < widget.numColumns) {
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
          widget.wordCollectionDb.write(() {
            entry.isFavorite = true;
          });
        }
      },
      onUnmarkedFavorite: (wordOrPhrase) {
        if (entry != null) {
          widget.wordCollectionDb.write(() {
            entry.isFavorite = false;
          });
        }
      },
      inMultiSelectMode: widget.inMultiSelectMode,
      selectedCount: widget.selectedCount,
      selected: widget.selected,
    );
  }

  void _showDefinitions(WordCollectionEntry entry, BuildContext context) {
    ValueNotifier<bool> isFavoriteNotifier = ValueNotifier(entry.isFavorite);
    showDialog(
      context: context,
      builder: (context) {
        return DefinitionsDialog(
          wordOrPhrase: entry.wordOrPhrase,
          db: widget.db,
          externalStorageDb: widget.externalStorageDb,
          dictionaryId: entry.dictionaryId,
          onToggleFavorite: () {
            onFavoriteToggle(entry);
            isFavoriteNotifier.value = entry.isFavorite;
          },
          isFavoriteNotifier: isFavoriteNotifier,
        );
      },
    ).then((value) {
      isFavoriteNotifier.dispose();
      refresh();
    });
  }

  void onFavoriteToggle(WordCollectionEntry entry) {
    widget.wordCollectionDb.write(() {
      entry.isFavorite = !entry.isFavorite;
    });
  }

  void refresh() {
    setState(() {});
  }
}
