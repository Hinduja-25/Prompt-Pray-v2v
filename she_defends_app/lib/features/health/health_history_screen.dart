import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:she_defends_app/core/theme/app_theme.dart';
import 'package:she_defends_app/core/network/api_client.dart';

// ---------------------------------------------------------------------------
// Models
// ---------------------------------------------------------------------------

class HealthLog {
  final String id;
  final String symptoms;
  final String urgency;
  final String timestamp;
  final List<String> conditions;
  final List<String> suggestions;
  final List<String> warnings;
  final String disclaimer;

  const HealthLog({
    required this.id,
    required this.symptoms,
    required this.urgency,
    required this.timestamp,
    required this.conditions,
    required this.suggestions,
    required this.warnings,
    required this.disclaimer,
  });

  factory HealthLog.fromJson(Map<String, dynamic> json) {
    final analysis = json['analysis'] as Map<String, dynamic>? ?? {};
    return HealthLog(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      symptoms: json['symptoms'] as String? ?? '',
      urgency: analysis['urgency_level'] as String? ?? 'Low',
      timestamp: json['timestamp'] as String? ?? '',
      conditions: (analysis['possible_conditions'] as List?)?.cast<String>() ?? [],
      suggestions: (analysis['suggestions'] as List?)?.cast<String>() ?? [],
      warnings: (analysis['warning_signs'] as List?)?.cast<String>() ?? [],
      disclaimer: analysis['disclaimer'] as String? ?? '',
    );
  }

  String get displayDate {
    try {
      final dt = DateTime.parse(timestamp);
      const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
    } catch (_) {
      return timestamp.split('T').first;
    }
  }

  String get displayTime {
    try {
      final dt = DateTime.parse(timestamp);
      final h = dt.hour.toString().padLeft(2, '0');
      final m = dt.minute.toString().padLeft(2, '0');
      return '$h:$m';
    } catch (_) {
      return '';
    }
  }
}

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------

enum HistoryFilter { all, high, medium, low }

class HealthHistoryState {
  final List<HealthLog> logs;
  final bool isLoading;
  final HistoryFilter filter;
  final String? error;

  const HealthHistoryState({
    this.logs = const [],
    this.isLoading = false,
    this.filter = HistoryFilter.all,
    this.error,
  });

  HealthHistoryState copyWith({
    List<HealthLog>? logs,
    bool? isLoading,
    HistoryFilter? filter,
    String? error,
  }) =>
      HealthHistoryState(
        logs: logs ?? this.logs,
        isLoading: isLoading ?? this.isLoading,
        filter: filter ?? this.filter,
        error: error ?? this.error,
      );

  List<HealthLog> get filtered {
    if (filter == HistoryFilter.all) return logs;
    final urgency = filter.name[0].toUpperCase() + filter.name.substring(1);
    return logs.where((l) => l.urgency == urgency).toList();
  }
}

class HealthHistoryNotifier extends StateNotifier<HealthHistoryState> {
  HealthHistoryNotifier() : super(const HealthHistoryState()) {
    fetchHistory();
  }

  final _api = ApiClient();

  Future<void> fetchHistory() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _api.get('/health/history');
      if (response.statusCode == 200) {
        final list = response.data as List;
        final logs = list.map((e) => HealthLog.fromJson(e as Map<String, dynamic>)).toList();
        state = state.copyWith(logs: logs, isLoading: false);
      } else {
        state = state.copyWith(isLoading: false, logs: _mockLogs());
      }
    } catch (_) {
      state = state.copyWith(isLoading: false, logs: _mockLogs());
    }
  }

  void setFilter(HistoryFilter f) => state = state.copyWith(filter: f);

  List<HealthLog> _mockLogs() => [
        HealthLog(
          id: '1',
          symptoms: 'Headache on left side with slight nausea and fatigue',
          urgency: 'Low',
          timestamp: DateTime.now().subtract(const Duration(hours: 2)).toIso8601String(),
          conditions: ['Tension Headache', 'Dehydration', 'Migraine'],
          suggestions: ['Drink water', 'Rest in dark room', 'Cool compress'],
          warnings: ['Thunderclap pain', 'Stiff neck with fever'],
          disclaimer: 'This is not a medical diagnosis.',
        ),
        HealthLog(
          id: '2',
          symptoms: 'Body ache, chills, and a fever of about 101°F since yesterday evening',
          urgency: 'Medium',
          timestamp: DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
          conditions: ['Viral Fever', 'Influenza'],
          suggestions: ['Monitor temperature', 'Stay hydrated', 'Rest'],
          warnings: ['Fever > 103°F', 'Difficulty breathing'],
          disclaimer: 'This is not a medical diagnosis.',
        ),
        HealthLog(
          id: '3',
          symptoms: 'Severe chest pain and shortness of breath',
          urgency: 'High',
          timestamp: DateTime.now().subtract(const Duration(days: 3)).toIso8601String(),
          conditions: ['Cardiac Event', 'Panic Attack'],
          suggestions: ['Call emergency services', 'Sit upright'],
          warnings: ['Radiating arm pain', 'Loss of consciousness'],
          disclaimer: 'This is not a medical diagnosis. Seek immediate care.',
        ),
        HealthLog(
          id: '4',
          symptoms: 'Lower back pain and general tiredness for the past 3 days',
          urgency: 'Low',
          timestamp: DateTime.now().subtract(const Duration(days: 5)).toIso8601String(),
          conditions: ['Muscle Strain', 'Sedentary Fatigue'],
          suggestions: ['Light stretching', 'Warm compress', 'Short walks'],
          warnings: ['Numbness in legs', 'Persistent 2+ weeks'],
          disclaimer: 'This is not a medical diagnosis.',
        ),
      ];
}

final healthHistoryProvider =
    StateNotifierProvider.autoDispose<HealthHistoryNotifier, HealthHistoryState>(
  (ref) => HealthHistoryNotifier(),
);

// ---------------------------------------------------------------------------
// Screen
// ---------------------------------------------------------------------------

class HealthHistoryScreen extends ConsumerWidget {
  const HealthHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(healthHistoryProvider);
    final notifier = ref.read(healthHistoryProvider.notifier);

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
          'Health History',
          style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.primary),
            onPressed: notifier.fetchHistory,
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter bar
          _FilterBar(current: state.filter, onSelect: notifier.setFilter),

          // Summary stats
          if (state.logs.isNotEmpty)
            _StatsSummary(logs: state.logs),

          // List
          Expanded(
            child: state.isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2))
                : state.filtered.isEmpty
                    ? _EmptyState()
                    : _TimelineList(logs: state.filtered),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Filter Bar
// ---------------------------------------------------------------------------

class _FilterBar extends StatelessWidget {
  final HistoryFilter current;
  final ValueChanged<HistoryFilter> onSelect;

  const _FilterBar({required this.current, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Row(
        children: HistoryFilter.values.map((f) {
          final label = f == HistoryFilter.all
              ? 'All'
              : f.name[0].toUpperCase() + f.name.substring(1);
          final isSelected = f == current;
          final color = _urgencyColor(label);

          return Expanded(
            child: GestureDetector(
              onTap: () => onSelect(f),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? (f == HistoryFilter.all ? AppColors.primary : color)
                      : AppColors.lightGray,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isSelected ? Colors.white : AppColors.textMuted,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Color _urgencyColor(String urgency) {
    switch (urgency) {
      case 'High':
        return AppColors.emergency;
      case 'Medium':
        return AppColors.warning;
      case 'Low':
        return AppColors.success;
      default:
        return AppColors.primary;
    }
  }
}

// ---------------------------------------------------------------------------
// Stats Summary
// ---------------------------------------------------------------------------

class _StatsSummary extends StatelessWidget {
  final List<HealthLog> logs;

  const _StatsSummary({required this.logs});

  @override
  Widget build(BuildContext context) {
    final high = logs.where((l) => l.urgency == 'High').length;
    final medium = logs.where((l) => l.urgency == 'Medium').length;
    final low = logs.where((l) => l.urgency == 'Low').length;

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Row(
        children: [
          _StatChip(count: logs.length, label: 'Total', color: AppColors.primary),
          const SizedBox(width: 8),
          _StatChip(count: low, label: 'Low', color: AppColors.success),
          const SizedBox(width: 8),
          _StatChip(count: medium, label: 'Medium', color: AppColors.warning),
          const SizedBox(width: 8),
          _StatChip(count: high, label: 'High', color: AppColors.emergency),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final int count;
  final String label;
  final Color color;

  const _StatChip({required this.count, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(
              '$count',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color),
            ),
            Text(label, style: TextStyle(fontSize: 11, color: color.withOpacity(0.8))),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Timeline List
// ---------------------------------------------------------------------------

class _TimelineList extends StatelessWidget {
  final List<HealthLog> logs;

  const _TimelineList({required this.logs});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: logs.length,
      itemBuilder: (context, index) => _TimelineTile(
        log: logs[index],
        isLast: index == logs.length - 1,
        onTap: () => _showDetailSheet(context, logs[index]),
      ),
    );
  }

  void _showDetailSheet(BuildContext context, HealthLog log) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _DetailSheet(log: log),
    );
  }
}

// ---------------------------------------------------------------------------
// Timeline Tile
// ---------------------------------------------------------------------------

class _TimelineTile extends StatelessWidget {
  final HealthLog log;
  final bool isLast;
  final VoidCallback onTap;

  const _TimelineTile({required this.log, required this.isLast, required this.onTap});

  Color get _urgencyColor {
    switch (log.urgency) {
      case 'High':
        return AppColors.emergency;
      case 'Medium':
        return AppColors.warning;
      default:
        return AppColors.success;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Timeline column
        SizedBox(
          width: 40,
          child: Column(
            children: [
              Container(
                width: 14,
                height: 14,
                margin: const EdgeInsets.only(top: 14),
                decoration: BoxDecoration(
                  color: _urgencyColor,
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: _urgencyColor.withOpacity(0.3), blurRadius: 6)],
                ),
              ),
              if (!isLast)
                Container(
                  width: 2,
                  height: 80,
                  color: const Color(0xFFE5E7EB),
                ),
            ],
          ),
        ),

        // Card
        Expanded(
          child: GestureDetector(
            onTap: onTap,
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE5E7EB)),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 2)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: _urgencyColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          log.urgency,
                          style: TextStyle(
                            color: _urgencyColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${log.displayDate}  ${log.displayTime}',
                        style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    log.symptoms,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textDark,
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    children: log.conditions
                        .take(2)
                        .map((c) => Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppColors.lavender,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                c,
                                style: const TextStyle(
                                  color: AppColors.primary,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ))
                        .toList(),
                  ),
                  const SizedBox(height: 6),
                  const Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      'View report →',
                      style: TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Detail Bottom Sheet
// ---------------------------------------------------------------------------

class _DetailSheet extends StatelessWidget {
  final HealthLog log;

  const _DetailSheet({required this.log});

  Color get _urgencyColor {
    switch (log.urgency) {
      case 'High':
        return AppColors.emergency;
      case 'Medium':
        return AppColors.warning;
      default:
        return AppColors.success;
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      builder: (_, scrollController) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFE5E7EB),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.all(24),
                children: [
                  // Header
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Health Report',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${log.displayDate} at ${log.displayTime}',
                              style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: _urgencyColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${log.urgency} Risk',
                          style: TextStyle(
                            color: _urgencyColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Symptoms
                  _SheetSection(
                    icon: Icons.notes_rounded,
                    title: 'Described Symptoms',
                    child: Text(
                      log.symptoms,
                      style: const TextStyle(color: AppColors.textDark, fontSize: 14, height: 1.5),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Conditions
                  _SheetSection(
                    icon: Icons.biotech_rounded,
                    title: 'Possible Conditions',
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: log.conditions
                          .map((c) => Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: AppColors.lavender,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  c,
                                  style: const TextStyle(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                ),
                              ))
                          .toList(),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Suggestions
                  _SheetSection(
                    icon: Icons.spa_rounded,
                    title: 'Self-Care Suggestions',
                    child: Column(
                      children: log.suggestions.asMap().entries.map((e) => Padding(
                        padding: EdgeInsets.only(bottom: e.key < log.suggestions.length - 1 ? 8 : 0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              margin: const EdgeInsets.only(top: 3),
                              width: 6, height: 6,
                              decoration: const BoxDecoration(
                                color: AppColors.success, shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(e.value, style: const TextStyle(color: AppColors.textDark, fontSize: 14, height: 1.4)),
                            ),
                          ],
                        ),
                      )).toList(),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Warnings
                  if (log.warnings.isNotEmpty) ...[
                    _SheetSection(
                      icon: Icons.warning_amber_rounded,
                      title: 'Warning Signs',
                      iconColor: AppColors.emergency,
                      child: Column(
                        children: log.warnings.asMap().entries.map((e) => Padding(
                          padding: EdgeInsets.only(bottom: e.key < log.warnings.length - 1 ? 8 : 0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                margin: const EdgeInsets.only(top: 3),
                                width: 6, height: 6,
                                decoration: const BoxDecoration(
                                  color: AppColors.emergency, shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(e.value, style: const TextStyle(color: AppColors.textDark, fontSize: 14, height: 1.4)),
                              ),
                            ],
                          ),
                        )).toList(),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Disclaimer
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFFBEB),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.warning.withOpacity(0.3)),
                    ),
                    child: Text(
                      log.disclaimer,
                      style: const TextStyle(fontSize: 12, color: AppColors.textMuted, height: 1.5),
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
}

class _SheetSection extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget child;
  final Color iconColor;

  const _SheetSection({
    required this.icon,
    required this.title,
    required this.child,
    this.iconColor = AppColors.primary,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.lightGray,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 18),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textDark, fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Empty State
// ---------------------------------------------------------------------------

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.lavender,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.history_rounded, color: AppColors.primary, size: 40),
          ),
          const SizedBox(height: 16),
          const Text(
            'No health records yet',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textDark),
          ),
          const SizedBox(height: 6),
          const Text(
            'Use the Symptom Checker to start\nbuilding your health history.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textMuted, fontSize: 14, height: 1.5),
          ),
        ],
      ),
    );
  }
}
