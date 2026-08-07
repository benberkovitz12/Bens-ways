import 'package:cloud_firestore/cloud_firestore.dart';

// ─────────────────────────────────────────────────────────────────
//  SEED SCRIPT — BATCH 3 (FINAL): trails 27–36
//
//  The last ten trails, completing the set of 36. Same combined
//  structure (base + filter fields in one .set() per trail).
//
//  ⚠️ pathPoints are TRAILHEAD-ONLY STUBS by design (real GPX later).
//
//  HOW TO RUN:
//  1. In main.dart:  import 'scripts/seed_trails_27_36.dart';
//     and after Firebase.initializeApp():  await seedTrails27to36();
//  2. flutter run once, watch for: 🎉 Trails 27–36 seeded! (36 total)
//  3. Comment both lines back out.
// ─────────────────────────────────────────────────────────────────

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
    'name': name,
    'description': description,
    'difficulty': difficulty,
    'distanceKm': distanceKm,
    'duration': duration,
    'imageUrl': '',
    'startLat': startLat,
    'startLng': startLng,
    'startRadiusMeters': 100,
    'pathPoints': [
      {'lat': startLat, 'lng': startLng},
    ],
    'region': region,
    'isWet': isWet,
    'attractions': attractions,
    'entryFee': entryFee,
    'participantType': ['משפחתי'],
    'distanceKmNum': distanceKmNum,
    'durationHoursNum': durationHoursNum,
  };
}

Future<void> seedTrails27to36() async {
  final db = FirebaseFirestore.instance;

  // trail_27 : תל דן — הגליל העליון
  await db.collection('trails').doc('trail_27').set(_fullTrailDoc(
        name: 'שמורת תל דן',
        description:
            'הנחל השופע בישראל זורם בין עצים סבוכים, ולצדו שער כנעני בן 4,000 שנה ועיר מקראית עתיקה.',
        difficulty: 'קל',
        distanceKm: '2',
        duration: 'עד 2 שעות',
        startLat: 33.2480,
        startLng: 35.6520,
        region: 'הגליל העליון',
        isWet: true,
        attractions: ['נחל', 'מעיין'],
        entryFee: 'בתשלום',
        distanceKmNum: 2,
        durationHoursNum: 2,
      ));
  print('✅ trail_27 (תל דן) seeded!');

  // trail_28 : ראש הנקרה — הגליל העליון (חוף)
  await db.collection('trails').doc('trail_28').set(_fullTrailDoc(
        name: 'נקרות ראש הנקרה',
        description:
            'מערות ים לבנות שנחצבו בגלים בקצה הצפוני של החוף — רכבל תלול, נקיקים וגלים מתנפצים.',
        difficulty: 'קל',
        distanceKm: '1',
        duration: 'עד 2 שעות',
        startLat: 33.0930,
        startLng: 35.1050,
        region: 'הגליל העליון',
        isWet: false,
        attractions: ['תצפית'],
        entryFee: 'בתשלום',
        distanceKmNum: 1,
        durationHoursNum: 2,
      ));
  print('✅ trail_28 (ראש הנקרה) seeded!');

  // trail_29 : רמת הנדיב — הכרמל והחוף
  await db.collection('trails').doc('trail_29').set(_fullTrailDoc(
        name: 'רמת הנדיב',
        description:
            'גני זיכרון מטופחים לצד שבילי טבע על שלוחת הכרמל — תצפיות לים, פריחה ועופות דורסים.',
        difficulty: 'קל',
        distanceKm: '3',
        duration: 'עד 3 שעות',
        startLat: 32.5560,
        startLng: 34.9430,
        region: 'הכרמל והחוף',
        isWet: false,
        attractions: ['תצפית'],
        entryFee: 'חינם',
        distanceKmNum: 3,
        durationHoursNum: 3,
      ));
  print('✅ trail_29 (רמת הנדיב) seeded!');

  // trail_30 : הקסטל — ירושלים והסביבה
  await db.collection('trails').doc('trail_30').set(_fullTrailDoc(
        name: 'גן לאומי הקסטל',
        description:
            'אתר מורשת מקרבות תש״ח בפסגה השולטת על הדרך לירושלים — תעלות, בונקרים ותצפית פנורמית.',
        difficulty: 'קל',
        distanceKm: '1.5',
        duration: 'עד 2 שעות',
        startLat: 31.7908,
        startLng: 35.1417,
        region: 'ירושלים והסביבה',
        isWet: false,
        attractions: ['הרים', 'תצפית'],
        entryFee: 'בתשלום',
        distanceKmNum: 1.5,
        durationHoursNum: 2,
      ));
  print('✅ trail_30 (הקסטל) seeded!');

  // trail_31 : עינות צוקים (עין פשחה) — צפון ים המלח
  await db.collection('trails').doc('trail_31').set(_fullTrailDoc(
        name: 'עינות צוקים (עין פשחה)',
        description:
            'השמורה הנמוכה בעולם — נווה מעיינות על חוף ים המלח עם בריכות טבילה צלולות בלב מלחה.',
        difficulty: 'קל',
        distanceKm: '2',
        duration: 'עד 3 שעות',
        startLat: 31.7160,
        startLng: 35.4530,
        region: 'הבקעה והעמקים',
        isWet: true,
        attractions: ['מעיין'],
        entryFee: 'בתשלום',
        distanceKmNum: 2,
        durationHoursNum: 3,
      ));
  print('✅ trail_31 (עינות צוקים) seeded!');

  // trail_32 : פארק תמנע — הנגב הדרומי
  await db.collection('trails').doc('trail_32').set(_fullTrailDoc(
        name: 'פארק תמנע',
        description:
            'עמודי שלמה, הפטרייה ומכרות הנחושת העתיקים בעולם — נופי מדבר אדומים צפונית לאילת.',
        difficulty: 'בינוני',
        distanceKm: '4',
        duration: 'עד 4 שעות',
        startLat: 29.7860,
        startLng: 34.9600,
        region: 'הנגב',
        isWet: false,
        attractions: ['הרים', 'תצפית'],
        entryFee: 'בתשלום',
        distanceKmNum: 4,
        durationHoursNum: 4,
      ));
  print('✅ trail_32 (תמנע) seeded!');

  // trail_33 : אגמון החולה — הגליל העליון
  await db.collection('trails').doc('trail_33').set(_fullTrailDoc(
        name: 'אגמון החולה',
        description:
            'מוקד נדידת הציפורים של ישראל — עשרות אלפי עגורים בחורף, שבילים שטוחים סביב האגם.',
        difficulty: 'קל',
        distanceKm: '8',
        duration: 'עד 3 שעות',
        startLat: 33.1110,
        startLng: 35.6070,
        region: 'הגליל העליון',
        isWet: false,
        attractions: ['תצפית'],
        entryFee: 'חינם',
        distanceKmNum: 8,
        durationHoursNum: 3,
      ));
  print('✅ trail_33 (אגמון החולה) seeded!');

  // trail_34 : שמורת האירוסים — השרון והמרכז
  await db.collection('trails').doc('trail_34').set(_fullTrailDoc(
        name: 'שמורת האירוסים (נתניה)',
        description:
            'שמורה עירונית על כורכר נתניה — פריחת אירוס הארגמן המרהיבה בסוף החורף ותחילת האביב.',
        difficulty: 'קל',
        distanceKm: '2',
        duration: 'עד 2 שעות',
        startLat: 32.2870,
        startLng: 34.8440,
        region: 'השרון והמרכז',
        isWet: false,
        attractions: ['תצפית'],
        entryFee: 'חינם',
        distanceKmNum: 2,
        durationHoursNum: 2,
      ));
  print('✅ trail_34 (שמורת האירוסים) seeded!');

  // trail_35 : ציפורי — הגליל התחתון
  await db.collection('trails').doc('trail_35').set(_fullTrailDoc(
        name: 'גן לאומי ציפורי',
        description:
            'בירת הגליל העתיקה — פסיפס "המונה ליזה של הגליל", תיאטרון רומי ומערכת מים תת־קרקעית.',
        difficulty: 'קל',
        distanceKm: '2.5',
        duration: 'עד 3 שעות',
        startLat: 32.7530,
        startLng: 35.2790,
        region: 'הגליל התחתון',
        isWet: false,
        attractions: ['תצפית'],
        entryFee: 'בתשלום',
        distanceKmNum: 2.5,
        durationHoursNum: 3,
      ));
  print('✅ trail_35 (ציפורי) seeded!');

  // trail_36 : בית גוברין — שפלת יהודה
  await db.collection('trails').doc('trail_36').set(_fullTrailDoc(
        name: 'גן לאומי בית גוברין',
        description:
            'אתר מורשת עולמית — מערות הפעמון הענקיות, מערות קבורה מעוטרות ותל מרשה העתיקה בשפלה.',
        difficulty: 'קל',
        distanceKm: '3',
        duration: 'עד 3 שעות',
        startLat: 31.6060,
        startLng: 34.8980,
        region: 'ירושלים והסביבה',
        isWet: false,
        attractions: ['תצפית'],
        entryFee: 'בתשלום',
        distanceKmNum: 3,
        durationHoursNum: 3,
      ));
  print('✅ trail_36 (בית גוברין) seeded!');

  print('🎉 Trails 27–36 seeded! (36 total)');
}
