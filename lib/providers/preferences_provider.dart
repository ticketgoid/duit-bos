import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _keyOnboardingDone = 'onboarding_done';
const _keyUserName = 'user_name';

// ── Cek apakah onboarding sudah selesai ──────────────────────
final onboardingDoneProvider = FutureProvider<bool>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool(_keyOnboardingDone) ?? false;
});

// ── Nama user ─────────────────────────────────────────────────
final userNameProvider = FutureProvider<String>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString(_keyUserName) ?? 'Bos';
});

// ── Notifier untuk update preferensi ─────────────────────────
class PreferencesNotifier extends AsyncNotifier<Map<String, dynamic>> {
  @override
  Future<Map<String, dynamic>> build() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'onboarding_done': prefs.getBool(_keyOnboardingDone) ?? false,
      'user_name': prefs.getString(_keyUserName) ?? 'Bos',
    };
  }

  Future<void> completeOnboarding(String userName) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyOnboardingDone, true);
    await prefs.setString(_keyUserName, userName);
    ref.invalidateSelf();
  }

  Future<void> updateUserName(String userName) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyUserName, userName);
    ref.invalidateSelf();
  }

  Future<void> resetOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyOnboardingDone);
    await prefs.remove(_keyUserName);
    ref.invalidateSelf();
  }
}

final preferencesNotifierProvider =
AsyncNotifierProvider<PreferencesNotifier, Map<String, dynamic>>(
    PreferencesNotifier.new);
