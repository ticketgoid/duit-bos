import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/database_helper.dart';
import '../models/category_model.dart';

// Provider existing — tidak diubah agar expense_screen & income_screen tidak error
final categoryProvider =
FutureProvider.family<List<CategoryModel>, String>((ref, type) async {
  return await DatabaseHelper.instance.getCategoriesByType(type);
});

// Provider baru untuk settings (semua kategori tanpa filter)
final allCategoriesProvider = FutureProvider<List<CategoryModel>>((ref) async {
  return await DatabaseHelper.instance.getAllCategories();
});

// Notifier untuk CRUD kategori
class CategoryNotifier extends StateNotifier<AsyncValue<void>> {
  final Ref _ref;
  CategoryNotifier(this._ref) : super(const AsyncValue.data(null));

  Future<void> addCategory(CategoryModel category) async {
    state = const AsyncValue.loading();
    try {
      await DatabaseHelper.instance.insertCategory(category);
      _invalidate();
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> updateCategory(CategoryModel category) async {
    state = const AsyncValue.loading();
    try {
      await DatabaseHelper.instance.updateCategory(category);
      _invalidate();
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> deleteCategory(String id) async {
    state = const AsyncValue.loading();
    try {
      await DatabaseHelper.instance.deleteCategory(id);
      _invalidate();
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  void _invalidate() {
    _ref.invalidate(allCategoriesProvider);
    _ref.invalidate(categoryProvider);
  }
}

final categoryNotifierProvider =
StateNotifierProvider<CategoryNotifier, AsyncValue<void>>(
        (ref) => CategoryNotifier(ref));
