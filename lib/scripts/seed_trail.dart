import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../firebase_options.dart';
import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────────
//  SEED SCRIPT
//
//  This file now holds TWO seed functions:
//
//  1. seedAllTrails()        — (already run) created trails 2–6.
//  2. seedFilterFields()     — NEW. Adds the filter-wizard fields to
//                              ALL 6 trails. Run this ONCE.
//
//  HOW TO RUN seedFilterFields():
//  1. In main.dart, uncomment the import + call `seedFilterFields()`.
//  2. flutter run -d TB330FU --release   (or debug to see prints)
//  3. Watch for: 🎉 Filter fields added to all trails!
//  4. Comment the call + import back out so it never re-runs.
//
//  WHY .update() and not .set():
//  .update() merges these new fields INTO the existing documents
//  without erasing name, description, pathPoints, GPS, etc.
//  (.set() would overwrite the whole document — we don't want that.)
// ─────────────────────────────────────────────────────────────────

// ╔═══════════════════════════════════════════════════════════════╗
// ║  FUNCTION 2 (NEW): add filter fields to all 6 trails           ║
// ╚═══════════════════════════════════════════════════════════════╝

// Helper: the new filter fields for one trail, as a Map.
Map<String, dynamic> _filterFields({
  required String region,
  required bool isWet,
  required List<String> attractions,
  required String entryFee,
  required List<String> participantType,
  required double distanceKmNum,
  required double durationHoursNum,
}) {
  return {
    'region': region,
    'isWet': isWet,
    'attractions': attractions,
    'entryFee': entryFee,
    'participantType': participantType,
    'distanceKmNum': distanceKmNum,
    'durationHoursNum': durationHoursNum,
  };
}

Future<void> seedFilterFields() async {
  final db = FirebaseFirestore.instance;

  // trail_1 : נחל חרמון (הבניאס) — Upper Galilee, wet
  await db.collection('trails').doc('trail_1').update(_filterFields(
        region: 'הגליל העליון',
        isWet: true,
        attractions: ['נחל', 'מפלים'],
        entryFee: 'בתשלום',
        participantType: ['משפחתי'],
        distanceKmNum: 2.5,
        durationHoursNum: 3,
      ));
  print('✅ trail_1 filter fields added!');

  // trail_2 : שמורת מג׳רסה — Jordan Valley & Vales, wet
  await db.collection('trails').doc('trail_2').update(_filterFields(
        region: 'הבקעה והעמקים',
        isWet: true,
        attractions: ['נחל'],
        entryFee: 'בתשלום',
        participantType: ['משפחתי'],
        distanceKmNum: 2,
        durationHoursNum: 4,
      ));
  print('✅ trail_2 filter fields added!');

  // trail_3 : הר בנטל — Upper Galilee / Golan, dry
  await db.collection('trails').doc('trail_3').update(_filterFields(
        region: 'הגליל העליון',
        isWet: false,
        attractions: ['הרים', 'תצפית'],
        entryFee: 'חינם',
        participantType: ['משפחתי'],
        distanceKmNum: 3,
        durationHoursNum: 4,
      ));
  print('✅ trail_3 filter fields added!');

  // trail_4 : גן לאומי עין עבדת — Negev, wet
  await db.collection('trails').doc('trail_4').update(_filterFields(
        region: 'הנגב',
        isWet: true,
        attractions: ['מפלים', 'נחל'],
        entryFee: 'בתשלום',
        participantType: ['משפחתי'],
        distanceKmNum: 7,
        durationHoursNum: 3,
      ));
  print('✅ trail_4 filter fields added!');

  // trail_5 : שביל הפסגה (הר מירון) — Lower Galilee, dry
  await db.collection('trails').doc('trail_5').update(_filterFields(
        region: 'הגליל התחתון',
        isWet: false,
        attractions: ['הרים', 'מעיין', 'תצפית'],
        entryFee: 'חינם',
        participantType: ['משפחתי'],
        distanceKmNum: 1.5,
        durationHoursNum: 3,
      ));
  print('✅ trail_5 filter fields added!');

  // trail_6 : שמורת נחל שניר — Upper Galilee, wet
  await db.collection('trails').doc('trail_6').update(_filterFields(
        region: 'הגליל העליון',
        isWet: true,
        attractions: ['נחל'],
        entryFee: 'בתשלום',
        participantType: ['משפחתי'],
        distanceKmNum: 2,
        durationHoursNum: 3,
      ));
  print('✅ trail_6 filter fields added!');

  print('🎉 Filter fields added to all trails!');
}

// ╔═══════════════════════════════════════════════════════════════╗
// ║  FUNCTION 1 (already run): create trails 2–6                   ║
// ║  Kept here for reference / re-seeding. Do NOT run again unless ║
// ║  you want to overwrite trails 2–6 back to these base values.   ║
// ╚═══════════════════════════════════════════════════════════════╝

Map<String, dynamic> _trailDoc({
  required String name,
  required String description,
  required String difficulty,
  required String distanceKm,
  required String duration,
  required double startLat,
  required double startLng,
  required List<Map<String, double>> pathPoints,
}) {
  return {
    'name': name,
    'description': description,
    'difficulty': difficulty,
    'distanceKm': distanceKm,
    'duration': duration,
    'imageUrl': '',
    'startLat': startLat,
    'startLng': startLng,
    'startRadiusMeters': 100,
    'pathPoints': pathPoints,
  };
}

Future<void> seedAllTrails() async {
  final db = FirebaseFirestore.instance;

  await db.collection('trails').doc('trail_2').set(_trailDoc(
        name: 'שמורת מג׳רסה',
        description:
            'מסלול מים בתוך נחל רדוד בין קנים, עצים וצמחייה בצפון הכנרת.',
        difficulty: 'קל',
        distanceKm: '1-2',
        duration: 'עד 4 שעות',
        startLat: 32.9050,
        startLng: 35.6310,
        pathPoints: [
          {'lat': 32.9050, 'lng': 35.6310},
          {'lat': 32.9054, 'lng': 35.6316},
          {'lat': 32.9059, 'lng': 35.6321},
          {'lat': 32.9063, 'lng': 35.6327},
          {'lat': 32.9068, 'lng': 35.6332},
          {'lat': 32.9072, 'lng': 35.6338},
          {'lat': 32.9077, 'lng': 35.6343},
          {'lat': 32.9081, 'lng': 35.6349},
          {'lat': 32.9086, 'lng': 35.6354},
          {'lat': 32.9090, 'lng': 35.6360},
        ],
      ));
  print('✅ trail_2 (מג׳רסה) seeded!');

  await db.collection('trails').doc('trail_3').set(_trailDoc(
        name: 'הר בנטל',
        description:
            'הר געש כבוי עם תצפית פתוחה על רמת הגולן, החרמון וגבול סוריה.',
        difficulty: 'בינוני',
        distanceKm: '1-3',
        duration: 'עד 4 שעות',
        startLat: 33.1175,
        startLng: 35.7820,
        pathPoints: [
          {'lat': 33.1175, 'lng': 35.7820},
          {'lat': 33.1179, 'lng': 35.7826},
          {'lat': 33.1183, 'lng': 35.7831},
          {'lat': 33.1187, 'lng': 35.7837},
          {'lat': 33.1191, 'lng': 35.7842},
          {'lat': 33.1195, 'lng': 35.7848},
          {'lat': 33.1199, 'lng': 35.7853},
          {'lat': 33.1203, 'lng': 35.7859},
          {'lat': 33.1207, 'lng': 35.7864},
          {'lat': 33.1211, 'lng': 35.7870},
        ],
      ));
  print('✅ trail_3 (הר בנטל) seeded!');

  await db.collection('trails').doc('trail_4').set(_trailDoc(
        name: 'גן לאומי עין עבדת',
        description:
            'פארק מוגן בערוץ עמוק עם שבילים הנמתחים לאורכו ומובילים למפל.',
        difficulty: 'קל',
        distanceKm: '5-17',
        duration: 'עד 3 שעות',
        startLat: 30.8320,
        startLng: 34.7700,
        pathPoints: [
          {'lat': 30.8320, 'lng': 34.7700},
          {'lat': 30.8324, 'lng': 34.7705},
          {'lat': 30.8329, 'lng': 34.7709},
          {'lat': 30.8333, 'lng': 34.7714},
          {'lat': 30.8338, 'lng': 34.7718},
          {'lat': 30.8342, 'lng': 34.7723},
          {'lat': 30.8347, 'lng': 34.7727},
          {'lat': 30.8351, 'lng': 34.7732},
          {'lat': 30.8356, 'lng': 34.7736},
          {'lat': 30.8360, 'lng': 34.7741},
        ],
      ));
  print('✅ trail_4 (עין עבדת) seeded!');

  await db.collection('trails').doc('trail_5').set(_trailDoc(
        name: 'שביל הפסגה',
        description:
            'שביל הפסגה בהר מירון — הרים, חורשים, צמחים, מעיינות ותצפיות.',
        difficulty: 'קל',
        distanceKm: '1.5',
        duration: 'עד 3 שעות',
        startLat: 32.9990,
        startLng: 35.4080,
        pathPoints: [
          {'lat': 32.9990, 'lng': 35.4080},
          {'lat': 32.9994, 'lng': 35.4085},
          {'lat': 32.9998, 'lng': 35.4091},
          {'lat': 33.0002, 'lng': 35.4096},
          {'lat': 33.0006, 'lng': 35.4102},
          {'lat': 33.0010, 'lng': 35.4107},
          {'lat': 33.0014, 'lng': 35.4113},
          {'lat': 33.0018, 'lng': 35.4118},
          {'lat': 33.0022, 'lng': 35.4124},
          {'lat': 33.0026, 'lng': 35.4129},
        ],
      ));
  print('✅ trail_5 (שביל הפסגה) seeded!');

  await db.collection('trails').doc('trail_6').set(_trailDoc(
        name: 'שמורת נחל שניר',
        description: 'מסלול הליכה קליל לאורך פלג מים קריר, עם טבע ירוק ושופע.',
        difficulty: 'קל',
        distanceKm: '2',
        duration: 'עד 3 שעות',
        startLat: 33.2410,
        startLng: 35.6210,
        pathPoints: [
          {'lat': 33.2410, 'lng': 35.6210},
          {'lat': 33.2414, 'lng': 35.6216},
          {'lat': 33.2418, 'lng': 35.6221},
          {'lat': 33.2422, 'lng': 35.6227},
          {'lat': 33.2426, 'lng': 35.6232},
          {'lat': 33.2430, 'lng': 35.6238},
          {'lat': 33.2434, 'lng': 35.6243},
          {'lat': 33.2438, 'lng': 35.6249},
          {'lat': 33.2442, 'lng': 35.6254},
          {'lat': 33.2446, 'lng': 35.6260},
        ],
      ));
  print('✅ trail_6 (נחל שניר) seeded!');

  print('🎉 All trails (2–6) seeded successfully!');
}
