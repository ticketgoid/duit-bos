import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/database_helper.dart';
import '../models/category_model.dart';

final categoryProvider =
FutureProvider.family<List<CategoryModel>, String>((ref, type) async {
  return await DatabaseHelper.instance.getCategoriesByType(type);
});
