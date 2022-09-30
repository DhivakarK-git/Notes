import 'package:isar/isar.dart';

import '../models/Note.dart';

class IsarService {
  late Future<Isar> db;

  IsarService() {
    db = openDB();
  }

  Future<void> saveCourse(Note newNote) async {
    final isar = await db;
    isar.writeTxnSync<int>(() => isar.notes.putSync(newNote));
  }

  Future<List<Note>> getAllCourses() async {
    final isar = await db;
    return await isar.notes.where().findAll();
  }

  Stream<List<Note>> listenToCourses() async* {
    final isar = await db;
    yield* isar.notes.where().watch(fireImmediately: true);
  }

  Future<void> cleanDb() async {
    final isar = await db;
    await isar.writeTxn(() => isar.clear());
  }

  Future<Isar> openDB() async {
    if (Isar.instanceNames.isEmpty) {
      return await Isar.open(
        [NoteSchema],
        inspector: true,
      );
    }
    return Future.value(Isar.getInstance());
  }
}
