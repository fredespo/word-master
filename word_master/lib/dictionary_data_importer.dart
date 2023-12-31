import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:realm/realm.dart';
import 'package:http/http.dart' as http;
import 'package:word_master/dictionary.dart';

import 'dictionary_entry.dart';

class DictionaryDataImporter extends StatefulWidget {
  final Realm db;
  final String dictionaryId;

  const DictionaryDataImporter({
    super.key,
    required this.db,
    required this.dictionaryId,
  });

  @override
  State<DictionaryDataImporter> createState() => _DictionaryDataImporterState();
}

class _DictionaryDataImporterState extends State<DictionaryDataImporter> {
  double progress = 0;
  bool inProgress = false;

  @override
  Widget build(BuildContext context) {
    List<Widget> children = [_buildImportButton()];
    if (inProgress) {
      children.add(const SizedBox(height: 10));
      children.add(_buildProgressIndicator());
    }
    return Column(children: children);
  }

  Widget _buildImportButton() {
    return ElevatedButton(
      onPressed: inProgress
          ? null
          : () async {
              setState(() {
                inProgress = true;
                progress = 0;
              });

              await Future.delayed(const Duration(seconds: 1));
              await _importDictionaryEntries(
                progressCallback: (progress) {
                  setState(() {
                    this.progress = progress;
                  });
                },
              );

              setState(() {
                inProgress = false;
              });
            },
      child: Text(inProgress ? 'Importing...' : 'Import'),
    );
  }

  Future<void> _importDictionaryEntries({
    int? total,
    Function(double)? progressCallback,
  }) async {
    String functionUrl =
        "https://rgnbhyf5h63zg2krd6mxtr7cga0qlnse.lambda-url.us-east-1.on.aws/";

    int numPerCall = 10000;
    if (total != null && total < numPerCall) {
      numPerCall = total;
    }
    String? startKey;
    num totalCount = 0;
    num expectedTotal = total ?? 350000;
    var dict = widget.db.find<Dictionary>(widget.dictionaryId);
    if (dict == null) {
      return;
    }

    await clearDictionaryEntries(dict);
    do {
      Map<String, dynamic> args = {
        'limit': numPerCall,
      };
      if (startKey != null) {
        args['start_key'] = startKey;
      }
      var body = jsonEncode(args);
      http.Response response = await http.post(Uri.parse(functionUrl),
          headers: {"Content-Type": "application/json"}, body: body);
      var responseBody = jsonDecode(response.body);
      var entries = responseBody['definitions'];
      startKey = responseBody.containsKey('start_key')
          ? responseBody['start_key']
          : null;

      widget.db.write(() {
        for (var entry in entries.entries) {
          var wordOrPhrase = entry.key;
          var definitions = entry.value;
          widget.db.add(
            DictionaryEntry(
              widget.dictionaryId,
              wordOrPhrase,
              json.encode(definitions),
            ),
          );
          dict.size++;
        }
      });
      totalCount += entries.length;
      if (progressCallback != null) {
        progressCallback(totalCount / expectedTotal);
      }
    } while (startKey != null && (total == null || totalCount < total));
  }

  Future clearDictionaryEntries(Dictionary dictionary) async {
    const batchSize = 100;
    var preexistingEntries = widget.db
        .all<DictionaryEntry>()
        .query("dictionaryId == '${dictionary.id}'")
        .toList();

    for (int i = 0; i < preexistingEntries.length; i += batchSize) {
      widget.db.write(() {
        for (int j = i;
            j < i + batchSize && j < preexistingEntries.length;
            j++) {
          widget.db.delete(preexistingEntries[j]);
        }
      });
      await Future.delayed(const Duration(microseconds: 1));
    }

    widget.db.write(() => dictionary.size = 0);
  }

  Widget _buildProgressIndicator() {
    return SizedBox(
      width: 100,
      child: LinearProgressIndicator(
        value: progress,
        backgroundColor: Colors.grey[300],
      ),
    );
  }
}
