enum CategoryType { income, expense, both }

class CategoryModel {
  final String id;
  final String name;
  final String emoji;
  final CategoryType type;

  CategoryModel({
    required this.id,
    required this.name,
    required this.emoji,
    required this.type,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'emoji': emoji,
      'type': type.name,
    };
  }

  factory CategoryModel.fromMap(Map<String, dynamic> map) {
    return CategoryModel(
      id: map['id'],
      name: map['name'],
      emoji: map['emoji'],
      type: CategoryType.values.byName(map['type']),
    );
  }
}
