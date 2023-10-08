import 'package:realm/realm.dart';

part 'word_collection.g.dart';

@RealmModel()
class _WordCollection {
  late String id;
  late String name;
  late DateTime createdOn;
  late int size;
}
