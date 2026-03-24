import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import '../models/note_model.dart';
import '../providers/note_provider.dart';

final _notifPlugin = FlutterLocalNotificationsPlugin();
bool _notifInitialized = false;

Future<void> initNotifications() async {
  if (_notifInitialized) return;
  tz_data.initializeTimeZones();
  const android = AndroidInitializationSettings('@mipmap/ic_launcher');
  const ios = DarwinInitializationSettings();
  await _notifPlugin.initialize(
    const InitializationSettings(android: android, iOS: ios),
  );
  _notifInitialized = true;
}

Future<void> scheduleNoteNotifications(NoteModel note) async {
  await initNotifications();
  if (note.reminderDate == null ||
      note.reminderType == ReminderType.none) return;

  // Cancel existing notifications for this note
  await cancelNoteNotifications(note.id);

  final daysMap = {
    ReminderType.onDay: <int>[0],
    ReminderType.h3Daily: [3, 2, 1, 0],
    ReminderType.h5Daily: [5, 4, 3, 2, 1, 0],
    ReminderType.h7Daily: [7, 6, 5, 4, 3, 2, 1, 0],
  };

  final days = daysMap[note.reminderType] ?? [];
  final idBase = note.id.hashCode.abs();

  for (int i = 0; i < days.length; i++) {
    final d = days[i];
    final scheduledDate = note.reminderDate!.subtract(Duration(days: d));
    final tzDate = tz.TZDateTime.from(
      DateTime(scheduledDate.year, scheduledDate.month, scheduledDate.day, 9, 0),
      tz.local,
    );
    if (tzDate.isBefore(tz.TZDateTime.now(tz.local))) continue;

    final title = d == 0
        ? '⏰ Jatuh tempo hari ini!'
        : '🔔 Pengingat H-$d';
    final body = note.title +
        (note.amount > 0
            ? ' • Rp ${NumberFormat('#,###', 'id_ID').format(note.amount)}'
            : '');

    await _notifPlugin.zonedSchedule(
      idBase + i,
      title,
      body,
      tzDate,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'duit_bos_notes',
          'Catatan Keuangan',
          channelDescription: 'Pengingat catatan keuangan',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
      UILocalNotificationDateInterpretation.absoluteTime,
    );
  }
}

Future<void> cancelNoteNotifications(String noteId) async {
  await initNotifications();
  final idBase = noteId.hashCode.abs();
  for (int i = 0; i < 8; i++) {
    await _notifPlugin.cancel(idBase + i);
  }
}

class NotesScreen extends ConsumerWidget {
  const NotesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notesAsync = ref.watch(allNotesProvider);
    final fmt = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    return Scaffold(
      backgroundColor: const Color(0xFFF0E6FF),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
              child: Row(children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [BoxShadow(
                          color: Colors.black.withOpacity(0.06),
                          blurRadius: 6)],
                    ),
                    child: const Icon(Icons.arrow_back_ios_new,
                        size: 16, color: Color(0xFF5C4A6E)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text('📝 Catatan Keuangan',
                      style: GoogleFonts.nunito(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF5C4A6E),
                      )),
                ),
                GestureDetector(
                  onTap: () => _showNoteSheet(context, ref),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF5C4A6E),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.add, color: Colors.white, size: 20),
                  ),
                ),
              ]),
            ),

            const SizedBox(height: 16),

            Expanded(
              child: notesAsync.when(
                data: (notes) {
                  if (notes.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('📝', style: TextStyle(fontSize: 48)),
                          const SizedBox(height: 12),
                          Text('Belum ada catatan',
                              style: GoogleFonts.nunito(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF9B8AAE))),
                          const SizedBox(height: 8),
                          Text('Tap + untuk buat catatan baru',
                              style: GoogleFonts.nunito(
                                  fontSize: 13,
                                  color: const Color(0xFFCCBBDD))),
                        ],
                      ),
                    );
                  }

                  final pinned = notes.where((n) => n.isPinned).toList();
                  final unpinned = notes.where((n) => !n.isPinned).toList();
                  final sorted = [...pinned, ...unpinned];

                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                    itemCount: sorted.length,
                    itemBuilder: (_, i) =>
                        _NoteCard(
                          note: sorted[i],
                          fmt: fmt,
                          onEdit: () => _showNoteSheet(context, ref, note: sorted[i]),
                          onDelete: () => _confirmDelete(context, ref, sorted[i]),
                          onTogglePin: () =>
                              ref.read(noteNotifierProvider.notifier)
                                  .updateNote(sorted[i].copyWith(
                                  isPinned: !sorted[i].isPinned)),
                          onToggleCheck: () =>
                              ref.read(noteNotifierProvider.notifier)
                                  .updateNote(sorted[i].copyWith(
                                  isChecked: !sorted[i].isChecked)),
                          onPayNow: () => _handlePayNow(context, sorted[i]),
                        ),
                  );
                },
                loading: () =>
                const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Error: $e')),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handlePayNow(BuildContext context, NoteModel note) {
    // Navigasi ke expense via PageView — pop dulu lalu trigger swipe
    Navigator.pop(context, {'payNow': true, 'note': note});
  }

  Future<void> _confirmDelete(
      BuildContext context, WidgetRef ref, NoteModel note) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Hapus catatan?',
            style: GoogleFonts.nunito(
                fontWeight: FontWeight.w800,
                color: const Color(0xFF5C4A6E))),
        content: Text('Catatan "${note.title}" akan dihapus permanen.',
            style: GoogleFonts.nunito(
                fontSize: 13, color: const Color(0xFF9B8AAE))),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Batal',
                style: GoogleFonts.nunito(color: const Color(0xFF9B8AAE))),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: Text('Hapus',
                style: GoogleFonts.nunito(
                    color: Colors.white, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await cancelNoteNotifications(note.id);
      await ref.read(noteNotifierProvider.notifier).deleteNote(note.id);
    }
  }

  void _showNoteSheet(BuildContext context, WidgetRef ref,
      {NoteModel? note}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _NoteFormSheet(
        existing: note,
        onSave: (newNote) async {
          if (note == null) {
            await ref.read(noteNotifierProvider.notifier).addNote(newNote);
          } else {
            await ref.read(noteNotifierProvider.notifier).updateNote(newNote);
          }
          await scheduleNoteNotifications(newNote);
          if (ctx.mounted) Navigator.pop(ctx);
        },
      ),
    );
  }
}

// ─── Note Card ────────────────────────────────────────────────

class _NoteCard extends StatelessWidget {
  final NoteModel note;
  final NumberFormat fmt;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onTogglePin;
  final VoidCallback onToggleCheck;
  final VoidCallback onPayNow;

  const _NoteCard({
    required this.note,
    required this.fmt,
    required this.onEdit,
    required this.onDelete,
    required this.onTogglePin,
    required this.onToggleCheck,
    required this.onPayNow,
  });

  static const _labelColors = {
    NoteLabel.reminder: Color(0xFFFFD6E0),
    NoteLabel.budget: Color(0xFFB8F0C8),
    NoteLabel.plan: Color(0xFFD6E8FF),
    NoteLabel.other: Color(0xFFF0E6FF),
  };
  static const _labelNames = {
    NoteLabel.reminder: '🔔 Pengingat',
    NoteLabel.budget: '💰 Budget',
    NoteLabel.plan: '📋 Rencana',
    NoteLabel.other: '📌 Lainnya',
  };

  @override
  Widget build(BuildContext context) {
    final isOverdue = note.reminderDate != null &&
        note.reminderDate!.isBefore(DateTime.now()) &&
        !note.isChecked;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: isOverdue
            ? Border.all(color: Colors.redAccent.withOpacity(0.4), width: 1.5)
            : null,
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Row 1: label + pin + check
            Row(children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _labelColors[note.label],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(_labelNames[note.label]!,
                    style: GoogleFonts.nunito(
                        fontSize: 11, fontWeight: FontWeight.w700,
                        color: const Color(0xFF5C4A6E))),
              ),
              const Spacer(),
              if (note.isPinned)
                const Padding(
                  padding: EdgeInsets.only(right: 4),
                  child: Text('📌', style: TextStyle(fontSize: 14)),
                ),
              GestureDetector(
                onTap: onToggleCheck,
                child: Container(
                  width: 22, height: 22,
                  decoration: BoxDecoration(
                    color: note.isChecked
                        ? const Color(0xFF4CAF50)
                        : Colors.transparent,
                    border: Border.all(
                      color: note.isChecked
                          ? const Color(0xFF4CAF50)
                          : const Color(0xFFCCBBDD),
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: note.isChecked
                      ? const Icon(Icons.check, size: 14, color: Colors.white)
                      : null,
                ),
              ),
            ]),

            const SizedBox(height: 8),

            // Title
            Text(note.title,
                style: GoogleFonts.nunito(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: note.isChecked
                      ? const Color(0xFFCCBBDD)
                      : const Color(0xFF5C4A6E),
                  decoration: note.isChecked
                      ? TextDecoration.lineThrough
                      : null,
                )),

            if (note.content != null && note.content!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(note.content!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.nunito(
                      fontSize: 12, color: const Color(0xFF9B8AAE))),
            ],

            const SizedBox(height: 10),

            // Amount + reminder date
            Row(children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0E6FF),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(fmt.format(note.amount),
                    style: GoogleFonts.nunito(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF5C4A6E))),
              ),
              const SizedBox(width: 8),
              if (note.reminderDate != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isOverdue
                        ? const Color(0xFFFFD6E0)
                        : const Color(0xFFF0E6FF),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '📅 ${DateFormat('d MMM yyyy', 'id_ID').format(note.reminderDate!)}',
                    style: GoogleFonts.nunito(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: isOverdue
                            ? Colors.redAccent
                            : const Color(0xFF9B8AAE)),
                  ),
                ),
            ]),

            const SizedBox(height: 10),

            // Action buttons
            Row(children: [
              // Bayar Sekarang
              if (!note.isChecked)
                Expanded(
                  child: GestureDetector(
                    onTap: onPayNow,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF5C4A6E),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text('💸 Bayar Sekarang',
                            style: GoogleFonts.nunito(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            )),
                      ),
                    ),
                  ),
                ),
              if (!note.isChecked) const SizedBox(width: 8),
              // Edit
              GestureDetector(
                onTap: onEdit,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0E6FF),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.edit, size: 16,
                      color: Color(0xFF9B8AAE)),
                ),
              ),
              const SizedBox(width: 6),
              // Pin
              GestureDetector(
                onTap: onTogglePin,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: note.isPinned
                        ? const Color(0xFFFFD6E0)
                        : const Color(0xFFF0E6FF),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(note.isPinned ? '📌' : '📍',
                      style: const TextStyle(fontSize: 14)),
                ),
              ),
              const SizedBox(width: 6),
              // Delete
              GestureDetector(
                onTap: onDelete,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFD6E0),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.delete_outline,
                      size: 16, color: Colors.redAccent),
                ),
              ),
            ]),
          ],
        ),
      ),
    );
  }
}

// ─── Note Form Sheet ──────────────────────────────────────────

class _NoteFormSheet extends StatefulWidget {
  final NoteModel? existing;
  final Future<void> Function(NoteModel) onSave;

  const _NoteFormSheet({this.existing, required this.onSave});

  @override
  State<_NoteFormSheet> createState() => _NoteFormSheetState();
}

class _NoteFormSheetState extends State<_NoteFormSheet> {
  late final TextEditingController _titleCtrl;
  late final TextEditingController _contentCtrl;
  late final TextEditingController _amountCtrl;
  late NoteLabel _label;
  late ReminderType _reminderType;
  DateTime? _reminderDate;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _titleCtrl = TextEditingController(text: e?.title ?? '');
    _contentCtrl = TextEditingController(text: e?.content ?? '');
    _amountCtrl = TextEditingController(
        text: e != null && e.amount > 0 ? e.amount.toInt().toString() : '');
    _label = e?.label ?? NoteLabel.reminder;
    _reminderType = e?.reminderType ?? ReminderType.none;
    _reminderDate = e?.reminderDate;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _contentCtrl.dispose();
    _amountCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(
          20, 16, 20, MediaQuery.of(context).viewInsets.bottom + 24),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE0D0F0),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(widget.existing == null ? '📝 Catatan Baru' : 'Edit Catatan',
                style: GoogleFonts.nunito(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF5C4A6E))),
            const SizedBox(height: 16),

            // Judul
            _label2('Judul'),
            _field(_titleCtrl, 'Nama catatan...'),
            const SizedBox(height: 12),

            // Nominal (wajib)
            _label2('Nominal (wajib)'),
            _field(_amountCtrl, 'Rp 0', isNumber: true),
            const SizedBox(height: 12),

            // Catatan opsional
            _label2('Catatan (opsional)'),
            _field(_contentCtrl, 'Tulis detail...', maxLines: 3),
            const SizedBox(height: 12),

            // Label
            _label2('Label'),
            Wrap(
              spacing: 8,
              children: NoteLabel.values.map((l) {
                final names = {
                  NoteLabel.reminder: '🔔 Pengingat',
                  NoteLabel.budget: '💰 Budget',
                  NoteLabel.plan: '📋 Rencana',
                  NoteLabel.other: '📌 Lainnya',
                };
                return GestureDetector(
                  onTap: () => setState(() => _label = l),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _label == l
                          ? const Color(0xFF5C4A6E)
                          : const Color(0xFFF0E6FF),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(names[l]!,
                        style: GoogleFonts.nunito(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: _label == l
                              ? Colors.white
                              : const Color(0xFF9B8AAE),
                        )),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),

            // Tanggal jatuh tempo
            _label2('Tanggal Jatuh Tempo'),
            GestureDetector(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _reminderDate ?? DateTime.now(),
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
                );
                if (picked != null) setState(() => _reminderDate = picked);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0E6FF),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(children: [
                  const Text('📅', style: TextStyle(fontSize: 16)),
                  const SizedBox(width: 8),
                  Text(
                    _reminderDate != null
                        ? DateFormat('d MMMM yyyy', 'id_ID')
                        .format(_reminderDate!)
                        : 'Pilih tanggal...',
                    style: GoogleFonts.nunito(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: _reminderDate != null
                          ? const Color(0xFF5C4A6E)
                          : const Color(0xFFCCBBDD),
                    ),
                  ),
                ]),
              ),
            ),
            const SizedBox(height: 12),

            // Pengingat
            if (_reminderDate != null) ...[
              _label2('Pengingat'),
              Column(
                children: [
                  _reminderOption(ReminderType.none, '🔕 Tidak ada pengingat'),
                  _reminderOption(ReminderType.onDay, '🔔 Saat jatuh tempo saja'),
                  _reminderOption(ReminderType.h3Daily, '📅 Tiap hari mulai H-3'),
                  _reminderOption(ReminderType.h5Daily, '📅 Tiap hari mulai H-5'),
                  _reminderOption(ReminderType.h7Daily, '📅 Tiap hari mulai H-7'),
                ],
              ),
              const SizedBox(height: 12),
            ],

            // Simpan
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF5C4A6E),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: _saving
                    ? const SizedBox(
                    width: 20, height: 20,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2))
                    : Text('Simpan',
                    style: GoogleFonts.nunito(
                        fontSize: 15, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _reminderOption(ReminderType type, String label) {
    return GestureDetector(
      onTap: () => setState(() => _reminderType = type),
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: _reminderType == type
              ? const Color(0xFF5C4A6E)
              : const Color(0xFFF0E6FF),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(children: [
          Expanded(
            child: Text(label,
                style: GoogleFonts.nunito(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: _reminderType == type
                      ? Colors.white
                      : const Color(0xFF9B8AAE),
                )),
          ),
          if (_reminderType == type)
            const Icon(Icons.check, size: 16, color: Colors.white),
        ]),
      ),
    );
  }

  Widget _label2(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(text,
        style: GoogleFonts.nunito(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF9B8AAE))),
  );

  Widget _field(TextEditingController ctrl, String hint,
      {bool isNumber = false, int maxLines = 1}) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF0E6FF),
        borderRadius: BorderRadius.circular(14),
      ),
      child: TextField(
        controller: ctrl,
        maxLines: maxLines,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        style: GoogleFonts.nunito(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF5C4A6E)),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.nunito(color: const Color(0xFFCCBBDD)),
          border: InputBorder.none,
          contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }

  Future<void> _save() async {
    final title = _titleCtrl.text.trim();
    final amountStr = _amountCtrl.text.trim();
    if (title.isEmpty) return;
    if (amountStr.isEmpty) return;
    final amount = double.tryParse(
        amountStr.replaceAll('.', '').replaceAll(',', ''));
    if (amount == null || amount <= 0) return;

    if (!mounted) return;
    setState(() => _saving = true);

    final note = NoteModel(
      id: widget.existing?.id ?? const Uuid().v4(),
      title: title,
      amount: amount,
      content: _contentCtrl.text.trim().isEmpty
          ? null
          : _contentCtrl.text.trim(),
      label: _label,
      isPinned: widget.existing?.isPinned ?? false,
      isChecked: widget.existing?.isChecked ?? false,
      reminderDate: _reminderDate,
      reminderType:
      _reminderDate != null ? _reminderType : ReminderType.none,
      createdAt: widget.existing?.createdAt ?? DateTime.now(),
    );

    await widget.onSave(note);

    // onSave sudah pop sheet, jadi cek mounted dulu
    if (mounted) setState(() => _saving = false);
  }
}