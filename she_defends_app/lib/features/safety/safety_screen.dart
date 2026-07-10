import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import 'package:she_defends_app/core/providers/app_state.dart';
import 'package:she_defends_app/core/theme/app_theme.dart';
import 'package:she_defends_app/core/network/api_client.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:geolocator/geolocator.dart';
import 'package:she_defends_app/core/services/location_service.dart';
import 'dart:math';

class SafetyScreen extends ConsumerStatefulWidget {
  const SafetyScreen({super.key});

  @override
  ConsumerState<SafetyScreen> createState() => _SafetyScreenState();
}

class _SafetyScreenState extends ConsumerState<SafetyScreen> {
  final _startController = TextEditingController(text: "5th Avenue, Manhattan");
  final _destController = TextEditingController(text: "Corporate Plaza, Midtown");
  final _contactNameController = TextEditingController();
  final _contactPhoneController = TextEditingController();
  String _selectedContactCategory = "Family";

  String _selectedRouteType = "safe"; // Default to 'safe'
  final bool _isStealthExpanded = false;
  final _apiClient = ApiClient();

  bool _isRecordingAudio = false;
  int _recordingSeconds = 0;
  Timer? _recordingTimer;

  // Real-time location tracking state properties
  List<Map<String, dynamic>> _nearbyPlaces = [];
  StreamSubscription<Position>? _locationSubscription;

  @override
  void initState() {
    super.initState();
    _syncContactsFromBackend();
    _loadCurrentLocationAndPlaces();
    _subscribeToLiveLocation();
  }

  @override
  void dispose() {
    _startController.dispose();
    _destController.dispose();
    _contactNameController.dispose();
    _contactPhoneController.dispose();
    _recordingTimer?.cancel();
    _locationSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadCurrentLocationAndPlaces() async {
    try {
      final position = await LocationService().getCurrentLocation();
      if (mounted) {
        setState(() {
          _startController.text = "GPS: ${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}";
        });
        await _generateNearbyPlaces(position.latitude, position.longitude);
      }
    } catch (e) {
      debugPrint("Error fetching real location: $e");
      _generateFallbackPlaces();
    }
  }

  void _subscribeToLiveLocation() {
    _locationSubscription = LocationService().getPositionStream().listen((position) {
      if (mounted) {
        if (_nearbyPlaces.isNotEmpty) {
          _updatePlacesList(_nearbyPlaces, position.latitude, position.longitude);
        }
      }
    });
  }

  Future<void> _generateNearbyPlaces(double lat, double lng) async {
    try {
      final response = await _apiClient.get("/safety/safe-places?lat=$lat&lng=$lng");
      if (response.statusCode == 200 && response.data is List) {
        final List<Map<String, dynamic>> places = List<Map<String, dynamic>>.from(
          (response.data as List).map((p) => Map<String, dynamic>.from(p))
        );
        _updatePlacesList(places, lat, lng);
        return;
      }
    } catch (e) {
      debugPrint("Failed to fetch nearby safe places from backend: $e");
    }

    // Local fallback if API fails
    final List<Map<String, dynamic>> fallbackPlaces = [
      {
        "name": "St. Mary Medical Center",
        "lat": lat + 0.005,
        "lng": lng + 0.004,
        "phone": "555-0199",
        "type": "Hospital"
      },
      {
        "name": "Central Police Precinct",
        "lat": lat - 0.007,
        "lng": lng - 0.005,
        "phone": "555-0144",
        "type": "Police Station"
      },
      {
        "name": "SafeHaven Community Center",
        "lat": lat + 0.008,
        "lng": lng - 0.006,
        "phone": "555-0122",
        "type": "Safe Place"
      },
      {
        "name": "24/7 Downtown Pharmacy",
        "lat": lat - 0.003,
        "lng": lng + 0.008,
        "phone": "555-0188",
        "type": "Pharmacy"
      },
    ];

    _updatePlacesList(fallbackPlaces, lat, lng);
  }

  void _generateFallbackPlaces() {
    const double lat = 40.7749;
    const double lng = -73.9712;
    _generateNearbyPlaces(lat, lng);
  }


  void _updatePlacesList(List<Map<String, dynamic>> basePlaces, double userLat, double userLng) {
    final List<Map<String, dynamic>> updated = [];
    for (var place in basePlaces) {
      final double lat = (place["lat"] as num).toDouble();
      final double lng = (place["lng"] as num).toDouble();
      final double distKm = _calculateDistance(userLat, userLng, lat, lng);
      final double distMiles = distKm * 0.621371;
      
      updated.add({
        "name": place["name"],
        "lat": lat,
        "lng": lng,
        "phone": place["phone"],
        "type": place["type"],
        "dist": "${distMiles.toStringAsFixed(2)} miles",
      });
    }
    if (mounted) {
      setState(() {
        _nearbyPlaces = updated;
      });
    }
  }


  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    var p = 0.017453292519943295; // Math.PI / 180
    var a = 0.5 - cos((lat2 - lat1) * p)/2 + 
          cos(lat1 * p) * cos(lat2 * p) * 
          (1 - cos((lon2 - lon1) * p))/2;
    return 12742 * asin(sqrt(a)); // 2 * R; R = 6371 km
  }

  Future<void> _syncContactsFromBackend() async {
    try {
      final res = await _apiClient.get("/safety/contacts");
      if (res.data is List) {
        final list = (res.data as List).map((c) => EmergencyContact(
          id: c["id"] ?? "",
          name: c["name"] ?? "",
          phone: c["phone"] ?? "",
          category: c["category"] ?? "Family",
        )).toList();
        ref.read(emergencyContactsProvider.notifier).setContacts(list);
      }
    } catch (e) {
      debugPrint("Failed to load contacts from backend: $e");
    }
  }

  Future<void> _handleStartJourney() async {
    final src = _startController.text.trim().isEmpty ? "My Location (GPS)" : _startController.text.trim();
    final dest = _destController.text.trim();
    if (dest.isEmpty) return;

    ref.read(guardianProvider.notifier).startJourney(src, dest);
    
    try {
      await _apiClient.post("/safety/journey/start", data: {
        "source": src,
        "destination": dest,
        "eta": 15,
        "route_type": _selectedRouteType,
      });
    } catch (e) {
      debugPrint("Failed to sync journey with backend: $e");
    }
  }

  Future<void> _addOrEditContact({String? editId}) async {
    final name = _contactNameController.text.trim();
    final phone = _contactPhoneController.text.trim();
    if (name.isEmpty || phone.isEmpty) return;

    final data = {
      "name": name,
      "phone": phone,
      "category": _selectedContactCategory,
    };
    if (editId != null && editId.isNotEmpty) {
      data["id"] = editId;
    }

    try {
      final res = await _apiClient.post("/safety/contacts", data: data);
      final savedId = res.data["id"] ?? editId ?? DateTime.now().millisecondsSinceEpoch.toString();
      
      if (editId != null && editId.isNotEmpty) {
        ref.read(emergencyContactsProvider.notifier).editContact(editId, name, phone, _selectedContactCategory);
      } else {
        ref.read(emergencyContactsProvider.notifier).addContact(savedId, name, phone, _selectedContactCategory);
      }
      
      _contactNameController.clear();
      _contactPhoneController.clear();
      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      debugPrint("Failed to save contact to backend: $e");
    }
  }

  Future<void> _deleteContact(String id) async {
    try {
      await _apiClient.dio.delete("/safety/contacts/$id");
      ref.read(emergencyContactsProvider.notifier).removeContact(id);
    } catch (e) {
      debugPrint("Failed to delete contact on backend: $e");
    }
  }

  void _showContactDialog({EmergencyContact? contact}) {
    if (contact != null) {
      _contactNameController.text = contact.name;
      _contactPhoneController.text = contact.phone;
      _selectedContactCategory = contact.category;
    } else {
      _contactNameController.clear();
      _contactPhoneController.clear();
      _selectedContactCategory = "Family";
    }

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(contact != null ? "Edit Contact" : "Add Emergency Contact", style: const TextStyle(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _contactNameController,
                decoration: const InputDecoration(labelText: "Full Name", hintText: "Enter contact name"),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _contactPhoneController,
                decoration: const InputDecoration(labelText: "Phone Number", hintText: "Enter phone number"),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                // ignore: deprecated_member_use
                value: _selectedContactCategory,
                decoration: const InputDecoration(labelText: "Relationship Category"),
                items: ["Family", "Friends", "Guardians", "Emergency Services"].map((cat) {
                  return DropdownMenuItem(value: cat, child: Text(cat));
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    setDialogState(() {
                      _selectedContactCategory = val;
                    });
                  }
                },
              )
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
            ElevatedButton(
              onPressed: () => _addOrEditContact(
                editId: (contact?.id != null && contact!.id.isNotEmpty) ? contact.id : null,
              ),
              child: const Text("Save"),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final guardianState = ref.watch(guardianProvider);
    final stealthState = ref.watch(stealthProvider);
    // final fakeCallState = ref.watch(fakeCallProvider);
    final contacts = ref.watch(emergencyContactsProvider);

    final isJourneyActive = guardianState.status == GuardianStatus.active || 
                            guardianState.status == GuardianStatus.deviationWarning;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text("Safety Shield", style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header status block
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Guardian Mode", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.primary)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isJourneyActive ? AppColors.success.withValues(alpha: 0.1) : AppColors.textMuted.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: isJourneyActive ? AppColors.success : AppColors.textMuted,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        isJourneyActive ? "Active" : "Inactive",
                        style: TextStyle(
                          color: isJourneyActive ? AppColors.success : AppColors.textMuted,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Main Map Tracking Card or Input Card
            isJourneyActive 
                ? _buildActiveJourneyCard(guardianState) 
                : _buildPlanJourneyCard(),

            // Are You Safe Check-In Prompts (during deviation warnings)
            if (guardianState.status == GuardianStatus.deviationWarning) ...[
              const SizedBox(height: 16),
              _buildDeviationCard(),
            ],

            const SizedBox(height: 20),
            
            // Expandable Stealth & Discreet Settings Card
            _buildStealthConfigCard(stealthState),

            const SizedBox(height: 24),

            // Emergency Contacts Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Emergency Contacts", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.primary)),
                TextButton.icon(
                  onPressed: () => _showContactDialog(),
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text("Add", style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _buildContactsList(contacts),

            const SizedBox(height: 24),

            // Nearby Safe Havens Section
            const Text("Nearby Safe Havens", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.primary)),
            const SizedBox(height: 12),
            _buildNearbyPlaces(),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // --- Active Journey Map Card ---
  Widget _buildActiveJourneyCard(GuardianState state) {
    return GestureDetector(
      onTap: () async {
        final origin = Uri.encodeComponent(state.source);
        final destination = Uri.encodeComponent(state.destination);
        final url = Uri.parse("https://www.google.com/maps/dir/?api=1&origin=$origin&destination=$destination");
        if (await canLaunchUrl(url)) {
          await launchUrl(url, mode: LaunchMode.externalApplication);
        }
      },
      child: Card(
        clipBehavior: Clip.antiAlias,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18), side: BorderSide(color: Colors.grey.shade200)),
        child: Column(
        children: [
          Container(
            height: 220,
            color: const Color(0xFFE5E7EB),
            alignment: Alignment.center,
            child: Stack(
              children: [
                Positioned.fill(
                  child: CustomPaint(
                    painter: MapRoutePainter(routeType: _selectedRouteType),
                  ),
                ),
                Positioned(
                  top: 12,
                  left: 12,
                  child: Card(
                    color: _selectedRouteType == "safe" ? AppColors.success : AppColors.primary,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                      child: Row(
                        children: [
                          Icon(_selectedRouteType == "safe" ? Icons.shield : Icons.navigation, color: Colors.white, size: 14),
                          const SizedBox(width: 4),
                          Text(
                            _selectedRouteType == "safe" ? "Safe Route Active" : "Fastest Route",
                            style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.6), borderRadius: BorderRadius.circular(8)),
                    child: const Row(
                      children: [
                        Icon(Icons.gps_fixed, color: Colors.green, size: 12),
                        SizedBox(width: 4),
                        Text("GPS ACTIVE", style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
                // Floating Address Panel
                Positioned(
                  top: 60,
                  left: 20,
                  right: 20,
                  child: Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          const Column(
                            children: [
                              Icon(Icons.my_location, color: AppColors.primaryActive, size: 16),
                              SizedBox(height: 8),
                              Icon(Icons.more_vert, color: AppColors.textMuted, size: 12),
                              SizedBox(height: 8),
                              Icon(Icons.location_on, color: AppColors.emergency, size: 16),
                            ],
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text("Current Location", style: TextStyle(color: AppColors.textMuted, fontSize: 10)),
                                Text(state.source, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                const SizedBox(height: 10),
                                const Text("Destination", style: TextStyle(color: AppColors.textMuted, fontSize: 10)),
                                Text(state.destination, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                              ],
                            ),
                          )
                        ],
                      ),
                    ),
                  ),
                )
              ],
            ),
          ),
          
          // Metrics Row
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildMetricColumn("ETA", "${state.remainingMinutes} mins"),
                _buildMetricColumn("Distance", "4.2 km"),
                _buildMetricColumn("Risk Score", "Low", color: AppColors.success),
              ],
            ),
          ),
          const Divider(height: 1),
          
          // Active Actions Bar: End Journey, Fake Call, Audio Record
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      flex: 1,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          ref.read(guardianProvider.notifier).reset();
                        },
                        icon: const Icon(Icons.cancel_outlined, size: 16),
                        label: const Text("End Journey", maxLines: 1, overflow: TextOverflow.ellipsis),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey.shade200,
                          foregroundColor: Colors.black87,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 1,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          ref.read(fakeCallProvider.notifier).triggerIncomingCall();
                        },
                        icon: const Icon(Icons.phone_in_talk, size: 16),
                        label: const Text("Fake Call", maxLines: 1, overflow: TextOverflow.ellipsis),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (_isRecordingAudio) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.emergency.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.emergency.withValues(alpha: 0.2)),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: (_recordingSeconds % 2 == 0) ? Colors.red : Colors.transparent,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              "Recording Ambient Audio... ${_recordingSeconds.toString().padLeft(2, '0')}s",
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.emergency),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        // Waveform animation
                        SizedBox(
                          height: 24,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(16, (idx) {
                              final h = 4.0 + (16.0 * (1.0 + (idx % 3 == 0 ? 0.6 : (idx % 2 == 0 ? 0.2 : -0.4))));
                              return Container(
                                margin: const EdgeInsets.symmetric(horizontal: 2.0),
                                width: 3,
                                height: h,
                                decoration: BoxDecoration(
                                  color: AppColors.emergency.withValues(alpha: 0.6),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              );
                            }),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              _recordingTimer?.cancel();
                              _uploadMockAudioClip();
                              setState(() {
                                _isRecordingAudio = false;
                                _recordingSeconds = 0;
                              });
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text("Ambient Audio Recording stashed successfully!")),
                              );
                            },
                            icon: const Icon(Icons.stop),
                            label: const Text("Stop & Save Recording"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                              elevation: 0,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        setState(() {
                          _isRecordingAudio = true;
                          _recordingSeconds = 0;
                        });
                        _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
                          setState(() {
                            _recordingSeconds++;
                          });
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Ambient Audio Recording started...")),
                        );
                      },
                      icon: const Icon(Icons.mic, color: AppColors.emergency),
                      label: const Text("Stash Audio Recording", style: TextStyle(color: AppColors.emergency)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.emergency),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

  // --- Plan/Start Journey Card ---
  Widget _buildPlanJourneyCard() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18), side: BorderSide(color: Colors.grey.shade200)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Start a Monitored Journey", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 16),
            
            const Text("Start Location", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
            const SizedBox(height: 6),
            TextField(
              controller: _startController,
              decoration: const InputDecoration(
                hintText: "Enter start address",
                prefixIcon: Icon(Icons.gps_fixed, color: AppColors.success),
              ),
            ),
            const SizedBox(height: 16),
            
            const Text("Destination", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
            const SizedBox(height: 6),
            TextField(
              controller: _destController,
              decoration: const InputDecoration(
                hintText: "Enter destination address",
                prefixIcon: Icon(Icons.location_on, color: AppColors.emergency),
              ),
            ),
            const SizedBox(height: 16),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Strategy:", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                Row(
                  children: [
                    ChoiceChip(
                      label: const Text("Fastest"),
                      selected: _selectedRouteType == "fastest",
                      onSelected: (sel) {
                        if (sel) setState(() => _selectedRouteType = "fastest");
                      },
                    ),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: const Text("Safe Route"),
                      selected: _selectedRouteType == "safe",
                      onSelected: (sel) {
                        if (sel) setState(() => _selectedRouteType = "safe");
                      },
                    ),
                  ],
                )
              ],
            ),
            const SizedBox(height: 20),
            
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _handleStartJourney,
                icon: const Icon(Icons.navigation),
                label: const Text("Start Monitored Journey"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Deviation Warning Card ---
  Widget _buildDeviationCard() {
    return Card(
      color: AppColors.emergency.withValues(alpha: 0.04),
      shape: RoundedRectangleBorder(side: const BorderSide(color: AppColors.emergency, width: 1.5), borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Row(
              children: [
                Icon(Icons.warning, color: AppColors.warning),
                SizedBox(width: 12),
                Text("Are you safe?", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.emergency)),
              ],
            ),
            const SizedBox(height: 8),
            const Text("A route deviation was detected. Let us know if you need assistance.", style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      ref.read(guardianProvider.notifier).reset();
                      ref.read(sosProvider.notifier).startCountdown();
                    },
                    style: OutlinedButton.styleFrom(side: const BorderSide(color: AppColors.emergency)),
                    child: const Text("Need Help", style: TextStyle(color: AppColors.emergency)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      ref.read(guardianProvider.notifier).resolveDeviation();
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
                    child: const Text("I'm Safe"),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  // --- Expandable Stealth Config Card ---
  Widget _buildStealthConfigCard(StealthState state) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.grey.shade200)),
      child: ExpansionTile(
        initiallyExpanded: _isStealthExpanded,
        title: const Text("Stealth & Discreet Alarms", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.primary)),
        subtitle: const Text("Calculator decoy lock, shake triggers, and silent SOS"),
        leading: const Icon(Icons.security, color: AppColors.primary),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text("Calculator Decoy Lock", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  subtitle: const Text("Hides app behind a working calculator decoy. Enter PIN to unlock."),
                  value: state.isCalculatorLockEnabled,
                  activeThumbColor: AppColors.primary,
                  contentPadding: EdgeInsets.zero,
                  onChanged: (val) {
                    ref.read(stealthProvider.notifier).toggleCalculatorLock(val);
                  },
                ),
                if (state.isCalculatorLockEnabled) ...[
                  ListTile(
                    title: const Text("Secret Decoy Unlock PIN", style: TextStyle(fontSize: 12)),
                    trailing: Text(state.pin, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 14)),
                    contentPadding: EdgeInsets.zero,
                    onTap: () {
                      _showPinDialog(state.pin);
                    },
                  )
                ],
                const Divider(),
                SwitchListTile(
                  title: const Text("Silent SOS Alerts", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  subtitle: const Text("Broadcasts distress coordinates silently without sounding alarms."),
                  value: state.isSilentSosEnabled,
                  activeThumbColor: AppColors.primary,
                  contentPadding: EdgeInsets.zero,
                  onChanged: (val) {
                    ref.read(stealthProvider.notifier).toggleSilentSos(val);
                  },
                ),
                const Divider(),
                SwitchListTile(
                  title: const Text("Shake Phone to Alert", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  subtitle: const Text("Trigger distress alert automatically by shaking the device."),
                  value: state.isShakeToSosEnabled,
                  activeThumbColor: AppColors.primary,
                  contentPadding: EdgeInsets.zero,
                  onChanged: (val) {
                    ref.read(stealthProvider.notifier).toggleShakeToSos(val);
                  },
                ),
                if (state.isShakeToSosEnabled) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Text("Sensitivity: ", style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                      Expanded(
                        child: Slider(
                          value: state.shakeSensitivity,
                          min: 0.1,
                          max: 1.0,
                          onChanged: (val) {
                            ref.read(stealthProvider.notifier).setShakeSensitivity(val);
                          },
                        ),
                      ),
                      Text(state.shakeSensitivity.toStringAsFixed(1), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: () {
                      ref.read(sosProvider.notifier).startCountdown();
                    },
                    icon: const Icon(Icons.vibration, size: 16),
                    label: const Text("Simulate Shake Event"),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.emergency,
                      side: const BorderSide(color: AppColors.emergency),
                    ),
                  )
                ],
              ],
            ),
          )
        ],
      ),
    );
  }

  // --- Contacts List ---
  Widget _buildContactsList(List<EmergencyContact> contacts) {
    if (contacts.isEmpty) {
      return Container(
        height: 100,
        alignment: Alignment.center,
        child: const Text("No trusted contacts configured", style: TextStyle(color: AppColors.textMuted)),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: contacts.length,
      itemBuilder: (context, index) {
        final contact = contacts[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: AppColors.lavender,
              child: Text(contact.category[0].toUpperCase(), style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
            ),
            title: Text(contact.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            subtitle: Text("${contact.phone} • ${contact.category}"),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 18, color: AppColors.textMuted),
                  onPressed: () => _showContactDialog(contact: contact),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.emergency),
                  onPressed: () => _deleteContact(contact.id),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // --- Nearby Safe Places ---
  Widget _buildNearbyPlaces() {
    if (_nearbyPlaces.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _nearbyPlaces.length,
      itemBuilder: (context, index) {
        final loc = _nearbyPlaces[index];
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
          margin: const EdgeInsets.only(bottom: 10),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: color.withValues(alpha: 0.1),
              child: Icon(icon, color: color, size: 20),
            ),
            title: Text(loc["name"]!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            subtitle: Text("${loc["type"]} • ${loc["dist"]} away"),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.phone_outlined, color: AppColors.success, size: 20),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Dialing ${loc['name']} (${loc['phone']})...")),
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.directions, color: AppColors.primary, size: 20),
                  onPressed: () {
                    setState(() {
                      _destController.text = loc["name"]!;
                      _selectedRouteType = "safe";
                    });
                    _handleStartJourney();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Routing secure path to ${loc['name']}...")),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // --- Helper Widgets ---
  Widget _buildMetricColumn(String label, String value, {Color? color}) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: AppColors.textMuted, fontSize: 10, fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        Text(
          value, 
          style: TextStyle(
            fontWeight: FontWeight.bold, 
            fontSize: 15, 
            color: color ?? AppColors.primary,
          ),
        ),
      ],
    );
  }

  Future<void> _uploadMockAudioClip() async {
    final clipNum = ref.read(sosProvider).recordings.length + 1;
    final filename = "SOS_Record_Clip_#$clipNum.mp3";
    try {
      final res = await _apiClient.post("/safety/recordings", data: {
        "filename": filename,
        "duration": "0:30",
        "size": "120 KB",
      });
      if (res.data["recording"] != null) {
        ref.read(sosProvider.notifier).addMockRecording(filename, "0:30", "120 KB");
      }
    } catch (e) {
      debugPrint("Failed to sync recording with backend: $e");
    }
  }

  void _showPinDialog(String currentPin) {
    showDialog(
      context: context,
      builder: (context) {
        final controller = TextEditingController(text: currentPin);
        return AlertDialog(
          title: const Text("Set Decoy Unlock PIN"),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            maxLength: 6,
            decoration: const InputDecoration(hintText: "Enter numeric code"),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
            ElevatedButton(
              onPressed: () {
                if (controller.text.trim().isNotEmpty) {
                  ref.read(stealthProvider.notifier).setPin(controller.text.trim());
                }
                Navigator.pop(context);
              },
              child: const Text("Set PIN"),
            )
          ],
        );
      },
    );
  }
}

// Simple path painter to simulate map on Canvas
class MapRoutePainter extends CustomPainter {
  final String routeType;
  MapRoutePainter({required this.routeType});

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = Colors.grey.withValues(alpha: 0.15)
      ..strokeWidth = 1.0;
    
    for (double i = 0; i < size.width; i += 30) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), gridPaint);
    }
    for (double j = 0; j < size.height; j += 30) {
      canvas.drawLine(Offset(0, j), Offset(size.width, j), gridPaint);
    }

    final pathPaint = Paint()
      ..color = routeType == 'safe' ? AppColors.success : AppColors.primary.withValues(alpha: 0.4)
      ..strokeWidth = 6.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final path = Path();
    path.moveTo(size.width * 0.1, size.height * 0.8);
    
    if (routeType == 'safe') {
      path.lineTo(size.width * 0.35, size.height * 0.7);
      path.lineTo(size.width * 0.45, size.height * 0.45);
      path.lineTo(size.width * 0.7, size.height * 0.35);
      path.lineTo(size.width * 0.9, size.height * 0.2);
    } else {
      path.quadraticBezierTo(
        size.width * 0.35,
        size.height * 0.35,
        size.width * 0.9,
        size.height * 0.2,
      );
    }

    canvas.drawPath(path, pathPaint);

    final landmarkPaint = Paint()..style = PaintingStyle.fill;

    if (routeType == 'safe') {
      landmarkPaint.color = AppColors.success;
      canvas.drawCircle(Offset(size.width * 0.35, size.height * 0.7), 6, landmarkPaint);
      canvas.drawCircle(Offset(size.width * 0.7, size.height * 0.35), 6, landmarkPaint);
    }
    
    final startPaint = Paint()..color = AppColors.primaryActive..style = PaintingStyle.fill;
    final endPaint = Paint()..color = AppColors.emergency..style = PaintingStyle.fill;
    
    canvas.drawCircle(Offset(size.width * 0.1, size.height * 0.8), 8, startPaint);
    canvas.drawCircle(Offset(size.width * 0.9, size.height * 0.2), 8, endPaint);
  }

  @override
  bool shouldRepaint(covariant MapRoutePainter oldDelegate) => oldDelegate.routeType != routeType;
}
