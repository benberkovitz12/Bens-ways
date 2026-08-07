import 'package:cloud_firestore/cloud_firestore.dart';

// ─────────────────────────────────────────────────────────────────
//  SEED SCRIPT — REAL PATHS batch 1: trail_7 (נחל דוד, עין גדי)
//
//  Source: GPX exported from Israel Hiking Map ("Single track GPX"),
//  parsed and downsampled to 60 points.
//
//  Updates THREE fields together (via .update(), nothing else touched):
//    - pathPoints    → the real route polyline
//    - startLat/Lng  → corrected to the route's true starting point.
//      (The GPX revealed our seeded trailhead was ~730m off — the
//      GPS-unlock must sit where the path actually begins.)
//
//  HOW TO RUN (the usual ritual):
//  1. In main.dart:  import 'scripts/seed_paths_1.dart';
//     after Firebase.initializeApp():  await seedPaths1();
//  2. flutter run once → 🎉 real path for trail_7 seeded!
//  3. Comment both lines back out.
// ─────────────────────────────────────────────────────────────────

Future<void> seedPaths1() async {
  final db = FirebaseFirestore.instance;

  await db.collection('trails').doc('trail_7').update({
    'startLat': 31.466082,
    'startLng': 35.394252,
    'pathPoints': [
      {'lat': 31.466082, 'lng': 35.394252},
      {'lat': 31.466095, 'lng': 35.394229},
      {'lat': 31.466321, 'lng': 35.394313},
      {'lat': 31.466613, 'lng': 35.394138},
      {'lat': 31.466941, 'lng': 35.394},
      {'lat': 31.467348, 'lng': 35.393757},
      {'lat': 31.46776, 'lng': 35.393588},
      {'lat': 31.468042, 'lng': 35.393519},
      {'lat': 31.46862, 'lng': 35.393072},
      {'lat': 31.469029, 'lng': 35.39265},
      {'lat': 31.469321, 'lng': 35.392307},
      {'lat': 31.469439, 'lng': 35.39212},
      {'lat': 31.469494, 'lng': 35.392131},
      {'lat': 31.469584, 'lng': 35.391925},
      {'lat': 31.469789, 'lng': 35.391869},
      {'lat': 31.469862, 'lng': 35.391849},
      {'lat': 31.469929, 'lng': 35.39179},
      {'lat': 31.470098, 'lng': 35.391337},
      {'lat': 31.470172, 'lng': 35.391223},
      {'lat': 31.470374, 'lng': 35.391064},
      {'lat': 31.470461, 'lng': 35.390964},
      {'lat': 31.470488, 'lng': 35.390911},
      {'lat': 31.470532, 'lng': 35.390622},
      {'lat': 31.470552, 'lng': 35.39032},
      {'lat': 31.470609, 'lng': 35.39015},
      {'lat': 31.470602, 'lng': 35.389989},
      {'lat': 31.470616, 'lng': 35.38991},
      {'lat': 31.470745, 'lng': 35.389656},
      {'lat': 31.470883, 'lng': 35.389405},
      {'lat': 31.470854, 'lng': 35.389507},
      {'lat': 31.470828, 'lng': 35.389548},
      {'lat': 31.470775, 'lng': 35.389583},
      {'lat': 31.470629, 'lng': 35.389523},
      {'lat': 31.470823, 'lng': 35.389282},
      {'lat': 31.470892, 'lng': 35.38923},
      {'lat': 31.470823, 'lng': 35.389282},
      {'lat': 31.470602, 'lng': 35.389545},
      {'lat': 31.470623, 'lng': 35.389785},
      {'lat': 31.470614, 'lng': 35.389872},
      {'lat': 31.470549, 'lng': 35.389984},
      {'lat': 31.47044, 'lng': 35.390099},
      {'lat': 31.470357, 'lng': 35.390277},
      {'lat': 31.470263, 'lng': 35.390415},
      {'lat': 31.470203, 'lng': 35.390555},
      {'lat': 31.47013, 'lng': 35.390787},
      {'lat': 31.470093, 'lng': 35.390906},
      {'lat': 31.469971, 'lng': 35.391103},
      {'lat': 31.469832, 'lng': 35.391236},
      {'lat': 31.469793, 'lng': 35.391314},
      {'lat': 31.469771, 'lng': 35.391609},
      {'lat': 31.469362, 'lng': 35.392055},
      {'lat': 31.469439, 'lng': 35.39212},
      {'lat': 31.469029, 'lng': 35.39265},
      {'lat': 31.46835, 'lng': 35.393351},
      {'lat': 31.468042, 'lng': 35.393519},
      {'lat': 31.46776, 'lng': 35.393588},
      {'lat': 31.467348, 'lng': 35.393757},
      {'lat': 31.466941, 'lng': 35.394},
      {'lat': 31.466613, 'lng': 35.394138},
      {'lat': 31.466321, 'lng': 35.394313},
    ],
  });
  print('✅ trail_7 (נחל דוד) — real path (60 pts) + corrected trailhead!');

  print('🎉 real path for trail_7 seeded!');
}
