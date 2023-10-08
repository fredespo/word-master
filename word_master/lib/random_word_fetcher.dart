import 'dart:math';

import 'package:realm/realm.dart';

import 'dictionary_entry.dart';

class RandomWordFetcher {
  static List<String> getRandomWords(Realm db, String dictionaryId, int count) {
    List<String> all = [];
    var entries =
        db.all<DictionaryEntry>().query("dictionaryId = '$dictionaryId'");
    for (var entry in entries) {
      all.add(entry.wordOrPhrase);
    }
    all.shuffle();
    return all.sublist(0, min(count, all.length));
  }
}
