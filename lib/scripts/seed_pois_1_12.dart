import 'package:cloud_firestore/cloud_firestore.dart';

// ─────────────────────────────────────────────────────────────────
//  SEED SCRIPT — POIs BATCH 1: trails 1–12
//
//  Real, documented points of interest for each trail, in walking
//  order. No coordinates by design (added later with real GPX work).
//
//  DATA:  trails/{trailId}/pois/poi_N
//    - name, description, type, order
//  Types: waterfall / spring / pool / lookout / heritage / cave / nature
//
//  HOW TO RUN:
//  1. In main.dart:  import 'scripts/seed_pois_1_12.dart';
//     and after Firebase.initializeApp():  await seedPois1to12();
//  2. flutter run once, watch for: 🎉 POIs for trails 1–12 seeded!
//  3. Comment both lines back out.
// ─────────────────────────────────────────────────────────────────

Future<void> _addPois(String trailId, List<Map<String, dynamic>> pois) async {
  final col = FirebaseFirestore.instance
      .collection('trails')
      .doc(trailId)
      .collection('pois');
  for (var i = 0; i < pois.length; i++) {
    await col.doc('poi_${i + 1}').set({...pois[i], 'order': i + 1});
  }
  print('✅ $trailId — ${pois.length} POIs seeded!');
}

Future<void> seedPois1to12() async {
  // trail_1 : נחל חרמון (הבניאס)
  await _addPois('trail_1', [
    {
      'name': 'מפל הבניאס',
      'description':
          'המפל השופע בישראל — מים גועשים אל בריכה כחולה בלב הקניון.',
      'type': 'waterfall',
    },
    {
      'name': 'השביל התלוי',
      'description': 'מדרך עץ תלוי מעל הנחל הגועש, צמוד לקירות הבזלת.',
      'type': 'nature',
    },
    {
      'name': 'מקדש פאן והעיר העתיקה',
      'description':
          'שרידי מקדש יווני לאל פאן ומערת הפולחן העתיקה למרגלות המצוק.',
      'type': 'heritage',
    },
  ]);

  // trail_2 : שמורת מג׳רסה
  await _addPois('trail_2', [
    {
      'name': 'הכניסה למים',
      'description': 'נקודת הירידה לערוץ הרדוד — מכאן הולכים בתוך המים.',
      'type': 'spring',
    },
    {
      'name': 'מנהרת הצמחייה',
      'description':
          'קטע שבו הקנים והעצים נסגרים מעל הנחל ויוצרים מנהרה ירוקה.',
      'type': 'nature',
    },
    {
      'name': 'שפך הדליות',
      'description': 'המקום שבו נחלי הגולן נפגשים בדרכם אל הכנרת.',
      'type': 'lookout',
    },
  ]);

  // trail_3 : הר בנטל
  await _addPois('trail_3', [
    {
      'name': 'תצפית הפסגה',
      'description': 'נוף פנורמי אל החרמון, עמק קוניטרה וגבול סוריה.',
      'type': 'lookout',
    },
    {
      'name': 'תעלות הקרב',
      'description': 'מערך תעלות ובונקרים משוחזר מהעמדה הסורית שעל ההר.',
      'type': 'heritage',
    },
  ]);

  // trail_4 : גן לאומי עין עבדת
  await _addPois('trail_4', [
    {
      'name': 'בריכת המפל',
      'description': 'מפל נופל אל בריכה צלולה בין קירות קניון לבנים.',
      'type': 'waterfall',
    },
    {
      'name': 'מדרגות הנזירים',
      'description': 'מדרגות חצובות בסלע ומערות נזירים ביזנטיות בקיר הקניון.',
      'type': 'heritage',
    },
    {
      'name': 'יעלים על המצוק',
      'description': 'עדרי יעלים מטפסים על קירות הקניון — עיניים למעלה!',
      'type': 'nature',
    },
  ]);

  // trail_5 : שביל הפסגה (הר מירון)
  await _addPois('trail_5', [
    {
      'name': 'תצפית הפסגה צפונה',
      'description': 'ביום בהיר רואים מכאן עד החרמון ומרום הגליל כולו.',
      'type': 'lookout',
    },
    {
      'name': 'החורש הקדום',
      'description':
          'חורש אלונים וערים מהעתיקים והגבוהים בארץ, מוצל ברוב הדרך.',
      'type': 'nature',
    },
  ]);

  // trail_6 : שמורת נחל שניר
  await _addPois('trail_6', [
    {
      'name': 'המצפור',
      'description': 'תצפית על ערוץ הנחל הגועש, נקודת פתיחה מושלמת למסלול.',
      'type': 'lookout',
    },
    {
      'name': 'פינות השכשוך',
      'description': 'ירידות מוסדרות למים הקרירים של השניר — כפות רגליים חובה.',
      'type': 'pool',
    },
  ]);

  // trail_7 : נחל דוד (עין גדי)
  await _addPois('trail_7', [
    {
      'name': 'בריכות השכשוך',
      'description':
          'סדרת בריכות ומפלונים לאורך הפלג — נעים לעצור ולהרטיב רגליים.',
      'type': 'pool',
    },
    {
      'name': 'מפל דוד',
      'description':
          'המפל הגדול בקצה הקניון, יורד מגובה של כ־30 מטר אל בריכה צלולה.',
      'type': 'waterfall',
    },
    {
      'name': 'שפני סלע ויעלים',
      'description': 'תושבי הקבע של השמורה — כמעט בטוח שתפגשו אותם על הסלעים.',
      'type': 'nature',
    },
  ]);

  // trail_8 : שמורת נחל מערות
  await _addPois('trail_8', [
    {
      'name': 'מערת התנור',
      'description':
          'המערה שבה נמצאו שרידי אדם ניאנדרטלי והומו־ספיינס זה לצד זה.',
      'type': 'cave',
    },
    {
      'name': 'מערת הנחל',
      'description': 'מערה ארוכה עם מיצג המחזה את חיי האדם הקדמון בכרמל.',
      'type': 'cave',
    },
    {
      'name': 'תצפית המצוק',
      'description': 'מבט אל מישור החוף מהנקודה שבה חיו בני אדם 500 אלף שנה.',
      'type': 'lookout',
    },
  ]);

  // trail_9 : עין פרת (נחל פרת)
  await _addPois('trail_9', [
    {
      'name': 'בריכת המעיין',
      'description':
          'בריכת הסלע הטבעית של עין פרת — המים צלולים וקרים כל השנה.',
      'type': 'spring',
    },
    {
      'name': 'מנזר פארן',
      'description': 'המנזר הראשון של מדבר יהודה, תלוי על צלע הקניון מעל הנחל.',
      'type': 'heritage',
    },
    {
      'name': 'חורשת האקליפטוס',
      'description': 'פינת צל ופיקניק על גדת הפלג הזורם.',
      'type': 'nature',
    },
  ]);

  // trail_10 : סטף
  await _addPois('trail_10', [
    {
      'name': 'עין סטף',
      'description': 'מעיין עם נקבה חצובה — אפשר להיכנס עם פנס אל תוך ההר.',
      'type': 'spring',
    },
    {
      'name': 'הטרסות העתיקות',
      'description': 'חקלאות הר מסורתית משוחזרת, בת אלפי שנים, על מדרגות ההר.',
      'type': 'heritage',
    },
    {
      'name': 'תצפית הרי ירושלים',
      'description': 'נוף פתוח אל נחל שורק והרי ירושלים המיוערים.',
      'type': 'lookout',
    },
  ]);

  // trail_11 : טיילת מכתש רמון
  await _addPois('trail_11', [
    {
      'name': 'תצפית שפת המכתש',
      'description':
          'מבט אל תוך המכתש הגדול בעולם — 40 ק״מ של נוף גיאולוגי חשוף.',
      'type': 'lookout',
    },
    {
      'name': 'מרכז המבקרים ע״ש אילן רמון',
      'description':
          'מוזיאון על המכתש והאסטרונאוט הישראלי הראשון, על קצה המצוק.',
      'type': 'heritage',
    },
  ]);

  // trail_12 : נחל יהודיה
  await _addPois('trail_12', [
    {
      'name': 'מפל יהודיה',
      'description': 'מפל בזלת יורד אל בריכה עמוקה — נקודת השיא של המסלול.',
      'type': 'waterfall',
    },
    {
      'name': 'קטע הסולמות',
      'description': 'ירידה בסולמות ויתדות בצמוד למצוק — חוויה למיטיבי לכת.',
      'type': 'nature',
    },
    {
      'name': 'תצפית הקניון',
      'description': 'מבט מלמעלה על קניון הבזלת השחור וצמחיית הגדות.',
      'type': 'lookout',
    },
  ]);

  print('🎉 POIs for trails 1–12 seeded!');
}
