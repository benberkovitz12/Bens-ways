import 'package:cloud_firestore/cloud_firestore.dart';

// ─────────────────────────────────────────────────────────────────
//  SEED SCRIPT — BATCH 1: trails 7–16
//
//  Ten real Israeli trails with verified/accurate trailhead coords.
//  Each doc is COMPLETE (base fields + filter fields in one .set()),
//  so this runs ONCE and needs no second seedFilterFields pass.
//
//  ⚠️ pathPoints are TRAILHEAD-ONLY STUBS by design. Real route
//  traces (GPX from Israel Hiking Map etc.) replace them later.
//  Inventing route coordinates for a hiking app is dangerous —
//  the trailhead point is accurate; the path drawing is deferred.
//
//  HOW TO RUN:
//  1. In main.dart:  import 'scripts/seed_trails_7_16.dart';
//     and after Firebase.initializeApp():  await seedTrails7to16();
//  2. flutter run once, watch for: 🎉 Trails 7–16 seeded!
//  3. Comment both lines back out.
//
//  VERIFY AFTER SEEDING (batch check before batch 2):
//  - Firestore console → trails → trail_7 … trail_16 exist
//  - מותאם wizard → filter by region → new trails appear
//  - Open a new trail's profile → loads, map centers on trailhead
// ─────────────────────────────────────────────────────────────────

// One complete trail document: base fields + filter fields together.
Map<String, dynamic> _fullTrailDoc({
  required String name,
  required String description,
  required String difficulty,
  required String distanceKm,
  required String duration,
  required double startLat,
  required double startLng,
  required String region,
  required bool isWet,
  required List<String> attractions,
  required String entryFee,
  required double distanceKmNum,
  required double durationHoursNum,
}) {
  return {
    // ── base fields (same shape as trails 1–6) ──
    'name': name,
    'description': description,
    'difficulty': difficulty,
    'distanceKm': distanceKm,
    'duration': duration,
    'imageUrl': '',
    'startLat': startLat,
    'startLng': startLng,
    'startRadiusMeters': 100,
    // Trailhead-only stub — replace with real GPX trace later.
    'pathPoints': [
      {'lat': startLat, 'lng': startLng},
    ],
    // ── filter fields (same shape as seedFilterFields) ──
    'region': region,
    'isWet': isWet,
    'attractions': attractions,
    'entryFee': entryFee,
    'participantType': ['משפחתי'],
    'distanceKmNum': distanceKmNum,
    'durationHoursNum': durationHoursNum,
  };
}

Future<void> seedTrails7to16() async {
  final db = FirebaseFirestore.instance;

  // trail_7 : נחל דוד (עין גדי) — מדבר יהודה / בקעת ים המלח
  await db.collection('trails').doc('trail_7').set(_fullTrailDoc(
        name: 'נחל דוד (עין גדי)',
        description:
            'נווה מדבר שופע מעל ים המלח — פלג זורם, בריכות ומפל דוד, עם יעלים ושפני סלע לאורך הדרך.',
        difficulty: 'קל',
        distanceKm: '2',
        duration: 'עד 2 שעות',
        startLat: 31.4614,
        startLng: 35.3888,
        region: 'הבקעה והעמקים',
        isWet: true,
        attractions: ['נחל', 'מפלים'],
        entryFee: 'בתשלום',
        distanceKmNum: 2,
        durationHoursNum: 2,
      ));
  print('✅ trail_7 (נחל דוד עין גדי) seeded!');

  // trail_8 : שמורת נחל מערות — הכרמל
  await db.collection('trails').doc('trail_8').set(_fullTrailDoc(
        name: 'שמורת נחל מערות',
        description:
            'אתר מורשת עולמית במצוק הכרמל — מערות פרהיסטוריות ושביל נוף קצר ונעים המתאים לכל המשפחה.',
        difficulty: 'קל',
        distanceKm: '1.5',
        duration: 'עד 2 שעות',
        startLat: 32.6706,
        startLng: 34.9664,
        region: 'הכרמל והחוף',
        isWet: false,
        attractions: ['הרים', 'תצפית'],
        entryFee: 'בתשלום',
        distanceKmNum: 1.5,
        durationHoursNum: 2,
      ));
  print('✅ trail_8 (נחל מערות) seeded!');

  // trail_9 : עין פרת (נחל פרת / ואדי קלט) — צפון מדבר יהודה
  await db.collection('trails').doc('trail_9').set(_fullTrailDoc(
        name: 'עין פרת (נחל פרת)',
        description:
            'קניון מדברי עם מעיין שופע, בריכות טבעיות ומנזר עתיק. שימו לב: הכניסה ברישום מראש בלבד.',
        difficulty: 'קל',
        distanceKm: '3',
        duration: 'עד 3 שעות',
        startLat: 31.8330,
        startLng: 35.3060,
        region: 'יהודה ושומרון',
        isWet: true,
        attractions: ['מעיין', 'נחל'],
        entryFee: 'בתשלום',
        distanceKmNum: 3,
        durationHoursNum: 3,
      ));
  print('✅ trail_9 (עין פרת) seeded!');

  // trail_10 : סטף — הרי ירושלים
  await db.collection('trails').doc('trail_10').set(_fullTrailDoc(
        name: 'סטף',
        description:
            'טרסות חקלאות הררית עתיקות, שני מעיינות עם נקבות מים ותצפיות על הרי ירושלים.',
        difficulty: 'קל',
        distanceKm: '2.5',
        duration: 'עד 3 שעות',
        startLat: 31.7767,
        startLng: 35.1225,
        region: 'ירושלים והסביבה',
        isWet: true,
        attractions: ['מעיין', 'תצפית'],
        entryFee: 'חינם',
        distanceKmNum: 2.5,
        durationHoursNum: 3,
      ));
  print('✅ trail_10 (סטף) seeded!');

  // trail_11 : טיילת אלברט, מכתש רמון — הנגב
  await db.collection('trails').doc('trail_11').set(_fullTrailDoc(
        name: 'טיילת מכתש רמון',
        description:
            'טיילת נוף על שפת המכתש הגדול בעולם — תצפיות עוצרות נשימה, פסל האמפיברך ומרכז המבקרים.',
        difficulty: 'קל',
        distanceKm: '2',
        duration: 'עד 2 שעות',
        startLat: 30.6096,
        startLng: 34.8011,
        region: 'הנגב',
        isWet: false,
        attractions: ['תצפית', 'הרים'],
        entryFee: 'חינם',
        distanceKmNum: 2,
        durationHoursNum: 2,
      ));
  print('✅ trail_11 (מכתש רמון) seeded!');

  // trail_12 : שמורת יהודיה — גולן
  await db.collection('trails').doc('trail_12').set(_fullTrailDoc(
        name: 'נחל יהודיה',
        description:
            'מסלול המים המפורסם של הגולן — קניון בזלת, בריכות עמוקות ומפלים. למיטיבי לכת ואוהבי מים.',
        difficulty: 'בינוני',
        distanceKm: '6',
        duration: 'עד 5 שעות',
        startLat: 32.9415,
        startLng: 35.7069,
        region: 'הגליל העליון',
        isWet: true,
        attractions: ['נחל', 'מפלים'],
        entryFee: 'בתשלום',
        distanceKmNum: 6,
        durationHoursNum: 5,
      ));
  print('✅ trail_12 (יהודיה) seeded!');

  // trail_13 : הר תבור, שביל ההקפה — הגליל התחתון
  await db.collection('trails').doc('trail_13').set(_fullTrailDoc(
        name: 'הר תבור — שביל ההקפה',
        description:
            'שביל מעגלי סביב פסגת התבור — תצפיות פנורמיות על עמק יזרעאל, חורש ים־תיכוני וכנסיות היסטוריות.',
        difficulty: 'קל',
        distanceKm: '3',
        duration: 'עד 2 שעות',
        startLat: 32.6857,
        startLng: 35.3872,
        region: 'הגליל התחתון',
        isWet: false,
        attractions: ['הרים', 'תצפית'],
        entryFee: 'חינם',
        distanceKmNum: 3,
        durationHoursNum: 2,
      ));
  print('✅ trail_13 (הר תבור) seeded!');

  // trail_14 : שמורת נחל אלכסנדר — השרון
  await db.collection('trails').doc('trail_14').set(_fullTrailDoc(
        name: 'נחל אלכסנדר (גשר הצבים)',
        description:
            'הליכה שטוחה לאורך הנחל אל גשר הצבים — נקודת התצפית המפורסמת על צבי הנילוס הרכים.',
        difficulty: 'קל',
        distanceKm: '3',
        duration: 'עד 2 שעות',
        startLat: 32.3893,
        startLng: 34.8892,
        region: 'השרון והמרכז',
        isWet: false,
        attractions: ['נחל'],
        entryFee: 'חינם',
        distanceKmNum: 3,
        durationHoursNum: 2,
      ));
  print('✅ trail_14 (נחל אלכסנדר) seeded!');

  // trail_15 : מצדה, שביל הנחש — מדבר יהודה / ים המלח
  await db.collection('trails').doc('trail_15').set(_fullTrailDoc(
        name: 'מצדה — שביל הנחש',
        description:
            'העלייה המיתולוגית למבצר הורדוס מעל ים המלח. מומלץ לצאת לפנות בוקר ולתפוס זריחה מהפסגה.',
        difficulty: 'בינוני',
        distanceKm: '4',
        duration: 'עד 3 שעות',
        startLat: 31.3122,
        startLng: 35.3654,
        region: 'הבקעה והעמקים',
        isWet: false,
        attractions: ['הרים', 'תצפית'],
        entryFee: 'בתשלום',
        distanceKmNum: 4,
        durationHoursNum: 3,
      ));
  print('✅ trail_15 (מצדה) seeded!');

  // trail_16 : גן השלושה (סחנה) — עמק המעיינות
  await db.collection('trails').doc('trail_16').set(_fullTrailDoc(
        name: 'גן השלושה (סחנה)',
        description:
            'בריכות מים טבעיות בטמפרטורה של 28 מעלות כל השנה, מדשאות ומפלונים — מהיפים בעולם לפי TIME.',
        difficulty: 'קל',
        distanceKm: '1',
        duration: 'עד 3 שעות',
        startLat: 32.5058,
        startLng: 35.4438,
        region: 'הבקעה והעמקים',
        isWet: true,
        attractions: ['מעיין'],
        entryFee: 'בתשלום',
        distanceKmNum: 1,
        durationHoursNum: 3,
      ));
  print('✅ trail_16 (גן השלושה) seeded!');

  print('🎉 Trails 7–16 seeded!');
}
