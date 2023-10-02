import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:realm/realm.dart';

import 'dictionary_entry.dart';

class Definitions extends StatelessWidget {
  final String? wordOrPhrase;
  final String? dictionaryId;
  final DictionaryEntry? entry;
  final Realm? db;

  const Definitions({
    super.key,
    this.entry,
    this.wordOrPhrase,
    this.dictionaryId,
    this.db,
  }) : assert(
          (db != null && wordOrPhrase != null && dictionaryId != null) ||
              entry != null,
          'Either wordOrPhrase and dictionaryId must not be null or entry must not be null',
        );

  @override
  Widget build(BuildContext context) {
    DictionaryEntry dictionaryEntry;
    if (entry == null) {
      try {
        dictionaryEntry = db!
            .all<DictionaryEntry>()
            .query("dictionaryId == '$dictionaryId'")
            .query("wordOrPhrase == \$0", [wordOrPhrase!]).first;
      } catch (e) {
        return const Text('No definitions found');
      }
    } else {
      dictionaryEntry = entry!;
    }

    String definitions = dictionaryEntry.definitions;
    Map<String, dynamic> jsonMap = jsonDecode(definitions);
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(25, 0, 20, 30),
        child: Column(children: [
          Text(
            wordOrPhrase ?? dictionaryEntry.wordOrPhrase,
            style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 20),
          ),
          const SizedBox(height: 10),
          ...jsonMap.keys.map((key) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: double.infinity,
                  child: Text(
                    key,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                ...List<Widget>.generate(
                  jsonMap[key].length,
                  (index) => Text('${index + 1}. ${jsonMap[key][index]}'),
                ),
              ],
            );
          }).toList(),
        ]),
      ),
    );
  }
}
