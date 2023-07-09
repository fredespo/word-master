import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:realm/realm.dart';
import 'package:word_master/dictionary_data_importer.dart';
import 'package:word_master/word_collection_creator.dart';
import 'package:word_master/word_table.dart';

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
        appBar: AppBar(
          title: Text('Word Master'),
        ),
        body: Center(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              DictionaryDataImporter(db: db),
              const SizedBox(height: 20),
              _buildReadButton(),
            ],
          ),
        ),
        floatingActionButton: Padding(
          padding: const EdgeInsets.fromLTRB(0, 0, 30, 30),
          child: CreateWordTableButton(db: db),
        ),
      ),
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

class CreateWordTableButton extends StatelessWidget {
  final Realm db;

  const CreateWordTableButton({super.key, required this.db});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      backgroundColor: Colors.orange,
      onPressed: () {
        // show dialog for creating a new word collection
        showDialog(
          context: context,
          builder: (context) {
            return WordCollectionCreator(
              onCreate: (String name, int wordCount) {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => WordTable(
                        entries: db.all<DictionaryEntry>(),
                        db: db,
                      ),
                    ));
              },
            );
          },
        );
      },
      child: const Icon(Icons.add),
    );
  }
}
