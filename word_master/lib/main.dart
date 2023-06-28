import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:realm/realm.dart';

import 'dictionary_entry.dart';

void main() {
  runApp(MainApp());
}

class MainApp extends StatelessWidget {
  final Realm db = Realm(Configuration.local([
    DictionaryEntry.schema,
  ]));

  MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildImportButton(),
              const SizedBox(height: 20),
              _buildReadButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImportButton() {
    return ElevatedButton(
      onPressed: () async {
        String functionUrl =
            "https://rgnbhyf5h63zg2krd6mxtr7cga0qlnse.lambda-url.us-east-1.on.aws/";
        http.Response response = await http.get(Uri.parse(functionUrl));
        var entries = jsonDecode(response.body);
        for (var entry in entries.entries) {
          var wordOrPhrase = entry.key;
          var definitions = entry.value;
          db.write(() {
            db.add(
              DictionaryEntry(wordOrPhrase, json.encode(definitions)),
              update: true,
            );
          });
        }
        print("Imported ${entries.length} entries");
      },
      child: const Text('Import'),
    );
  }

  Widget _buildReadButton() {
    return ElevatedButton(
      onPressed: () async {
        var all = db.all<DictionaryEntry>();
        for (var entry in all) {
          print(entry.wordOrPhrase);
          print(entry.definitions);
        }
      },
      child: const Text('Read'),
    );
  }
}
