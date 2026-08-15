import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'firebase_options.dart';
import 'theme/app_theme.dart';
import 'screens/home_screen.dart';
import 'screens/auth/login_screen.dart';
import 'services/auth_service.dart';
import 'services/saved_trails_service.dart';
import 'services/updates_read_service.dart';
import 'scripts/seed_trails_7_16.dart';
import 'scripts/seed_trails_17_26.dart';
import 'scripts/seed_trails_27_36.dart';
import 'scripts/seed_pois_1_12.dart';
import 'scripts/seed_pois_13_24.dart';
import 'scripts/seed_pois_25_36.dart';
import 'scripts/seed_paths_1.dart';
import 'scripts/seed_paths_1_12.dart';
import 'scripts/seed_paths_13_27.dart';
import 'scripts/seed_paths_28_36.dart';
import 'services/completed_trails_service.dart';
import 'scripts/seed_school_trail.dart';

// import 'scripts/seed_trail.dart'; // ← seeding done; re-enable only to re-seed

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  // await seedTrails7to16();
  // await seedTrails17to26();
  // await seedTrails27to36();
  // seedPois1to12();
  // await seedPois13to24();
  // await seedPois25to36();
  // await seedPaths1();
  // await seedPaths1to12();
  // await seedPaths13to27();
  // await seedPaths28to36();
  await seedSchoolTrail();
  await SavedTrailsService.instance.init();
  await CompletedTrailsService.instance.init();
  await UpdatesReadService.instance.init();

  // Seeding is finished — leave this commented out.
  // To re-seed, uncomment the import above AND the matching line below,
  // run once, then comment both out again.
  // await seedFilterFields();

  runApp(const BensWayApp());
}

class BensWayApp extends StatelessWidget {
  const BensWayApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Ben Ways",
      debugShowCheckedModeBanner: false,

      // ── RTL + Hebrew locale ───────────────────────────────────
      locale: const Locale('he', 'IL'),
      supportedLocales: const [
        Locale('he', 'IL'),
        Locale('en', 'US'),
      ],
      // These delegates provide MaterialLocalizations to ALL
      // widgets including TabBar.
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],

      // ── FORCE RTL FOR THE ENTIRE APP ──────────────────────────
      //  This wraps EVERY screen the app ever shows in a right-to-left
      //  Directionality. Because it lives here at the MaterialApp root,
      //  every screen, card, dialog, and future search bar inherits RTL
      //  automatically — you never have to wrap a screen by hand again.
      //
      //  This is the single fix for the "text hugs the left" bug: widgets
      //  using CrossAxisAlignment.end / TextAlign.right now resolve to the
      //  RIGHT side, because the ambient direction is finally RTL.
      builder: (context, child) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: child!,
        );
      },

      // ── Design theme ──────────────────────────────────────────
      theme: AppTheme.theme,

      // ── First screen ──────────────────────────────────────────
      //  The AuthGate decides: logged in → HomeScreen, logged out →
      //  LoginScreen. It reacts live, so signing in/out swaps screens
      //  automatically with no manual navigation.
      home: const AuthGate(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
//  AUTH GATE
//  Watches Firebase auth state and shows the right root screen:
//    - while the very first auth check resolves → a splash spinner
//    - logged in  → HomeScreen
//    - logged out → LoginScreen
//
//  Because it's a StreamBuilder on authStateChanges, calling
//  AuthService.signOut() anywhere in the app instantly returns the
//  user here to the login screen — no manual navigation needed.
// ─────────────────────────────────────────────────────────────────
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: AuthService.instance.authStateChanges,
      builder: (context, snapshot) {
        // First emission still pending → brief splash.
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: AppTheme.bg,
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // Logged in if there's a user object, else show login.
        final loggedIn = snapshot.data != null;
        return loggedIn ? const HomeScreen() : const LoginScreen();
      },
    );
  }
}
