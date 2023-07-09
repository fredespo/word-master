import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:realm/realm.dart';
import 'package:http/http.dart' as http;

import 'dictionary_entry.dart';

class DictionaryDataImporter extends StatefulWidget {
  final Realm db;

  const DictionaryDataImporter({super.key, required this.db});

  @override
  State<DictionaryDataImporter> createState() => _DictionaryDataImporterState();
}

class _DictionaryDataImporterState extends State<DictionaryDataImporter> {
  bool enabled = true;
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
      onPressed: enabled
          ? () async {
              setState(() {
                enabled = false;
                inProgress = true;
              });

              await _importDictionaryEntries(
                progressCallback: (progress) {
                  setState(() {
                    this.progress = progress;
                  });
                },
              );

              setState(() {
                enabled = true;
                inProgress = false;
              });
            }
          : null,
      child: const Text('Import'),
    );
  }

  Future<void> _importDictionaryEntries({
    int? total,
    Function(double)? progressCallback,
  }) async {
    String functionUrl =
        "https://rgnbhyf5h63zg2krd6mxtr7cga0qlnse.lambda-url.us-east-1.on.aws/";

    int numPerCall = 1000;
    if (total != null && total < numPerCall) {
      numPerCall = total;
    }
    String? startKey;
    num totalCount = 0;
    num expectedTotal = total ?? 350000;
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
            DictionaryEntry(wordOrPhrase, json.encode(definitions)),
            update: true,
          );
        }
      });
      totalCount += entries.length;
      if (progressCallback != null) {
        progressCallback(totalCount / expectedTotal);
      }
    } while (startKey != null && (total == null || totalCount < total));
    print("Imported $totalCount entries");
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
