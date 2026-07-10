import 'package:flutter_riverpod/flutter_riverpod.dart';

// --- Navigation State ---
final currentTabProvider = StateProvider<int>((ref) => 0);

// --- Auth & Setup State ---
class AuthState {
  final bool onboardingCompleted;
  final bool isLoggedIn;
  AuthState({required this.onboardingCompleted, required this.isLoggedIn});

  AuthState copyWith({bool? onboardingCompleted, bool? isLoggedIn}) {
    return AuthState(
      onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
      isLoggedIn: isLoggedIn ?? this.isLoggedIn,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(AuthState(onboardingCompleted: false, isLoggedIn: false));

  void completeOnboarding() {
    state = state.copyWith(onboardingCompleted: true);
  }

  void login() {
    state = state.copyWith(isLoggedIn: true);
  }

  void logout() {
    state = AuthState(onboardingCompleted: true, isLoggedIn: false);
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) => AuthNotifier());

// --- User Profile State ---
class UserProfile {
  final String name;
  final String age;
  final String bloodGroup;
  final String allergies;
  final String medicalConditions;
  final List<String> emergencyContacts;
  final String preferredLanguage;
  final String height; // in cm
  final String weight; // in kg
  final String activityLevel;
  final String dietaryPreference;
  final String fitnessGoal;

  UserProfile({
    this.name = '',
    this.age = '',
    this.bloodGroup = 'O+',
    this.allergies = '',
    this.medicalConditions = '',
    this.emergencyContacts = const [],
    this.preferredLanguage = 'English',
    this.height = '165',
    this.weight = '60',
    this.activityLevel = 'Lightly Active',
    this.dietaryPreference = 'Vegetarian',
    this.fitnessGoal = 'Healthy Maintenance',
  });

  // Calculate BMI: Weight / (Height / 100)^2
  double get bmi {
    try {
      final h = double.parse(height) / 100;
      final w = double.parse(weight);
      if (h <= 0) return 0.0;
      return double.parse((w / (h * h)).toStringAsFixed(1));
    } catch (e) {
      return 22.0;
    }
  }

  UserProfile copyWith({
    String? name,
    String? age,
    String? bloodGroup,
    String? allergies,
    String? medicalConditions,
    List<String>? emergencyContacts,
    String? preferredLanguage,
    String? height,
    String? weight,
    String? activityLevel,
    String? dietaryPreference,
    String? fitnessGoal,
  }) {
    return UserProfile(
      name: name ?? this.name,
      age: age ?? this.age,
      bloodGroup: bloodGroup ?? this.bloodGroup,
      allergies: allergies ?? this.allergies,
      medicalConditions: medicalConditions ?? this.medicalConditions,
      emergencyContacts: emergencyContacts ?? this.emergencyContacts,
      preferredLanguage: preferredLanguage ?? this.preferredLanguage,
      height: height ?? this.height,
      weight: weight ?? this.weight,
      activityLevel: activityLevel ?? this.activityLevel,
      dietaryPreference: dietaryPreference ?? this.dietaryPreference,
      fitnessGoal: fitnessGoal ?? this.fitnessGoal,
    );
  }
}

class UserProfileNotifier extends StateNotifier<UserProfile> {
  UserProfileNotifier() : super(UserProfile());

  void updateProfile(UserProfile newProfile) {
    state = newProfile;
  }
}

final userProfileProvider = StateNotifierProvider<UserProfileNotifier, UserProfile>((ref) => UserProfileNotifier());

// --- Medication Log State ---
class Medication {
  final String name;
  final String dosage;
  final String time;
  final bool isTaken;
  Medication({required this.name, required this.dosage, required this.time, this.isTaken = false});

  Medication copyWith({bool? isTaken}) {
    return Medication(name: name, dosage: dosage, time: time, isTaken: isTaken ?? this.isTaken);
  }
}

class MedicationNotifier extends StateNotifier<List<Medication>> {
  MedicationNotifier() : super([
    Medication(name: "Vitamin D3", dosage: "1 Tablet", time: "09:00 AM", isTaken: true),
    Medication(name: "Iron Supplement", dosage: "1 Capsule", time: "08:00 PM", isTaken: false),
  ]);

  void addMedication(Medication med) {
    state = [...state, med];
  }

  void toggleTaken(int index) {
    state = [
      for (int i = 0; i < state.length; i++)
        if (i == index) state[i].copyWith(isTaken: !state[i].isTaken) else state[i]
    ];
  }
}

final medicationProvider = StateNotifierProvider<MedicationNotifier, List<Medication>>((ref) => MedicationNotifier());

// --- SOS State ---
enum SosStatus { idle, countingDown, active }

class SosRecording {
  final String filename;
  final String duration;
  final String size;
  final String timestamp;
  SosRecording({required this.filename, required this.duration, required this.size, required this.timestamp});
}

class ContactNotified {
  final String name;
  final String status; // e.g. 'Delivered (SMS)', 'Delivered (App)', 'Calling...'
  ContactNotified({required this.name, required this.status});
}

class SosState {
  final SosStatus status;
  final int countdownSeconds;
  final double speed;
  final int batteryPercentage;
  final String location;
  final String phone;
  final String message;
  final List<SosRecording> recordings;
  final List<ContactNotified> contactsNotified;
  final bool isOneTapTrigger; // User preference: one tap vs long press

  SosState({
    required this.status,
    required this.countdownSeconds,
    this.speed = 0.0,
    this.batteryPercentage = 94,
    this.location = "456 Safety St, New York",
    this.phone = "+1-555-0199",
    this.message = "I may be in danger. This is my live location. Please help immediately.",
    this.recordings = const [],
    this.contactsNotified = const [],
    this.isOneTapTrigger = false, // defaults to long press
  });

  SosState copyWith({
    SosStatus? status,
    int? countdownSeconds,
    double? speed,
    int? batteryPercentage,
    String? location,
    String? phone,
    String? message,
    List<SosRecording>? recordings,
    List<ContactNotified>? contactsNotified,
    bool? isOneTapTrigger,
  }) {
    return SosState(
      status: status ?? this.status,
      countdownSeconds: countdownSeconds ?? this.countdownSeconds,
      speed: speed ?? this.speed,
      batteryPercentage: batteryPercentage ?? this.batteryPercentage,
      location: location ?? this.location,
      phone: phone ?? this.phone,
      message: message ?? this.message,
      recordings: recordings ?? this.recordings,
      contactsNotified: contactsNotified ?? this.contactsNotified,
      isOneTapTrigger: isOneTapTrigger ?? this.isOneTapTrigger,
    );
  }
}

class SosNotifier extends StateNotifier<SosState> {
  final Ref ref;
  SosNotifier(this.ref) : super(SosState(status: SosStatus.idle, countdownSeconds: 5));

  void toggleTriggerMode(bool oneTap) {
    state = state.copyWith(isOneTapTrigger: oneTap);
  }

  void startCountdown() {
    state = state.copyWith(status: SosStatus.countingDown, countdownSeconds: 5);
  }

  void decrementCountdown() {
    if (state.countdownSeconds > 1) {
      state = state.copyWith(countdownSeconds: state.countdownSeconds - 1);
    } else {
      triggerSos();
    }
  }

  void triggerSos() {
    final contacts = ref.read(emergencyContactsProvider);
    final List<ContactNotified> list = contacts.isNotEmpty
        ? contacts.map((c) => ContactNotified(name: "${c.name} (${c.phone})", status: "Delivered (SMS)")).toList()
        : [
            ContactNotified(name: "Mom", status: "Delivered (SMS)"),
            ContactNotified(name: "Dad", status: "Delivered (App)"),
            ContactNotified(name: "Sarah (Bestie)", status: "Delivered (SMS)"),
          ];
    state = state.copyWith(
      status: SosStatus.active,
      countdownSeconds: 0,
      speed: 14.5,
      batteryPercentage: 92,
      location: "Central Park West & W 72nd St, New York",
      contactsNotified: list,
      recordings: [],
    );
  }

  void cancelSos() {
    state = state.copyWith(status: SosStatus.idle, countdownSeconds: 5, recordings: []);
  }

  void addMockRecording(String filename, String duration, String size) {
    final newRecording = SosRecording(
      filename: filename,
      duration: duration,
      size: size,
      timestamp: DateTime.now().toIso8601String(),
    );
    state = state.copyWith(recordings: [...state.recordings, newRecording]);
  }
}

final sosProvider = StateNotifierProvider<SosNotifier, SosState>((ref) => SosNotifier(ref));

// --- Guardian Mode State ---
enum GuardianStatus { inactive, active, deviationWarning, completed }

class GuardianState {
  final GuardianStatus status;
  final String source;
  final String destination;
  final int remainingMinutes;
  final double speed;
  final double riskScore;

  GuardianState({
    required this.status,
    required this.source,
    required this.destination,
    required this.remainingMinutes,
    required this.speed,
    required this.riskScore,
  });

  GuardianState copyWith({
    GuardianStatus? status,
    String? source,
    String? destination,
    int? remainingMinutes,
    double? speed,
    double? riskScore,
  }) {
    return GuardianState(
      status: status ?? this.status,
      source: source ?? this.source,
      destination: destination ?? this.destination,
      remainingMinutes: remainingMinutes ?? this.remainingMinutes,
      speed: speed ?? this.speed,
      riskScore: riskScore ?? this.riskScore,
    );
  }
}

class GuardianNotifier extends StateNotifier<GuardianState> {
  GuardianNotifier() : super(GuardianState(
    status: GuardianStatus.inactive,
    source: '',
    destination: '',
    remainingMinutes: 0,
    speed: 0.0,
    riskScore: 0.0,
  ));

  void startJourney(String src, String dest) {
    state = GuardianState(
      status: GuardianStatus.active,
      source: src,
      destination: dest,
      remainingMinutes: 25,
      speed: 15.2,
      riskScore: 0.05,
    );
  }

  void triggerDeviation() {
    state = state.copyWith(status: GuardianStatus.deviationWarning, riskScore: 0.85);
  }

  void resolveDeviation() {
    state = state.copyWith(status: GuardianStatus.active, riskScore: 0.05);
  }

  void endJourney() {
    state = state.copyWith(status: GuardianStatus.completed);
  }

  void reset() {
    state = GuardianState(
      status: GuardianStatus.inactive,
      source: '',
      destination: '',
      remainingMinutes: 0,
      speed: 0.0,
      riskScore: 0.0,
    );
  }
}

final guardianProvider = StateNotifierProvider<GuardianNotifier, GuardianState>((ref) => GuardianNotifier());

// --- Chat History Message ---
class ChatMessage {
  final String text;
  final bool isUser;
  final String? route;
  ChatMessage({required this.text, required this.isUser, this.route});
}

class ChatNotifier extends StateNotifier<List<ChatMessage>> {
  ChatNotifier() : super([
    ChatMessage(text: "Hello! I am your SheDefends AI assistant. How can I support you today?", isUser: false),
  ]);

  void addMessage(String text, bool isUser, {String? route}) {
    state = [...state, ChatMessage(text: text, isUser: isUser, route: route)];
  }
  
  void clear() {
    state = [
      ChatMessage(text: "Hello! I am your SheDefends AI assistant. How can I support you today?", isUser: false),
    ];
  }
}

final chatProvider = StateNotifierProvider<ChatNotifier, List<ChatMessage>>((ref) => ChatNotifier());

// --- Emergency Contacts State ---
class EmergencyContact {
  final String id;
  final String name;
  final String phone;
  final String category; // Family, Friends, Guardians, etc.

  EmergencyContact({required this.id, required this.name, required this.phone, required this.category});

  EmergencyContact copyWith({String? name, String? phone, String? category}) {
    return EmergencyContact(
      id: id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      category: category ?? this.category,
    );
  }
}

class EmergencyContactsNotifier extends StateNotifier<List<EmergencyContact>> {
  EmergencyContactsNotifier() : super([
    EmergencyContact(id: "1", name: "Mom", phone: "555-0101", category: "Family"),
    EmergencyContact(id: "2", name: "Dad", phone: "555-0102", category: "Family"),
    EmergencyContact(id: "3", name: "Sarah (Bestie)", phone: "555-0103", category: "Friends"),
  ]);

  void setContacts(List<EmergencyContact> list) {
    state = list;
  }

  void addContact(String id, String name, String phone, String category) {
    final contact = EmergencyContact(
      id: id,
      name: name,
      phone: phone,
      category: category,
    );
    state = [...state, contact];
  }

  void editContact(String id, String name, String phone, String category) {
    state = [
      for (final c in state)
        if (c.id == id) c.copyWith(name: name, phone: phone, category: category) else c
    ];
  }

  void removeContact(String id) {
    state = state.where((c) => c.id != id).toList();
  }
}

final emergencyContactsProvider = StateNotifierProvider<EmergencyContactsNotifier, List<EmergencyContact>>((ref) => EmergencyContactsNotifier());

// --- Fake Call State ---
enum FakeCallStatus { idle, scheduled, ringing, active }

class FakeCallState {
  final FakeCallStatus status;
  final String callerName;
  final String ringtone;
  final int scheduleSeconds; // delay in seconds
  final bool playConversation;

  FakeCallState({
    required this.status,
    this.callerName = "Mom",
    this.ringtone = "Classic Bell",
    this.scheduleSeconds = 0,
    this.playConversation = true,
  });

  FakeCallState copyWith({
    FakeCallStatus? status,
    String? callerName,
    String? ringtone,
    int? scheduleSeconds,
    bool? playConversation,
  }) {
    return FakeCallState(
      status: status ?? this.status,
      callerName: callerName ?? this.callerName,
      ringtone: ringtone ?? this.ringtone,
      scheduleSeconds: scheduleSeconds ?? this.scheduleSeconds,
      playConversation: playConversation ?? this.playConversation,
    );
  }
}

class FakeCallNotifier extends StateNotifier<FakeCallState> {
  FakeCallNotifier() : super(FakeCallState(status: FakeCallStatus.idle));

  void configure({String? callerName, String? ringtone, int? scheduleSeconds, bool? playConversation}) {
    state = state.copyWith(
      callerName: callerName,
      ringtone: ringtone,
      scheduleSeconds: scheduleSeconds,
      playConversation: playConversation,
    );
  }

  void triggerIncomingCall() {
    state = state.copyWith(status: FakeCallStatus.ringing);
  }

  void startCallCountdown(int seconds) {
    state = state.copyWith(status: FakeCallStatus.scheduled, scheduleSeconds: seconds);
  }

  void decrementCountdown() {
    if (state.scheduleSeconds > 1) {
      state = state.copyWith(scheduleSeconds: state.scheduleSeconds - 1);
    } else {
      triggerIncomingCall();
    }
  }

  void acceptCall() {
    state = state.copyWith(status: FakeCallStatus.active);
  }

  void endCall() {
    state = state.copyWith(status: FakeCallStatus.idle);
  }
}

final fakeCallProvider = StateNotifierProvider<FakeCallNotifier, FakeCallState>((ref) => FakeCallNotifier());

// --- Stealth State ---
class StealthState {
  final bool isCalculatorLockEnabled;
  final bool isAppLocked; // when locked, it renders calculator
  final String pin;
  final bool isSilentSosEnabled;
  final double shakeSensitivity; // 0.0 to 1.0
  final bool isShakeToSosEnabled;

  StealthState({
    this.isCalculatorLockEnabled = false,
    this.isAppLocked = false,
    this.pin = "9999",
    this.isSilentSosEnabled = false,
    this.shakeSensitivity = 0.5,
    this.isShakeToSosEnabled = false,
  });

  StealthState copyWith({
    bool? isCalculatorLockEnabled,
    bool? isAppLocked,
    String? pin,
    bool? isSilentSosEnabled,
    double? shakeSensitivity,
    bool? isShakeToSosEnabled,
  }) {
    return StealthState(
      isCalculatorLockEnabled: isCalculatorLockEnabled ?? this.isCalculatorLockEnabled,
      isAppLocked: isAppLocked ?? this.isAppLocked,
      pin: pin ?? this.pin,
      isSilentSosEnabled: isSilentSosEnabled ?? this.isSilentSosEnabled,
      shakeSensitivity: shakeSensitivity ?? this.shakeSensitivity,
      isShakeToSosEnabled: isShakeToSosEnabled ?? this.isShakeToSosEnabled,
    );
  }
}

class StealthNotifier extends StateNotifier<StealthState> {
  StealthNotifier() : super(StealthState());

  void toggleCalculatorLock(bool enabled) {
    state = state.copyWith(
      isCalculatorLockEnabled: enabled,
      isAppLocked: enabled, // lock immediately if enabled
    );
  }

  void unlockApp() {
    state = state.copyWith(isAppLocked: false);
  }

  void lockApp() {
    if (state.isCalculatorLockEnabled) {
      state = state.copyWith(isAppLocked: true);
    }
  }

  void setPin(String newPin) {
    state = state.copyWith(pin: newPin);
  }

  void toggleSilentSos(bool enabled) {
    state = state.copyWith(isSilentSosEnabled: enabled);
  }

  void toggleShakeToSos(bool enabled) {
    state = state.copyWith(isShakeToSosEnabled: enabled);
  }

  void setShakeSensitivity(double sensitivity) {
    state = state.copyWith(shakeSensitivity: sensitivity);
  }
}

final stealthProvider = StateNotifierProvider<StealthNotifier, StealthState>((ref) => StealthNotifier());
// --- Water Intake State ---
