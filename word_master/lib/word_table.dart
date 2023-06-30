import 'dart:math';

import 'package:flutter/material.dart';
import 'package:realm/realm.dart';

import 'dictionary_entry.dart';

class WordTable extends StatelessWidget {
  final RealmResults<DictionaryEntry> entries;
  final Realm db;

  const WordTable({
    super.key,
    required this.entries,
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
    return ListView.builder(
      itemCount: (entries.length / 6).ceil(), // Number of rows
      itemBuilder: (context, index) {
        List<TableCell> currentRowCells = [];

        // i runs from (index*6) to ((index+1)*6 - 1) or the end of results
        for (int i = index * 6; i < min((index + 1) * 6, entries.length); i++) {
          currentRowCells
              .add(_buildTableCell(entries[i].wordOrPhrase, context));
        }

        // TableRow needs at least one cell, so in a case when we have fewer
        // than 6 words for the last row, we add empty cells
        while (currentRowCells.length < 6) {
          currentRowCells.add(_buildTableCell('', context));
        }

        // Build a table for each row
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
  }

  TableCell _buildTableCell(String wordOrPhrase, BuildContext context) {
    return TableCell(
      child: InkWell(
        onTap: () {
          _showDefinitions(wordOrPhrase, context);
        },
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(wordOrPhrase),
        ),
      ),
    );
  }

  void _showDefinitions(String wordOrPhrase, BuildContext context) {
    String definitions = db.find<DictionaryEntry>(wordOrPhrase)!.definitions;
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(wordOrPhrase),
          content: Text(definitions),
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
