import 'package:cloud_firestore/cloud_firestore.dart';

// ─────────────────────────────────────────────────────────────────
//  SEED SCRIPT — BATCH 2: trails 17–26
//
//  Ten more real Israeli trails, same combined structure as batch 1
//  (base fields + filter fields in one .set() per trail).
//
//  ⚠️ pathPoints are TRAILHEAD-ONLY STUBS by design (real GPX later).
//
//  HOW TO RUN:
//  1. In main.dart:  import 'scripts/seed_trails_17_26.dart';
//     and after Firebase.initializeApp():  await seedTrails17to26();
//  2. flutter run once, watch for: 🎉 Trails 17–26 seeded!
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

Future<void> seedTrails17to26() async {
  final db = FirebaseFirestore.instance;

  // trail_17 : נחל עמוד — הגליל העליון
  await db.collection('trails').doc('trail_17').set(_fullTrailDoc(
        name: 'נחל עמוד',
        description:
            'מהנחלים היפים בגליל — פלג זורם, טחנות קמח עתיקות ועמוד הסלע המפורסם שנתן לנחל את שמו.',
        difficulty: 'בינוני',
        distanceKm: '5',
        duration: 'עד 4 שעות',
        startLat: 32.9107,
        startLng: 35.4988,
        region: 'הגליל העליון',
        isWet: true,
        attractions: ['נחל', 'מעיין'],
        entryFee: 'בתשלום',
        distanceKmNum: 5,
        durationHoursNum: 4,
      ));
  print('✅ trail_17 (נחל עמוד) seeded!');

  // trail_18 : חוף דור הבונים — הכרמל והחוף
  await db.collection('trails').doc('trail_18').set(_fullTrailDoc(
        name: 'שמורת חוף דור הבונים',
        description:
            'רצועת החוף הסלעית היפה בישראל — מפרצונים, לגונות וכוכי גיר לאורך שביל חופי מרהיב.',
        difficulty: 'קל',
        distanceKm: '3',
        duration: 'עד 2 שעות',
        startLat: 32.6427,
        startLng: 34.9235,
        region: 'הכרמל והחוף',
        isWet: false,
        attractions: ['תצפית'],
        entryFee: 'בתשלום',
        distanceKmNum: 3,
        durationHoursNum: 2,
      ));
  print('✅ trail_18 (דור הבונים) seeded!');

  // trail_19 : עין חמד (אקווה בלה) — ירושלים והסביבה
  await db.collection('trails').doc('trail_19').set(_fullTrailDoc(
        name: 'עין חמד (אקווה בלה)',
        description:
            'גן לאומי ירוק בפאתי ירושלים — נחל קטן, מדשאות, ושרידי מצודה צלבנית. מושלם לפיקניק משפחתי.',
        difficulty: 'קל',
        distanceKm: '1',
        duration: 'עד 2 שעות',
        startLat: 31.7997,
        startLng: 35.1310,
        region: 'ירושלים והסביבה',
        isWet: true,
        attractions: ['נחל'],
        entryFee: 'בתשלום',
        distanceKmNum: 1,
        durationHoursNum: 2,
      ));
  print('✅ trail_19 (עין חמד) seeded!');

  // trail_20 : שמורת התנור (נחל עיון) — הגליל העליון
  await db.collection('trails').doc('trail_20').set(_fullTrailDoc(
        name: 'שמורת התנור — נחל עיון',
        description:
            'מסלול מפלים במטולה — מפל התנור הגבוה, מפל הטחנה ותעלות מים היסטוריות בקצה הצפון.',
        difficulty: 'קל',
        distanceKm: '2.5',
        duration: 'עד 2 שעות',
        startLat: 33.2680,
        startLng: 35.5770,
        region: 'הגליל העליון',
        isWet: false,
        attractions: ['מפלים', 'נחל'],
        entryFee: 'בתשלום',
        distanceKmNum: 2.5,
        durationHoursNum: 2,
      ));
  print('✅ trail_20 (התנור) seeded!');

  // trail_21 : נחל חווארים — הנגב
  await db.collection('trails').doc('trail_21').set(_fullTrailDoc(
        name: 'נחל חווארים',
        description:
            'קניון קירטון לבן וסוריאליסטי ליד מדרשת בן־גוריון — נוף ירחי שמתחיל ממש מצוקי הצין.',
        difficulty: 'קל',
        distanceKm: '4',
        duration: 'עד 3 שעות',
        startLat: 30.8510,
        startLng: 34.7800,
        region: 'הנגב',
        isWet: false,
        attractions: ['תצפית'],
        entryFee: 'חינם',
        distanceKmNum: 4,
        durationHoursNum: 3,
      ));
  print('✅ trail_21 (נחל חווארים) seeded!');

  // trail_22 : תל אפק (אנטיפטריס) — השרון והמרכז
  await db.collection('trails').doc('trail_22').set(_fullTrailDoc(
        name: 'תל אפק (אנטיפטריס)',
        description:
            'גן לאומי במקורות הירקון — מצודה עות׳מאנית, שרידים רומיים ואגם החורף, דקות מראש העין.',
        difficulty: 'קל',
        distanceKm: '2',
        duration: 'עד 2 שעות',
        startLat: 32.1047,
        startLng: 34.9296,
        region: 'השרון והמרכז',
        isWet: false,
        attractions: ['תצפית'],
        entryFee: 'בתשלום',
        distanceKmNum: 2,
        durationHoursNum: 2,
      ));
  print('✅ trail_22 (תל אפק) seeded!');

  // trail_23 : נחל כזיב (מבצר מונפור) — הגליל העליון
  await db.collection('trails').doc('trail_23').set(_fullTrailDoc(
        name: 'נחל כזיב ומבצר מונפור',
        description:
            'נחל איתן בגליל המערבי עם מעיינות, בריכות ומבצר צלבני מרשים הצופה על הערוץ הירוק.',
        difficulty: 'בינוני',
        distanceKm: '5',
        duration: 'עד 4 שעות',
        startLat: 33.0530,
        startLng: 35.2280,
        region: 'הגליל העליון',
        isWet: true,
        attractions: ['נחל', 'מעיין', 'תצפית'],
        entryFee: 'חינם',
        distanceKmNum: 5,
        durationHoursNum: 4,
      ));
  print('✅ trail_23 (נחל כזיב) seeded!');

  // trail_24 : הר ארבל — הגליל התחתון
  await db.collection('trails').doc('trail_24').set(_fullTrailDoc(
        name: 'הר ארבל',
        description:
            'מצוק דרמטי מעל הכנרת — תצפית מהיפות בארץ, מערות מבצר וירידה מאתגרת בסולמות ויתדות.',
        difficulty: 'בינוני',
        distanceKm: '3',
        duration: 'עד 3 שעות',
        startLat: 32.8240,
        startLng: 35.4990,
        region: 'הגליל התחתון',
        isWet: false,
        attractions: ['הרים', 'תצפית'],
        entryFee: 'בתשלום',
        distanceKmNum: 3,
        durationHoursNum: 3,
      ));
  print('✅ trail_24 (הר ארבל) seeded!');

  // trail_25 : פארק אשכול (הבשור) — הנגב המערבי
  await db.collection('trails').doc('trail_25').set(_fullTrailDoc(
        name: 'פארק אשכול (הבשור)',
        description:
            'ריאה ירוקה בנגב המערבי — מעיין עין הבשור, מדשאות ענק ופריחת כלניות מרהיבה בחורף.',
        difficulty: 'קל',
        distanceKm: '2',
        duration: 'עד 3 שעות',
        startLat: 31.3110,
        startLng: 34.4890,
        region: 'הנגב',
        isWet: true,
        attractions: ['מעיין'],
        entryFee: 'בתשלום',
        distanceKmNum: 2,
        durationHoursNum: 3,
      ));
  print('✅ trail_25 (פארק אשכול) seeded!');

  // trail_26 : פארק המעיינות — עמק המעיינות
  await db.collection('trails').doc('trail_26').set(_fullTrailDoc(
        name: 'פארק המעיינות',
        description:
            'שביל מעיינות בעמק בית שאן — עין מודע, עין שוקק ובריכות צלולות. מתאים גם לאופניים.',
        difficulty: 'קל',
        distanceKm: '5',
        duration: 'עד 3 שעות',
        startLat: 32.5000,
        startLng: 35.4790,
        region: 'הבקעה והעמקים',
        isWet: true,
        attractions: ['מעיין'],
        entryFee: 'חינם',
        distanceKmNum: 5,
        durationHoursNum: 3,
      ));
  print('✅ trail_26 (פארק המעיינות) seeded!');

  print('🎉 Trails 17–26 seeded!');
}
