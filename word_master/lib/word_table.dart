import 'dart:convert';
import 'dart:math';

import 'package:auto_size_text/auto_size_text.dart';
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

        for (int i = index * 6; i < min((index + 1) * 6, entries.length); i++) {
          currentRowCells
              .add(_buildTableCell(entries[i].wordOrPhrase, context));
        }

        while (currentRowCells.length < 6) {
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
  }

  TableCell _buildTableCell(String wordOrPhrase, BuildContext context) {
    return TableCell(
      child: InkWell(
        onTap: () {
          _showDefinitions(wordOrPhrase, context);
        },
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: AutoSizeText(
            wordOrPhrase,
            maxLines: 1,
          ),
        ),
      ),
    );
  }

  void _showDefinitions(String wordOrPhrase, BuildContext context) {
    String definitions = db.find<DictionaryEntry>(wordOrPhrase)!.definitions;
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
