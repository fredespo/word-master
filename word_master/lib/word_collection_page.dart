import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:realm/realm.dart';
import 'package:word_master/word_collection_page_cell.dart';

import 'dictionary_entry.dart';

class WordCollectionPage extends StatelessWidget {
  final int numColumns;
  final List<String> words;
  final int startIndex;
  final int endIndex;
  final int numTotalEntries;
  final Realm db;
  final Set<String> favorites;

  const WordCollectionPage({
    super.key,
    required this.numColumns,
    required this.words,
    required this.db,
    required this.startIndex,
    required this.endIndex,
    required this.numTotalEntries,
    required this.favorites,
  });

  @override
  Widget build(BuildContext context) {
    List<Widget> rows = [];
    for (int i = 0; i < numTotalEntries / numColumns; i++) {
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

    for (int i = startIndex + rowIndex * numColumns;
        i < startIndex + ((rowIndex + 1) * numColumns);
        i++) {
      int colNum = i % numColumns;
      Color bgColor = colNum % 2 == 0 ? Colors.grey.shade100 : Colors.white;
      String word = i < endIndex ? words[i] : '';
      currentRowCells.add(
          TableCell(child: _buildTableCellContent(word, context, bgColor)));
    }

    while (currentRowCells.length < numColumns) {
      currentRowCells.add(
          TableCell(child: _buildTableCellContent('', context, Colors.white)));
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
    String wordOrPhrase,
    BuildContext context,
    Color bgColor,
  ) {
    return WordCollectionPageCell(
      wordOrPhrase: wordOrPhrase,
      bgColor: bgColor,
      isFavorite: favorites.contains(wordOrPhrase),
      showDefinitions: (wordOrPhrase) {
        _showDefinitions(wordOrPhrase, context);
      },
      onMarkedFavorite: (wordOrPhrase) {
        db.write(() {
          favorites.add(wordOrPhrase);
        });
      },
      onUnmarkedFavorite: (wordOrPhrase) {
        db.write(() {
          favorites.remove(wordOrPhrase);
        });
      },
    );
  }

  void _showDefinitions(String wordOrPhrase, BuildContext context) {
    var dictionaryEntry = db.find<DictionaryEntry>(wordOrPhrase);
    if (dictionaryEntry == null) {
      return;
    }
    String definitions = dictionaryEntry.definitions;
    Map<String, dynamic> jsonMap = jsonDecode(definitions);
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(wordOrPhrase),
          content: SizedBox(
            width: MediaQuery.of(context).size.width * 0.5,
            height: MediaQuery.of(context).size.height * 0.4,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: jsonMap.keys.map((key) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        key,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      ...List<Widget>.generate(
                        jsonMap[key].length,
                        (index) => Text('${index + 1}. ${jsonMap[key][index]}'),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  void onFavoriteToggle(String wordOrPhrase) {
    db.write(() {
      if (!favorites.add(wordOrPhrase)) {
        favorites.remove(wordOrPhrase);
      }
    });
  }
}
