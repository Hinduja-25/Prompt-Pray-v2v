import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:she_defends_app/core/theme/app_theme.dart';

// ---------------------------------------------------------------------------
// Models
// ---------------------------------------------------------------------------

enum MedFrequency { daily, twiceDaily, weekly, asNeeded }

enum RefillStatus { ok, low, empty }

class MedicationV2 {
  final String id;
  final String name;
  final String dosage;
  final String unit; // mg, ml, tablet, etc.
  final List<String> scheduledTimes; // e.g. ['08:00', '20:00']
  final MedFrequency frequency;
  final String startDate;
  final String? endDate;
  final int totalPills;
  final int remainingPills;
  final bool isTakenToday;
  final bool reminderEnabled;
  final String color; // hex for UI

  const MedicationV2({
    required this.id,
    required this.name,
    required this.dosage,
    required this.unit,
    required this.scheduledTimes,
    required this.frequency,
    required this.startDate,
    this.endDate,
    required this.totalPills,
    required this.remainingPills,
    required this.isTakenToday,
    required this.reminderEnabled,
    required this.color,
  });

  RefillStatus get refillStatus {
    if (remainingPills == 0) return RefillStatus.empty;
    if (remainingPills <= 5) return RefillStatus.low;
    return RefillStatus.ok;
  }

  double get refillProgress =>
      totalPills == 0 ? 0 : remainingPills / totalPills;

  MedicationV2 copyWith({
    bool? isTakenToday,
    int? remainingPills,
    bool? reminderEnabled,
  }) =>
      MedicationV2(
        id: id,
        name: name,
        dosage: dosage,
        unit: unit,
        scheduledTimes: scheduledTimes,
        frequency: frequency,
        startDate: startDate,
        endDate: endDate,
        totalPills: totalPills,
        remainingPills: remainingPills ?? this.remainingPills,
        isTakenToday: isTakenToday ?? this.isTakenToday,
        reminderEnabled: reminderEnabled ?? this.reminderEnabled,
        color: color,
      );
}

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------

class MedManagerState {
  final List<MedicationV2> medications;
  final int selectedTab; // 0=Today, 1=All, 2=History
  final bool showAddForm;

  const MedManagerState({
    this.medications = const [],
    this.selectedTab = 0,
    this.showAddForm = false,
  });

  MedManagerState copyWith({
    List<MedicationV2>? medications,
    int? selectedTab,
    bool? showAddForm,
  }) =>
      MedManagerState(
        medications: medications ?? this.medications,
        selectedTab: selectedTab ?? this.selectedTab,
        showAddForm: showAddForm ?? this.showAddForm,
      );

  List<MedicationV2> get todayMeds =>
      medications.where((m) => m.frequency != MedFrequency.asNeeded).toList();

  int get takenCount => todayMeds.where((m) => m.isTakenToday).length;
  int get totalCount => todayMeds.length;
  double get adherence => totalCount == 0 ? 1.0 : takenCount / totalCount;

  List<MedicationV2> get lowRefill =>
      medications.where((m) => m.refillStatus != RefillStatus.ok).toList();
}

class MedManagerNotifier extends StateNotifier<MedManagerState> {
  MedManagerNotifier()
      : super(MedManagerState(
          medications: _defaultMeds,
        ));

  static final List<MedicationV2> _defaultMeds = [
    MedicationV2(
      id: '1',
      name: 'Vitamin D3',
      dosage: '1000',
      unit: 'IU',
      scheduledTimes: ['09:00 AM'],
      frequency: MedFrequency.daily,
      startDate: '2024-01-01',
      totalPills: 30,
      remainingPills: 22,
      isTakenToday: true,
      reminderEnabled: true,
      color: '#F59E0B',
    ),
    MedicationV2(
      id: '2',
      name: 'Iron Supplement',
      dosage: '65',
      unit: 'mg',
      scheduledTimes: ['08:00 PM'],
      frequency: MedFrequency.daily,
      startDate: '2024-01-01',
      totalPills: 30,
      remainingPills: 3,
      isTakenToday: false,
      reminderEnabled: true,
      color: '#EF4444',
    ),
    MedicationV2(
      id: '3',
      name: 'Omega-3',
      dosage: '1000',
      unit: 'mg',
      scheduledTimes: ['08:00 AM', '08:00 PM'],
      frequency: MedFrequency.twiceDaily,
      startDate: '2024-02-01',
      totalPills: 60,
      remainingPills: 45,
      isTakenToday: false,
      reminderEnabled: false,
      color: '#10B981',
    ),
    MedicationV2(
      id: '4',
      name: 'Paracetamol',
      dosage: '500',
      unit: 'mg',
      scheduledTimes: [],
      frequency: MedFrequency.asNeeded,
      startDate: '2024-01-01',
      totalPills: 20,
      remainingPills: 0,
      isTakenToday: false,
      reminderEnabled: false,
      color: '#6366F1',
    ),
  ];

  void markTaken(String id) {
    state = state.copyWith(
      medications: state.medications.map((m) {
        if (m.id == id) {
          final newRemaining = (m.remainingPills - 1).clamp(0, m.totalPills);
          return m.copyWith(isTakenToday: true, remainingPills: newRemaining);
        }
        return m;
      }).toList(),
    );
  }

  void toggleReminder(String id) {
    state = state.copyWith(
      medications: state.medications.map((m) {
        if (m.id == id) return m.copyWith(reminderEnabled: !m.reminderEnabled);
        return m;
      }).toList(),
    );
  }

  void addMedication(MedicationV2 med) {
    state = state.copyWith(medications: [...state.medications, med]);
  }

  void deleteMedication(String id) {
    state = state.copyWith(
      medications: state.medications.where((m) => m.id != id).toList(),
    );
  }

  void setTab(int tab) => state = state.copyWith(selectedTab: tab);
}

final medManagerProvider =
    StateNotifierProvider.autoDispose<MedManagerNotifier, MedManagerState>(
  (ref) => MedManagerNotifier(),
);

// ---------------------------------------------------------------------------
// Screen
// ---------------------------------------------------------------------------

class MedicationManagerScreen extends ConsumerWidget {
  const MedicationManagerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(medManagerProvider);
    final notifier = ref.read(medManagerProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.primary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Medication Manager',
          style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_rounded, color: AppColors.primary, size: 28),
            onPressed: () => _showAddMedSheet(context, ref),
          ),
        ],
      ),
      body: Column(
        children: [
          // Today's adherence header
          _AdherenceHeader(state: state),

          // Refill alerts
          if (state.lowRefill.isNotEmpty) _RefillAlerts(meds: state.lowRefill),

          // Tab row
          _TabRow(selected: state.selectedTab, onSelect: notifier.setTab),

          // Content
          Expanded(
            child: _buildTabContent(context, ref, state, notifier),
          ),
        ],
      ),
    );
  }

  Widget _buildTabContent(
    BuildContext context,
    WidgetRef ref,
    MedManagerState state,
    MedManagerNotifier notifier,
  ) {
    switch (state.selectedTab) {
      case 0:
        return _TodayTab(state: state, notifier: notifier);
      case 1:
        return _AllMedsTab(state: state, notifier: notifier, onAdd: () => _showAddMedSheet(context, ref));
      case 2:
        return _MedHistoryTab(meds: state.medications);
      default:
        return const SizedBox.shrink();
    }
  }

  void _showAddMedSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddMedSheet(
        onAdd: (med) => ref.read(medManagerProvider.notifier).addMedication(med),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Adherence Header
// ---------------------------------------------------------------------------

class _AdherenceHeader extends StatelessWidget {
  final MedManagerState state;

  const _AdherenceHeader({required this.state});

  @override
  Widget build(BuildContext context) {
    final pct = (state.adherence * 100).toInt();

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2D0C57), Color(0xFF4C1D95)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2D0C57).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Today's Adherence",
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
                const SizedBox(height: 4),
                Text(
                  '${state.takenCount} / ${state.totalCount} taken',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: state.adherence,
                    backgroundColor: Colors.white.withOpacity(0.2),
                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                    minHeight: 6,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 20),
          Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '$pct%',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Text(
                  'Done',
                  style: TextStyle(color: Colors.white70, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Refill Alerts
// ---------------------------------------------------------------------------

class _RefillAlerts extends StatelessWidget {
  final List<MedicationV2> meds;

  const _RefillAlerts({required this.meds});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF5F5),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.emergency.withOpacity(0.25)),
      ),
      child: Row(
        children: [
          const Icon(Icons.medication_outlined, color: AppColors.emergency, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Refill Needed',
                  style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.emergency, fontSize: 13),
                ),
                Text(
                  meds.map((m) => m.name).join(', '),
                  style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Tab Row
// ---------------------------------------------------------------------------

class _TabRow extends StatelessWidget {
  final int selected;
  final ValueChanged<int> onSelect;

  const _TabRow({required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    const tabs = ['Today', 'All Meds', 'History'];
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Row(
        children: tabs.asMap().entries.map((e) {
          final isSelected = e.key == selected;
          return Expanded(
            child: GestureDetector(
              onTap: () => onSelect(e.key),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                padding: const EdgeInsets.symmetric(vertical: 9),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : AppColors.lightGray,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  e.value,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isSelected ? Colors.white : AppColors.textMuted,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Today Tab
// ---------------------------------------------------------------------------

class _TodayTab extends StatelessWidget {
  final MedManagerState state;
  final MedManagerNotifier notifier;

  const _TodayTab({required this.state, required this.notifier});

  @override
  Widget build(BuildContext context) {
    final meds = state.todayMeds;
    if (meds.isEmpty) {
      return _emptyToday();
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const _ListHeader(label: 'Scheduled for today'),
        const SizedBox(height: 10),
        ...meds.map((m) => _TodayMedCard(med: m, notifier: notifier)),
        const SizedBox(height: 20),
        // Daily schedule timeline
        const _ListHeader(label: 'Daily Schedule'),
        const SizedBox(height: 10),
        _DailySchedule(meds: meds),
      ],
    );
  }

  Widget _emptyToday() => const Center(
        child: Text('No medications scheduled today.',
            style: TextStyle(color: AppColors.textMuted)),
      );
}

class _TodayMedCard extends StatelessWidget {
  final MedicationV2 med;
  final MedManagerNotifier notifier;

  const _TodayMedCard({required this.med, required this.notifier});

  Color get _baseColor {
    try {
      final hex = med.color.replaceAll('#', '');
      return Color(int.parse('FF$hex', radix: 16));
    } catch (_) {
      return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: med.isTakenToday ? AppColors.success.withOpacity(0.3) : const Color(0xFFE5E7EB),
        ),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 3)),
        ],
      ),
      child: Row(
        children: [
          // Color dot + icon
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: _baseColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(Icons.medication_rounded, color: _baseColor, size: 26),
          ),
          const SizedBox(width: 14),

          // Name + dosage + time
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  med.name,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textDark),
                ),
                const SizedBox(height: 2),
                Text(
                  '${med.dosage} ${med.unit}  •  ${med.scheduledTimes.join(', ')}',
                  style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                ),
                const SizedBox(height: 6),
                // Refill bar
                _RefillBar(med: med),
              ],
            ),
          ),
          const SizedBox(width: 12),

          // Take button / checkmark
          GestureDetector(
            onTap: med.isTakenToday ? null : () => notifier.markTaken(med.id),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: med.isTakenToday ? AppColors.success : AppColors.primary,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    med.isTakenToday ? Icons.check_rounded : Icons.medication_liquid_rounded,
                    color: Colors.white,
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    med.isTakenToday ? 'Taken' : 'Take',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RefillBar extends StatelessWidget {
  final MedicationV2 med;

  const _RefillBar({required this.med});

  Color get _color {
    switch (med.refillStatus) {
      case RefillStatus.empty:
        return AppColors.emergency;
      case RefillStatus.low:
        return AppColors.warning;
      default:
        return AppColors.success;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: med.refillProgress,
              backgroundColor: const Color(0xFFE5E7EB),
              valueColor: AlwaysStoppedAnimation<Color>(_color),
              minHeight: 4,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '${med.remainingPills} left',
          style: TextStyle(color: _color, fontSize: 11, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Daily Schedule Timeline
// ---------------------------------------------------------------------------

class _DailySchedule extends StatelessWidget {
  final List<MedicationV2> meds;

  const _DailySchedule({required this.meds});

  @override
  Widget build(BuildContext context) {
    // Collect all time slots
    final slots = <String, List<MedicationV2>>{};
    for (final med in meds) {
      for (final time in med.scheduledTimes) {
        slots.putIfAbsent(time, () => []).add(med);
      }
    }
    final sorted = slots.keys.toList()..sort();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        children: sorted.asMap().entries.map((e) {
          final isLast = e.key == sorted.length - 1;
          final time = e.value;
          final medsAtTime = slots[time]!;
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 70,
                child: Text(
                  time,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primary),
                ),
              ),
              Column(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    margin: const EdgeInsets.only(top: 4),
                    decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                  ),
                  if (!isLast)
                    Container(width: 2, height: 40, color: AppColors.lavender),
                ],
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: medsAtTime
                        .map((m) => Text(
                              '${m.name} — ${m.dosage} ${m.unit}',
                              style: const TextStyle(color: AppColors.textDark, fontSize: 13, height: 1.5),
                            ))
                        .toList(),
                  ),
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// All Meds Tab
// ---------------------------------------------------------------------------

class _AllMedsTab extends StatelessWidget {
  final MedManagerState state;
  final MedManagerNotifier notifier;
  final VoidCallback onAdd;

  const _AllMedsTab({required this.state, required this.notifier, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    final meds = state.medications;
    if (meds.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.medication_outlined, color: AppColors.lavender, size: 64),
            const SizedBox(height: 12),
            const Text('No medications added', style: TextStyle(color: AppColors.textMuted)),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add Medication'),
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: meds
          .map((m) => _AllMedCard(med: m, notifier: notifier))
          .toList(),
    );
  }
}

class _AllMedCard extends StatelessWidget {
  final MedicationV2 med;
  final MedManagerNotifier notifier;

  const _AllMedCard({required this.med, required this.notifier});

  Color get _baseColor {
    try {
      final hex = med.color.replaceAll('#', '');
      return Color(int.parse('FF$hex', radix: 16));
    } catch (_) {
      return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _baseColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.medication_rounded, color: _baseColor, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(med.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    Text(
                      '${med.dosage} ${med.unit}  •  ${_freqLabel(med.frequency)}',
                      style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                    ),
                  ],
                ),
              ),
              // Reminder toggle
              GestureDetector(
                onTap: () => notifier.toggleReminder(med.id),
                child: Icon(
                  med.reminderEnabled ? Icons.notifications_active_rounded : Icons.notifications_off_rounded,
                  color: med.reminderEnabled ? AppColors.primary : AppColors.textMuted,
                  size: 22,
                ),
              ),
              const SizedBox(width: 8),
              // Delete
              GestureDetector(
                onTap: () => _confirmDelete(context, med, notifier),
                child: const Icon(Icons.delete_outline_rounded, color: AppColors.textMuted, size: 22),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Refill
          Row(
            children: [
              const Text('Refill:', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
              const SizedBox(width: 8),
              Expanded(child: _RefillBar(med: med)),
            ],
          ),
          if (med.scheduledTimes.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              children: med.scheduledTimes
                  .map((t) => Container(
                        margin: const EdgeInsets.only(right: 6),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.lavender,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '⏰ $t',
                          style: const TextStyle(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.w600),
                        ),
                      ))
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }

  String _freqLabel(MedFrequency f) {
    switch (f) {
      case MedFrequency.daily: return 'Once daily';
      case MedFrequency.twiceDaily: return 'Twice daily';
      case MedFrequency.weekly: return 'Once a week';
      case MedFrequency.asNeeded: return 'As needed';
    }
  }

  void _confirmDelete(BuildContext context, MedicationV2 med, MedManagerNotifier notifier) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Remove ${med.name}?'),
        content: const Text('This medication will be removed from your list.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              notifier.deleteMedication(med.id);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.emergency),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// History Tab
// ---------------------------------------------------------------------------

class _MedHistoryTab extends StatelessWidget {
  final List<MedicationV2> meds;

  const _MedHistoryTab({required this.meds});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const _ListHeader(label: 'Medication adherence this week'),
        const SizedBox(height: 12),
        ...meds.map((m) => _MedHistoryCard(med: m)),
      ],
    );
  }
}

class _MedHistoryCard extends StatelessWidget {
  final MedicationV2 med;

  const _MedHistoryCard({required this.med});

  @override
  Widget build(BuildContext context) {
    // Mock: 7 days, randomly taken
    final mockHistory = List.generate(7, (i) => i % 2 == 0 || i == 5);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(med.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textDark)),
          const SizedBox(height: 4),
          Text('${med.dosage} ${med.unit}', style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
          const SizedBox(height: 10),
          Row(
            children: List.generate(7, (i) {
              const days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
              final taken = mockHistory[i];
              return Expanded(
                child: Column(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: taken ? AppColors.success : const Color(0xFFE5E7EB),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        taken ? Icons.check_rounded : Icons.close_rounded,
                        color: taken ? Colors.white : AppColors.textMuted,
                        size: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(days[i], style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Add Medication Bottom Sheet
// ---------------------------------------------------------------------------

class _AddMedSheet extends StatefulWidget {
  final ValueChanged<MedicationV2> onAdd;

  const _AddMedSheet({required this.onAdd});

  @override
  State<_AddMedSheet> createState() => _AddMedSheetState();
}

class _AddMedSheetState extends State<_AddMedSheet> {
  final _nameCtrl = TextEditingController();
  final _dosageCtrl = TextEditingController();
  final _pillsCtrl = TextEditingController();
  String _unit = 'mg';
  MedFrequency _frequency = MedFrequency.daily;
  final List<String> _times = ['08:00 AM'];
  bool _reminder = true;

  final _units = ['mg', 'ml', 'IU', 'tablet', 'capsule'];

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      builder: (_, scrollCtrl) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(color: const Color(0xFFE5E7EB), borderRadius: BorderRadius.circular(2)),
            ),
            Expanded(
              child: ListView(
                controller: scrollCtrl,
                padding: const EdgeInsets.all(24),
                children: [
                  const Text(
                    'Add Medication',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.primary),
                  ),
                  const SizedBox(height: 20),

                  _FormLabel(label: 'Medication Name'),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _nameCtrl,
                    decoration: const InputDecoration(hintText: 'e.g., Vitamin D3'),
                  ),
                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _FormLabel(label: 'Dosage'),
                            const SizedBox(height: 8),
                            TextField(
                              controller: _dosageCtrl,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(hintText: '500'),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _FormLabel(label: 'Unit'),
                            const SizedBox(height: 8),
                            DropdownButtonFormField<String>(
                              value: _unit,
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: AppColors.lightGray,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                              items: _units.map((u) => DropdownMenuItem(value: u, child: Text(u))).toList(),
                              onChanged: (v) => setState(() => _unit = v ?? 'mg'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  _FormLabel(label: 'Frequency'),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<MedFrequency>(
                    value: _frequency,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: AppColors.lightGray,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    items: const [
                      DropdownMenuItem(value: MedFrequency.daily, child: Text('Once daily')),
                      DropdownMenuItem(value: MedFrequency.twiceDaily, child: Text('Twice daily')),
                      DropdownMenuItem(value: MedFrequency.weekly, child: Text('Once a week')),
                      DropdownMenuItem(value: MedFrequency.asNeeded, child: Text('As needed')),
                    ],
                    onChanged: (v) => setState(() => _frequency = v ?? MedFrequency.daily),
                  ),
                  const SizedBox(height: 16),

                  _FormLabel(label: 'Total Pills / Units'),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _pillsCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(hintText: '30'),
                  ),
                  const SizedBox(height: 16),

                  // Reminder toggle
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.lightGray,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.notifications_rounded, color: AppColors.primary, size: 20),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text('Enable Reminders', style: TextStyle(fontWeight: FontWeight.w600)),
                        ),
                        Switch(
                          value: _reminder,
                          onChanged: (v) => setState(() => _reminder = v),
                          activeColor: AppColors.primary,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _submit,
                      style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                      child: const Text('Add Medication'),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _submit() {
    if (_nameCtrl.text.trim().isEmpty) return;
    final pills = int.tryParse(_pillsCtrl.text.trim()) ?? 30;
    final med = MedicationV2(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: _nameCtrl.text.trim(),
      dosage: _dosageCtrl.text.trim().isEmpty ? '1' : _dosageCtrl.text.trim(),
      unit: _unit,
      scheduledTimes: _times,
      frequency: _frequency,
      startDate: DateTime.now().toIso8601String().split('T').first,
      totalPills: pills,
      remainingPills: pills,
      isTakenToday: false,
      reminderEnabled: _reminder,
      color: '#4C1D95',
    );
    widget.onAdd(med);
    Navigator.pop(context);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _dosageCtrl.dispose();
    _pillsCtrl.dispose();
    super.dispose();
  }
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

class _ListHeader extends StatelessWidget {
  final String label;

  const _ListHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textDark),
    );
  }
}

class _FormLabel extends StatelessWidget {
  final String label;

  const _FormLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.textDark));
  }
}
