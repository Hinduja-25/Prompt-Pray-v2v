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

  UserProfile({
    this.name = '',
    this.age = '',
    this.bloodGroup = 'O+',
    this.allergies = '',
    this.medicalConditions = '',
    this.emergencyContacts = const [],
    this.preferredLanguage = 'English',
  });

  UserProfile copyWith({
    String? name,
    String? age,
    String? bloodGroup,
    String? allergies,
    String? medicalConditions,
    List<String>? emergencyContacts,
    String? preferredLanguage,
  }) {
    return UserProfile(
      name: name ?? this.name,
      age: age ?? this.age,
      bloodGroup: bloodGroup ?? this.bloodGroup,
      allergies: allergies ?? this.allergies,
      medicalConditions: medicalConditions ?? this.medicalConditions,
      emergencyContacts: emergencyContacts ?? this.emergencyContacts,
      preferredLanguage: preferredLanguage ?? this.preferredLanguage,
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

class SosState {
  final SosStatus status;
  final int countdownSeconds;
  SosState({required this.status, required this.countdownSeconds});
}

class SosNotifier extends StateNotifier<SosState> {
  SosNotifier() : super(SosState(status: SosStatus.idle, countdownSeconds: 5));

  void startCountdown() {
    state = SosState(status: SosStatus.countingDown, countdownSeconds: 5);
  }

  void decrementCountdown() {
    if (state.countdownSeconds > 1) {
      state = SosState(status: SosStatus.countingDown, countdownSeconds: state.countdownSeconds - 1);
    } else {
      triggerSos();
    }
  }

  void triggerSos() {
    state = SosState(status: SosStatus.active, countdownSeconds: 0);
  }

  void cancelSos() {
    state = SosState(status: SosStatus.idle, countdownSeconds: 5);
  }
}

final sosProvider = StateNotifierProvider<SosNotifier, SosState>((ref) => SosNotifier());

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
