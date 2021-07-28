import 'package:hive/hive.dart';

part 'note.g.dart';

@HiveType(typeId: 0)
class Note {
  @HiveField(0)
  final String title;

  @HiveField(1)
  final String body;

  @HiveField(2)
  final DateTime created;

  Note(this.title, this.body, this.created);

  Future<void> addCard() async {
    final noteBox = Hive.box('notes');
    noteBox.add(this);
  }

  Future<void> editCard(int index) async {
    final noteBox = Hive.box('notes');
    noteBox.putAt(index, this);
  }

  Future<void> removeCard(int index) async {
    final noteBox = Hive.box('notes');
    noteBox.deleteAt(index);
  }
}
