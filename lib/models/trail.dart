// ─────────────────────────────────────────────────────────────────
//  TRAIL MODEL
//
//  TrailData is the in-app shape of a trail. As of the home-screen
//  Firestore migration, there is NO hardcoded sample data anymore —
//  every screen (home included) builds TrailData live from Firestore
//  via TrailData.fromFirestore(). One source of truth. 🎉
//
//  Filter fields power the מותאם (filter wizard) feature:
//    region          — which area of Israel (e.g. 'הגליל העליון')
//    isWet           — true = רטוב (water trail), false = יבש (dry)
//    attractions     — what you'll see, e.g. ['נחל', 'מפלים', 'הרים']
//    entryFee        — 'חינם' (free) or 'בתשלום' (paid)
//    participantType — who it suits, e.g. ['משפחתי', 'זוגי']
//    distanceKmNum   — distance as a NUMBER (for the length slider)
//    durationHoursNum— duration as a NUMBER (for the length slider)
//
//  Note: distanceKm / duration stay as display STRINGS (e.g. "1.5-2.5",
//  "עד 3 שעות") for the cards. The *Num fields are the machine-readable
//  versions the slider/filter math uses.
// ─────────────────────────────────────────────────────────────────

class TrailData {
  final String firestoreId;
  final String name;
  final String description;
  final String distanceKm;
  final String duration;
  final List<String> tags;
  final String imageUrl;

  // ── Filter fields ──────────────────────────────────────────────
  final String region;
  final bool isWet;
  final List<String> attractions;
  final String entryFee;
  final List<String> participantType;
  final double distanceKmNum;
  final double durationHoursNum;

  const TrailData({
    required this.firestoreId,
    required this.name,
    required this.description,
    required this.distanceKm,
    required this.duration,
    required this.tags,
    this.imageUrl = '',
    this.region = '',
    this.isWet = false,
    this.attractions = const [],
    this.entryFee = '',
    this.participantType = const [],
    this.distanceKmNum = 0,
    this.durationHoursNum = 0,
  });

  // ── Build a TrailData from a Firestore trail document ──────────
  //  The card tags are derived on the fly (wet/dry + difficulty),
  //  since trail docs don't carry a 'tags' array.
  factory TrailData.fromFirestore(String id, Map<String, dynamic> d) {
    final isWet = d['isWet'] as bool? ?? false;
    final difficulty = d['difficulty'] as String? ?? '';
    return TrailData(
      firestoreId: id,
      name: d['name'] as String? ?? 'מסלול',
      description: d['description'] as String? ?? '',
      distanceKm: d['distanceKm'] as String? ?? '',
      duration: d['duration'] as String? ?? '',
      tags: [
        isWet ? 'רטוב' : 'יבש',
        if (difficulty.isNotEmpty) difficulty,
      ],
      imageUrl: d['imageUrl'] as String? ?? '',
      region: d['region'] as String? ?? '',
      isWet: isWet,
      attractions: List<String>.from(d['attractions'] as List? ?? const []),
      entryFee: d['entryFee'] as String? ?? '',
      participantType:
          List<String>.from(d['participantType'] as List? ?? const []),
      distanceKmNum: (d['distanceKmNum'] as num?)?.toDouble() ?? 0,
      durationHoursNum: (d['durationHoursNum'] as num?)?.toDouble() ?? 0,
    );
  }
}
