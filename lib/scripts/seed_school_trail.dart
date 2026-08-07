import 'package:cloud_firestore/cloud_firestore.dart';

// ─────────────────────────────────────────────────────────────────
//  SEED: DEMO TRAIL AT AFEKA  (one-time script, run-then-comment-out)
//
//  Creates trail_37 — a demo trail whose GPS gate sits on the Afeka
//  College of Engineering campus (מתחם פיקוס, מבצע קדש 38, תל אביב),
//  so tomorrow the on-trail check passes LIVE in the room and the
//  chat opens in free-writing mode.
//
//  Coordinates: 32.1149152, 34.8181039 (the campus itself).
//  Radius: 300m — generous on purpose; indoor GPS is flaky.
//
//  HOW TO RUN (the usual ritual):
//    1. In main.dart add:   import 'scripts/seed_school_trail.dart';
//    2. After Firebase.initializeApp(...):   await seedSchoolTrail();
//    3. flutter run -d TB330FU --release   (once)
//    4. Comment BOTH lines back out (import + call together!).
//
//  AFTER THE DEMO: just delete the trail_37 document in the console.
// ─────────────────────────────────────────────────────────────────

Future<void> seedSchoolTrail() async {
  final db = FirebaseFirestore.instance;

  await db.collection('trails').doc('trail_37').set({
    'name': 'מסלול אפקה 🎓',
    'region': 'מרכז',
    'description': 'מסלול הדגמה מיוחד במתחם פיקוס של מכללת אפקה להנדסה — '
        'כאן נולדה האפליקציה בדרכי בן. המסלול נפתח רק כשמגיעים '
        'פיזית לקמפוס, בדיוק כמו כל מסלול אמיתי.',
    'distanceKm': '1',
    'duration': 'עד שעה',
    'difficulty': 'קל',
    'isWet': false,
    'entryFee': 'חינם',
    'attractions': ['תצפית'],
    'participantType': ['קבוצתי'],
    'startLat': 32.1149152,
    'startLng': 34.8181039,
    'startRadiusMeters': 300,
    'distanceKmNum': 1,
    'durationHoursNum': 1,
    'imageUrl': '',
    // A tiny loop around the campus so live mode has a polyline to draw.
    'pathPoints': [
      {'lat': 32.1149152, 'lng': 34.8181039},
      {'lat': 32.1153800, 'lng': 34.8186500},
      {'lat': 32.1149900, 'lng': 34.8192200},
      {'lat': 32.1144600, 'lng': 34.8187000},
      {'lat': 32.1149152, 'lng': 34.8181039},
    ],
  });

  // ignore: avoid_print
  print('✓ trail_37 (מסלול אפקה) seeded — GPS gate armed at the campus.');
}
