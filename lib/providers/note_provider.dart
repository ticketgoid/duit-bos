import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/database_helper.dart';
import '../models/note_model.dart';

final allNotesProvider = FutureProvider<List<NoteModel>>((ref) async {
  return await DatabaseHelper.instance.getAllNotes();
});

final pinnedNotesProvider = FutureProvider<List<NoteModel>>((ref) async {
  final all = await DatabaseHelper.instance.getAllNotes();
  // pinned dulu, lalu by createdAt desc, ambil maks 3
  final sorted = [...all.where((n) => n.isPinned),
    ...all.where((n) => !n.isPinned)];
  return sorted.take(3).toList();
});

class NoteNotifier extends StateNotifier<AsyncValue<void>> {
  final Ref _ref;
  NoteNotifier(this._ref) : super(const AsyncValue.data(null));

  Future<void> addNote(NoteModel note) async {
    state = const AsyncValue.loading();
    try {
      await DatabaseHelper.instance.insertNote(note);
      _invalidate();
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> updateNote(NoteModel note) async {
    state = const AsyncValue.loading();
    try {
      await DatabaseHelper.instance.updateNote(note);
      _invalidate();
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> deleteNote(String id) async {
    state = const AsyncValue.loading();
    try {
      await DatabaseHelper.instance.deleteNote(id);
      _invalidate();
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  void _invalidate() {
    _ref.invalidate(allNotesProvider);
    _ref.invalidate(pinnedNotesProvider);
  }
}

final noteNotifierProvider =
StateNotifierProvider<NoteNotifier, AsyncValue<void>>(
        (ref) => NoteNotifier(ref));
