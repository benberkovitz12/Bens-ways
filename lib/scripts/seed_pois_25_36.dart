import 'package:cloud_firestore/cloud_firestore.dart';

// ─────────────────────────────────────────────────────────────────
//  SEED SCRIPT — POIs BATCH 3 (FINAL): trails 25–36
//  Same structure as batches 1–2. Run once, comment out.
//  In main.dart: import 'scripts/seed_pois_25_36.dart';
//                await seedPois25to36();
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

Future<void> seedPois25to36() async {
  // trail_25 : פארק אשכול (הבשור)
  await _addPois('trail_25', [
    {
      'name': 'עין הבשור',
      'description': 'המעיין הגדול של הנגב המערבי, נובע אל בריכה מוקפת ירק.',
      'type': 'spring',
    },
    {
      'name': 'מדשאות הענק',
      'description': 'משטחי דשא רחבים בלב הנגב — פינת פיקניק מושלמת.',
      'type': 'nature',
    },
  ]);

  // trail_26 : פארק המעיינות
  await _addPois('trail_26', [
    {
      'name': 'עין מודע',
      'description': 'בריכת מעיין רחבה ומוסדרת — הפופולרית שבמעיינות העמק.',
      'type': 'spring',
    },
    {
      'name': 'עין שוקק',
      'description': 'מעיין עם בריכה צלולה ומגלשת מים טבעית קטנה.',
      'type': 'pool',
    },
    {
      'name': 'תצפית הגלבוע',
      'description': 'רכס הגלבוע המתנשא מעל העמק — יפה במיוחד בפריחת החורף.',
      'type': 'lookout',
    },
  ]);

  // trail_27 : שמורת תל דן
  await _addPois('trail_27', [
    {
      'name': 'נביעות הדן',
      'description': 'המעיין השופע בישראל — רבע ממי הירדן מתחילים כאן.',
      'type': 'spring',
    },
    {
      'name': 'השער הכנעני',
      'description': 'שער לבני בוץ בן כמעט 4,000 שנה — מהעתיקים שנשתמרו בעולם.',
      'type': 'heritage',
    },
    {
      'name': 'בריכת השכשוך',
      'description': 'פינת מים קרירים ומוצלים בסוף המסלול — פינוק אמיתי בקיץ.',
      'type': 'pool',
    },
  ]);

  // trail_28 : נקרות ראש הנקרה
  await _addPois('trail_28', [
    {
      'name': 'הנקרות',
      'description':
          'מנהרות הים שחצבו הגלים בסלע הגיר הלבן — כחול עז בכל פינה.',
      'type': 'cave',
    },
    {
      'name': 'הרכבל',
      'description': 'מהרכבלים התלולים בעולם, יורד מהמצוק אל פתח הנקרות.',
      'type': 'lookout',
    },
    {
      'name': 'מנהרת הרכבת',
      'description': 'שרידי מסילת הרכבת חיפה־ביירות מימי מלחמת העולם השנייה.',
      'type': 'heritage',
    },
  ]);

  // trail_29 : רמת הנדיב
  await _addPois('trail_29', [
    {
      'name': 'גני הזיכרון',
      'description': 'גנים מטופחים סביב קבר הברון רוטשילד ורעייתו.',
      'type': 'heritage',
    },
    {
      'name': 'תצפית הים',
      'description': 'מבט מקצה השלוחה אל חוף הכרמל והים התיכון.',
      'type': 'lookout',
    },
    {
      'name': 'שביל החורש',
      'description': 'חורש ים־תיכוני עם פריחה עונתית ועופות דורסים בשמיים.',
      'type': 'nature',
    },
  ]);

  // trail_30 : גן לאומי הקסטל
  await _addPois('trail_30', [
    {
      'name': 'התעלות והבונקרים',
      'description': 'מערך הקרב המשוחזר מקרבות הדרך לירושלים בתש״ח.',
      'type': 'heritage',
    },
    {
      'name': 'תצפית הפסגה',
      'description': 'שליטה מלאה על כביש ירושלים — מבינים מיד למה נלחמו כאן.',
      'type': 'lookout',
    },
  ]);

  // trail_31 : עינות צוקים (עין פשחה)
  await _addPois('trail_31', [
    {
      'name': 'בריכות הטבילה',
      'description':
          'בריכות מעיין צלולות במקום הנמוך בעולם — חוויה שאין שנייה לה.',
      'type': 'pool',
    },
    {
      'name': 'תצפית ים המלח',
      'description': 'המלחה, הצוקים והרי מואב שמעבר לים.',
      'type': 'lookout',
    },
  ]);

  // trail_32 : פארק תמנע
  await _addPois('trail_32', [
    {
      'name': 'עמודי שלמה',
      'description': 'עמודי אבן החול האדומים המתנשאים לגובה 50 מטר.',
      'type': 'nature',
    },
    {
      'name': 'הפטרייה',
      'description': 'תצורת הסלע המפורסמת שפוסלה ברוח המדבר.',
      'type': 'nature',
    },
    {
      'name': 'מכרות הנחושת העתיקים',
      'description': 'פירי הכרייה מימי המצרים הקדמונים — מהעתיקים בעולם.',
      'type': 'heritage',
    },
  ]);

  // trail_33 : אגמון החולה
  await _addPois('trail_33', [
    {
      'name': 'תצפית העגורים',
      'description': 'בחורף — עשרות אלפי עגורים במופע טבע מהגדולים בעולם.',
      'type': 'lookout',
    },
    {
      'name': 'האגם',
      'description': 'שרידי ימת החולה ההיסטורית, ביתם של עופות מים ותאואים.',
      'type': 'nature',
    },
  ]);

  // trail_34 : שמורת האירוסים (נתניה)
  await _addPois('trail_34', [
    {
      'name': 'פריחת האירוסים',
      'description': 'אירוס הארגמן הנדיר צובע את השמורה בסגול בסוף החורף.',
      'type': 'nature',
    },
    {
      'name': 'רכס הכורכר',
      'description': 'שביל על רכס הכורכר עם מבט אל השכונות והים.',
      'type': 'lookout',
    },
  ]);

  // trail_35 : גן לאומי ציפורי
  await _addPois('trail_35', [
    {
      'name': 'המונה ליזה של הגליל',
      'description': 'פסיפס האישה המפורסם — מיצירות האמנות הרומית היפות בארץ.',
      'type': 'heritage',
    },
    {
      'name': 'התיאטרון הרומי',
      'description': 'תיאטרון בן 4,500 מושבים החצוב בצלע הגבעה.',
      'type': 'heritage',
    },
    {
      'name': 'מפעל המים העתיק',
      'description': 'מאגר מים תת־קרקעי מרשים שאפשר ללכת בתוכו.',
      'type': 'cave',
    },
  ]);

  // trail_36 : גן לאומי בית גוברין
  await _addPois('trail_36', [
    {
      'name': 'מערות הפעמון',
      'description': 'אולמות ענק חצובים בגיר הרך — קתדרלות טבעיות מהממות.',
      'type': 'cave',
    },
    {
      'name': 'מערות הקבורה הצידוניות',
      'description': 'מערות מעוטרות בציורי קיר צבעוניים מהתקופה ההלניסטית.',
      'type': 'heritage',
    },
    {
      'name': 'תל מרשה',
      'description': 'העיר העתיקה עם מערכות מסתור, בתי בד ומבט אל השפלה.',
      'type': 'heritage',
    },
  ]);

  print('🎉 POIs for trails 25–36 seeded! (all 36 trails covered)');
}
