enum NoteLabel { reminder, budget, plan, other }
enum ReminderType { none, onDay, h3Daily, h5Daily, h7Daily }

class NoteModel {
  final String id;
  final String title;
  final double amount;
  final String? content;
  final NoteLabel label;
  final bool isPinned;
  final bool isChecked;
  final DateTime? reminderDate;
  final ReminderType reminderType;
  final DateTime createdAt;

  NoteModel({
    required this.id,
    required this.title,
    required this.amount,
    this.content,
    required this.label,
    required this.isPinned,
    required this.isChecked,
    this.reminderDate,
    required this.reminderType,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'title': title,
    'amount': amount,
    'content': content,
    'label': label.name,
    'isPinned': isPinned ? 1 : 0,
    'isChecked': isChecked ? 1 : 0,
    'reminderDate': reminderDate?.toIso8601String(),
    'reminderType': reminderType.name,
    'createdAt': createdAt.toIso8601String(),
  };

  factory NoteModel.fromMap(Map<String, dynamic> m) => NoteModel(
    id: m['id'],
    title: m['title'],
    amount: (m['amount'] as num).toDouble(),
    content: m['content'],
    label: NoteLabel.values.byName(m['label']),
    isPinned: m['isPinned'] == 1,
    isChecked: m['isChecked'] == 1,
    reminderDate: m['reminderDate'] != null
        ? DateTime.parse(m['reminderDate'])
        : null,
    reminderType: ReminderType.values.byName(m['reminderType']),
    createdAt: DateTime.parse(m['createdAt']),
  );

  NoteModel copyWith({
    String? title,
    double? amount,
    String? content,
    NoteLabel? label,
    bool? isPinned,
    bool? isChecked,
    DateTime? reminderDate,
    ReminderType? reminderType,
  }) =>
      NoteModel(
        id: id,
        title: title ?? this.title,
        amount: amount ?? this.amount,
        content: content ?? this.content,
        label: label ?? this.label,
        isPinned: isPinned ?? this.isPinned,
        isChecked: isChecked ?? this.isChecked,
        reminderDate: reminderDate ?? this.reminderDate,
        reminderType: reminderType ?? this.reminderType,
        createdAt: createdAt,
      );
}