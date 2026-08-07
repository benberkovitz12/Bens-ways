import 'package:cloud_firestore/cloud_firestore.dart';

// ─────────────────────────────────────────────────────────────────
//  SEED SCRIPT — POIs BATCH 2: trails 13–24
//  Same structure as batch 1. Run once, comment out.
//  In main.dart: import 'scripts/seed_pois_13_24.dart';
//                await seedPois13to24();
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

Future<void> seedPois13to24() async {
  // trail_13 : הר תבור — שביל ההקפה
  await _addPois('trail_13', [
    {
      'name': 'כנסיית ההשתנות',
      'description':
          'הבזיליקה המפוארת על הפסגה, מוקד עלייה לרגל מהמאה הרביעית.',
      'type': 'heritage',
    },
    {
      'name': 'תצפית עמק יזרעאל',
      'description': 'שטיח החלקות החקלאיות של העמק נפרש למרגלות ההר.',
      'type': 'lookout',
    },
    {
      'name': 'שער הרוח',
      'description': 'שער האבן העתיק בכניסה לדרך העולה אל הפסגה.',
      'type': 'heritage',
    },
  ]);

  // trail_14 : נחל אלכסנדר (גשר הצבים)
  await _addPois('trail_14', [
    {
      'name': 'גשר הצבים',
      'description': 'נקודת התצפית המפורסמת על צבי הנילוס הרכים החיים בנחל.',
      'type': 'nature',
    },
    {
      'name': 'שדרת האקליפטוסים',
      'description': 'הליכה מוצלת לאורך הגדה, בין עצים ותיקים וספסלי מנוחה.',
      'type': 'nature',
    },
  ]);

  // trail_15 : מצדה — שביל הנחש
  await _addPois('trail_15', [
    {
      'name': 'הארמון הצפוני',
      'description': 'ארמון הורדוס התלוי בשלוש מדרגות על קצה הצוק — פלא הנדסי.',
      'type': 'heritage',
    },
    {
      'name': 'בית הכנסת העתיק',
      'description': 'מבתי הכנסת הקדומים בעולם, מימי המרד הגדול.',
      'type': 'heritage',
    },
    {
      'name': 'תצפית הזריחה',
      'description': 'ים המלח והרי מואב נצבעים בזהב — שווה את ההשכמה.',
      'type': 'lookout',
    },
  ]);

  // trail_16 : גן השלושה (סחנה)
  await _addPois('trail_16', [
    {
      'name': 'הבריכה הראשית',
      'description': 'בריכת המים הטבעית הגדולה — 28 מעלות נעימות כל השנה.',
      'type': 'pool',
    },
    {
      'name': 'המפלונים',
      'description':
          'מפלי מים קטנים המחברים בין הבריכות — פינות הג׳קוזי של הטבע.',
      'type': 'waterfall',
    },
    {
      'name': 'טחנת הקמח העתיקה',
      'description': 'טחנה משוחזרת המדגימה את כוח המים ששימש כאן דורות.',
      'type': 'heritage',
    },
  ]);

  // trail_17 : נחל עמוד
  await _addPois('trail_17', [
    {
      'name': 'העמוד',
      'description': 'עמוד הסלע הטבעי המזדקר בערוץ — הסמל שנתן לנחל את שמו.',
      'type': 'nature',
    },
    {
      'name': 'טחנות הקמח',
      'description': 'שרידי טחנות מים עתיקות שפעלו כאן מכוח זרימת הנחל.',
      'type': 'heritage',
    },
    {
      'name': 'בריכות הנחל',
      'description': 'קטעי מים צלולים בצל עצי הדולב — מושלם להפסקת רגליים.',
      'type': 'pool',
    },
  ]);

  // trail_18 : חוף דור הבונים
  await _addPois('trail_18', [
    {
      'name': 'הלגונה הכחולה',
      'description':
          'מפרצון מוגן בין רכסי הכורכר — מהפינות היפות בחוף הישראלי.',
      'type': 'pool',
    },
    {
      'name': 'כוכי הגיר',
      'description': 'מערות ונקיקים שחצבו הגלים ברכס הכורכר לאורך החוף.',
      'type': 'cave',
    },
    {
      'name': 'תצפית האיים',
      'description': 'איי הסלע הקטנים מול החוף — אתרי קינון של עופות ים.',
      'type': 'lookout',
    },
  ]);

  // trail_19 : עין חמד (אקווה בלה)
  await _addPois('trail_19', [
    {
      'name': 'המצודה הצלבנית',
      'description': 'מבנה אבן מרשים מהמאה ה־12 ששימש אכסניה לעולי רגל.',
      'type': 'heritage',
    },
    {
      'name': 'הנחל והמדשאות',
      'description': 'פלג קטן זורם בין מדשאות רחבות ועצי דולב עתיקים.',
      'type': 'nature',
    },
  ]);

  // trail_20 : שמורת התנור — נחל עיון
  await _addPois('trail_20', [
    {
      'name': 'מפל התנור',
      'description': 'המפל הגבוה בשמורה — 30 מטר של וילון מים בחורף.',
      'type': 'waterfall',
    },
    {
      'name': 'מפל הטחנה',
      'description': 'מפל ולצדו שרידי טחנת קמח שפעלה ממי הנחל.',
      'type': 'waterfall',
    },
    {
      'name': 'תצפית מטולה',
      'description': 'מבט אל המושבה הצפונית בישראל ואל הרי הלבנון.',
      'type': 'lookout',
    },
  ]);

  // trail_21 : נחל חווארים
  await _addPois('trail_21', [
    {
      'name': 'קניון הקירטון הלבן',
      'description': 'קירות לבנים וחלקים כמו נוף ירחי — מהמראות המיוחדים בנגב.',
      'type': 'nature',
    },
    {
      'name': 'תצפית צוקי הצין',
      'description': 'מבט פתוח אל מצוקי נחל צין ובקעת צין הרחבה.',
      'type': 'lookout',
    },
  ]);

  // trail_22 : תל אפק (אנטיפטריס)
  await _addPois('trail_22', [
    {
      'name': 'המצודה העות׳מאנית',
      'description': 'מבצר בינאר באשי הבנוי על שרידי העיר הרומית אנטיפטריס.',
      'type': 'heritage',
    },
    {
      'name': 'הקרדו הרומי',
      'description': 'שרידי הרחוב הראשי של העיר שבנה הורדוס לכבוד אביו.',
      'type': 'heritage',
    },
    {
      'name': 'אגם החורף',
      'description': 'אגם עונתי שמתמלא בגשמים ומושך אליו עופות מים.',
      'type': 'nature',
    },
  ]);

  // trail_23 : נחל כזיב ומבצר מונפור
  await _addPois('trail_23', [
    {
      'name': 'מבצר מונפור',
      'description': 'מבצר צלבני של המסדר הטבטוני, תלוי מעל הערוץ הירוק.',
      'type': 'heritage',
    },
    {
      'name': 'מעיינות הנחל',
      'description': 'נביעות איתן המזינות בריכות צלולות לאורך הערוץ.',
      'type': 'spring',
    },
    {
      'name': 'תצפית הערוץ',
      'description': 'מבט מהרכס אל הקניון הירוק המתפתל — מהיפים בגליל.',
      'type': 'lookout',
    },
  ]);

  // trail_24 : הר ארבל
  await _addPois('trail_24', [
    {
      'name': 'תצפית המצוק',
      'description': 'הכנרת, רמת הגולן והחרמון בפריים אחד — 380 מטר מעל העמק.',
      'type': 'lookout',
    },
    {
      'name': 'מצודת המערות',
      'description': 'מערות מבוצרות בקיר המצוק ששימשו מסתור מימי הורדוס.',
      'type': 'cave',
    },
    {
      'name': 'הירידה בסולמות',
      'description': 'קטע היתדות והסולמות הצמוד למצוק — למי שאוהב אתגר.',
      'type': 'nature',
    },
  ]);

  print('🎉 POIs for trails 13–24 seeded!');
}
