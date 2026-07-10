import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:she_defends_app/core/theme/app_theme.dart';
import 'package:she_defends_app/features/health/symptom_checker_screen.dart';
import 'package:she_defends_app/features/health/health_history_screen.dart';
import 'package:she_defends_app/features/health/medication_manager_screen.dart';

class HealthScreen extends ConsumerWidget {
  const HealthScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Health',
          style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 20),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top greeting
            _HealthGreeting(),
            const SizedBox(height: 24),

            // 3 main modules
            const Text(
              'Health Modules',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textDark),
            ),
            const SizedBox(height: 14),
            _ModuleCard(
              icon: Icons.medical_services_rounded,
              title: 'AI Symptom Checker',
              subtitle: 'Describe symptoms · Voice input · AI diagnosis',
              gradient: const [Color(0xFF4C1D95), Color(0xFF7C3AED)],
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SymptomCheckerScreen()),
              ),
            ),
            const SizedBox(height: 12),
            _ModuleCard(
              icon: Icons.history_rounded,
              title: 'Health History',
              subtitle: 'Timeline · Past reports · Detailed view',
              gradient: const [Color(0xFF0F766E), Color(0xFF14B8A6)],
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const HealthHistoryScreen()),
              ),
            ),
            const SizedBox(height: 12),
            _ModuleCard(
              icon: Icons.medication_rounded,
              title: 'Medication Manager',
              subtitle: 'Daily schedule · Reminders · Refill tracking',
              gradient: const [Color(0xFFB45309), Color(0xFFF59E0B)],
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const MedicationManagerScreen()),
              ),
            ),
            const SizedBox(height: 24),

            // Quick vitals
            const Text(
              'Quick Vitals',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textDark),
            ),
            const SizedBox(height: 12),
            _VitalsRow(),
          ],
        ),
      ),
    );
  }
}

class _HealthGreeting extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFF3F0FF), Color(0xFFEDE9FE)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.lavender),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Your Health Dashboard',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.primary),
                ),
                SizedBox(height: 6),
                Text(
                  'Monitor your well-being, track medications, and get AI-powered health insights.',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 13, height: 1.5),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          const Icon(Icons.favorite_rounded, color: AppColors.primary, size: 40),
        ],
      ),
    );
  }
}

class _ModuleCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final List<Color> gradient;
  final VoidCallback onTap;

  const _ModuleCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.gradient,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: gradient, begin: Alignment.topLeft, end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: gradient.first.withOpacity(0.3),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: Colors.white, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white70, size: 16),
          ],
        ),
      ),
    );
  }
}

class _VitalsRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: const [
        Expanded(
          child: _VitalCard(
            icon: Icons.favorite_rounded,
            label: 'Heart Rate',
            value: '72',
            unit: 'bpm',
            color: Color(0xFFEF4444),
            bgColor: Color(0xFFFFF5F5),
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: _VitalCard(
            icon: Icons.nightlight_round,
            label: 'Sleep',
            value: '7.5',
            unit: 'hrs',
            color: Color(0xFF4C1D95),
            bgColor: Color(0xFFF5F3FF),
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: _VitalCard(
            icon: Icons.water_drop_rounded,
            label: 'Hydration',
            value: '1.8',
            unit: 'L',
            color: Color(0xFF0EA5E9),
            bgColor: Color(0xFFF0F9FF),
          ),
        ),
      ],
    );
  }
}

class _VitalCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String unit;
  final Color color;
  final Color bgColor;

  const _VitalCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.unit,
    required this.color,
    required this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(color: color.withOpacity(0.7), fontSize: 11),
          ),
          const SizedBox(height: 2),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
              const SizedBox(width: 2),
              Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Text(unit, style: TextStyle(fontSize: 10, color: color.withOpacity(0.7))),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
