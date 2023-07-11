import 'dart:convert';
import 'dart:math';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:realm/realm.dart';
import 'package:word_master/word_collection_data.dart';

import 'dictionary_entry.dart';

class WordCollection extends StatelessWidget {
  final WordCollectionData data;
  final Realm db;

  const WordCollection({
    super.key,
    required this.data,
    required this.db,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Word Table'),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    return LayoutBuilder(builder: (context, constraints) {
      final screenWidth = constraints.maxWidth;
      final numColumns =
          (screenWidth / 100).floor(); // adjust the column width here

      return ListView.builder(
        itemCount: (data.words.length / numColumns).ceil(), // Number of rows
        itemBuilder: (context, index) {
          List<TableCell> currentRowCells = [];

          for (int i = index * numColumns;
              i < min((index + 1) * numColumns, data.words.length);
              i++) {
            currentRowCells.add(_buildTableCell(data.words[i], context));
          }

          while (currentRowCells.length < numColumns) {
            currentRowCells.add(_buildTableCell('', context));
          }

          return Table(
            border: TableBorder.all(),
            children: [
              TableRow(
                children: currentRowCells,
              ),
            ],
          );
        },
      );
    });
  }

  TableCell _buildTableCell(String wordOrPhrase, BuildContext context) {
    return TableCell(
      child: SizedBox(
        height: 50,
        child: InkWell(
          onTap: () {
            _showDefinitions(wordOrPhrase, context);
          },
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Center(
              child: AutoSizeText(
                textAlign: TextAlign.center,
                wordOrPhrase,
                maxLines: 2,
              ),
            ),
          ),
        ),
      ),
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
}
