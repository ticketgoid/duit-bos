import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'providers/preferences_provider.dart';
import 'screens/home_screen.dart';
import 'screens/onboarding_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID', null);
  runApp(const ProviderScope(child: DuitBosApp()));
}

class DuitBosApp extends StatelessWidget {
  const DuitBosApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Duit Bos',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: const ColorScheme.light(
          primary: Color(0xFFFF8FAB),
          secondary: Color(0xFFA8D8EA),
          tertiary: Color(0xFFB8F0C8),
          surface: Color(0xFFFFF9F0),
          onPrimary: Colors.white,
        ),
        scaffoldBackgroundColor: const Color(0xFFFFF9F0),
        textTheme: GoogleFonts.nunitoTextTheme().copyWith(
          displayLarge: GoogleFonts.nunito(
            fontSize: 32,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF5C4A6E),
          ),
          titleLarge: GoogleFonts.nunito(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF5C4A6E),
          ),
          bodyMedium: GoogleFonts.nunito(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF5C4A6E),
          ),
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFFF8FAB),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            textStyle: GoogleFonts.nunito(
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
      home: const _AppEntry(),
    );
  }
}

class _AppEntry extends ConsumerWidget {
  const _AppEntry();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final onboardingAsync = ref.watch(onboardingDoneProvider);
    return onboardingAsync.when(
      data: (done) => done ? const HomeScreen() : const OnboardingScreen(),
      loading: () => const Scaffold(
        backgroundColor: Color(0xFFF0E6FF),
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => const OnboardingScreen(),
    );
  }
}
