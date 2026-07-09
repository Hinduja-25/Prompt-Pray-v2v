import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:she_defends_app/core/providers/app_state.dart';
import 'package:she_defends_app/core/theme/app_theme.dart';
import 'package:she_defends_app/core/network/api_client.dart';

class SafetyScreen extends ConsumerStatefulWidget {
  const SafetyScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<SafetyScreen> createState() => _SafetyScreenState();
}

class _SafetyScreenState extends ConsumerState<SafetyScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _sourceController = TextEditingController();
  final _destController = TextEditingController();
  
  final _apiClient = ApiClient();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _sourceController.dispose();
    _destController.dispose();
    super.dispose();
  }

  Future<void> _handleStartJourney() async {
    final src = _sourceController.text.trim();
    final dest = _destController.text.trim();
    if (src.isEmpty || dest.isEmpty) return;

    // Start Journey state in Riverpod
    ref.read(guardianProvider.notifier).startJourney(src, dest);
    
    // Sync to backend DB
    try {
      await _apiClient.post("/safety/journey/start", data: {
        "source": src,
        "destination": dest,
        "eta": 25,
      });
    } catch (e) {
      debugPrint("Failed to sync journey start with backend API: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final guardianState = ref.watch(guardianProvider);
    final isJourneyActive = guardianState.status == GuardianStatus.active || 
                            guardianState.status == GuardianStatus.deviationWarning;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text("Safety Shield", style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textMuted,
          indicatorColor: AppColors.primary,
          tabs: const [
            Tab(text: "Guardian Mode"),
            Tab(text: "Contacts"),
            Tab(text: "Nearby Help"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildGuardianTab(isJourneyActive, guardianState),
          _buildContactsTab(),
          _buildNearbyTab(),
        ],
      ),
    );
  }

  // --- Guardian Mode Tab UI ---
  Widget _buildGuardianTab(bool isActive, GuardianState state) {
    if (isActive) {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Simulation Map Mock Card using SVG path style
            Card(
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  Container(
                    height: 200,
                    color: const Color(0xFFE5E7EB),
                    alignment: Alignment.center,
                    child: Stack(
                      children: [
                        // Mock grid lines and route path
                        Positioned.fill(
                          child: CustomPaint(
                            painter: MapRoutePainter(),
                          ),
                        ),
                        Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(Icons.navigation, color: AppColors.primaryActive, size: 28),
                              SizedBox(height: 4),
                              Text("GPS Active tracking...", style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 11)),
                            ],
                          ),
                        )
                      ],
                    ),
                  ),
                  ListTile(
                    title: const Text("Live Journey Tracking", style: TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text("${state.source} ➔ ${state.destination}"),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.success.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        "Risk: ${(state.riskScore * 100).toInt()}%",
                        style: const TextStyle(color: AppColors.success, fontWeight: FontWeight.bold, fontSize: 11),
                      ),
                    ),
                  )
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Journey metrics
            Row(
              children: [
                Expanded(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          const Text("ETA Remaining", style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                          const SizedBox(height: 4),
                          Text("${state.remainingMinutes} Mins", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          const Text("Speed", style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                          const SizedBox(height: 4),
                          Text("${state.speed} mph", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Simulator Control Panel
            Card(
              color: AppColors.lavender.withOpacity(0.3),
              shape: RoundedRectangleBorder(
                side: const BorderSide(color: AppColors.lavender),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    const Text("JOURNEY SIMULATOR", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.primary)),
                    const SizedBox(height: 12),
                    const Text("Test safety checks by simulating real travel events.", style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              ref.read(guardianProvider.notifier).triggerDeviation();
                            },
                            style: OutlinedButton.styleFrom(side: const BorderSide(color: AppColors.warning)),
                            child: const Text("Simulate Deviation", style: TextStyle(color: AppColors.warning)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              ref.read(guardianProvider.notifier).reset();
                            },
                            style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
                            child: const Text("Arrived Safely"),
                          ),
                        ),
                      ],
                    )
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Plan a Safe Journey", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.primary)),
          const SizedBox(height: 8),
          const Text("Enter your travel coordinates. Guardian Mode will check on you if your GPS stops or deviates.", style: TextStyle(color: AppColors.textMuted)),
          const SizedBox(height: 32),

          const Text("Starting Location", style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          TextField(
            controller: _sourceController,
            decoration: const InputDecoration(
              hintText: "Enter source address",
              prefixIcon: Icon(Icons.my_location, color: AppColors.textMuted),
            ),
          ),
          const SizedBox(height: 20),

          const Text("Destination", style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          TextField(
            controller: _destController,
            decoration: const InputDecoration(
              hintText: "Enter destination address",
              prefixIcon: Icon(Icons.location_on_outlined, color: AppColors.textMuted),
            ),
          ),
          const SizedBox(height: 32),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _handleStartJourney,
              icon: const Icon(Icons.navigation),
              label: const Text("Start Journey"),
            ),
          ),
        ],
      ),
    );
  }

  // --- Contacts Tab UI ---
  Widget _buildContactsTab() {
    final profile = ref.watch(userProfileProvider);
    final list = profile.emergencyContacts;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: list.isEmpty
          ? const Center(child: Text("No emergency contacts set yet", style: TextStyle(color: AppColors.textMuted)))
          : ListView.builder(
              padding: const EdgeInsets.all(24),
              itemCount: list.length,
              itemBuilder: (context, index) {
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: AppColors.lavender,
                      child: Icon(Icons.person, color: AppColors.primary),
                    ),
                    title: Text("Guardian ${index + 1}"),
                    subtitle: Text(list[index]),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(icon: const Icon(Icons.message_outlined, color: AppColors.primaryActive), onPressed: () {}),
                        IconButton(icon: const Icon(Icons.phone_outlined, color: AppColors.success), onPressed: () {}),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  // --- Nearby Safe Places Tab UI ---
  Widget _buildNearbyTab() {
    final List<Map<String, String>> locations = [
      {"name": "St. Mary Medical Center", "dist": "0.8 miles away", "phone": "555-0199", "type": "Hospital"},
      {"name": "Central Police Precinct", "dist": "1.2 miles away", "phone": "555-0144", "type": "Police Station"},
      {"name": "SafeHaven Community Center", "dist": "1.5 miles away", "phone": "555-0122", "type": "Safe Place"},
      {"name": "24/7 Downtown Pharmacy", "dist": "1.8 miles away", "phone": "555-0188", "type": "Pharmacy"},
    ];

    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: locations.length,
      itemBuilder: (context, index) {
        final loc = locations[index];
        IconData icon = Icons.local_hospital;
        Color color = AppColors.emergency;
        
        if (loc["type"] == "Police Station") {
          icon = Icons.local_police;
          color = AppColors.primaryActive;
        } else if (loc["type"] == "Safe Place") {
          icon = Icons.home_work;
          color = AppColors.success;
        } else if (loc["type"] == "Pharmacy") {
          icon = Icons.local_pharmacy;
          color = AppColors.warning;
        }

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: color.withOpacity(0.1),
              child: Icon(icon, color: color),
            ),
            title: Text(loc["name"]!, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text("${loc["type"]} • ${loc["dist"]}"),
            trailing: IconButton(
              icon: const Icon(Icons.directions, color: AppColors.primary),
              onPressed: () {},
            ),
          ),
        );
      },
    );
  }
}

// Simple path painter to simulate map on Canvas
class MapRoutePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.primary.withOpacity(0.3)
      ..strokeWidth = 6.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final path = Path();
    path.moveTo(size.width * 0.1, size.height * 0.8);
    path.quadraticBezierTo(
      size.width * 0.3,
      size.height * 0.2,
      size.width * 0.5,
      size.height * 0.5,
    );
    path.lineTo(size.width * 0.9, size.height * 0.2);

    canvas.drawPath(path, paint);

    // Draw grid intersections
    final dotPaint = Paint()
      ..color = Colors.grey.withOpacity(0.4)
      ..style = PaintingStyle.fill;
      
    canvas.drawCircle(Offset(size.width * 0.1, size.height * 0.8), 8, dotPaint);
    canvas.drawCircle(Offset(size.width * 0.9, size.height * 0.2), 8, dotPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
