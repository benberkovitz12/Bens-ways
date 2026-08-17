import 'package:cloud_firestore/cloud_firestore.dart';

// Reusable one-trail seed.
//
// 1. Edit only the configuration block below.
// 2. In main.dart, uncomment the import and seedNextTrail() call.
// 3. Run the app once and read the new trail ID from the console.
// 4. Comment both lines in main.dart again.
//
// The seedKey prevents a second run from creating the same trail twice.

// -----------------------------------------------------------------------------
// EDIT ONLY THIS BLOCK
// -----------------------------------------------------------------------------

const String newTrailSeedKey = 'CHANGE_ME_UNIQUE_KEY';

final Map<String, dynamic> newTrailData = {
  'name': 'שם המסלול',
  'description': 'תיאור המסלול',
  'difficulty': 'קל',
  'distanceKm': '1',
  'duration': 'עד שעה',
  'imageUrl': '',

  'startLat': 0.0,
  'startLng': 0.0,
  'startRadiusMeters': 100,

  'pathPoints': [
    {'lat': 0.0, 'lng': 0.0}, // Start: must match startLat/startLng.
    {'lat': 0.0, 'lng': 0.0}, // End.
  ],

  'region': 'מרכז',
  'isWet': false,
  'attractions': <String>[],
  'entryFee': 'חינם',
  'participantType': <String>['משפחתי'],

  // Numeric copies used by the filter wizard.
  'distanceKmNum': 1.0,
  'durationHoursNum': 1.0,
};

// -----------------------------------------------------------------------------
// DO NOT EDIT BELOW THIS LINE
// -----------------------------------------------------------------------------

Future<String> seedNextTrail() async {
  _validateNewTrail();

  final trails = FirebaseFirestore.instance.collection('trails');

  final existing =
      await trails.where('seedKey', isEqualTo: newTrailSeedKey).limit(1).get();

  if (existing.docs.isNotEmpty) {
    final existingId = existing.docs.first.id;
    // ignore: avoid_print
    print('Trail already exists: $existingId');
    return existingId;
  }

  final snapshot = await trails.get();
  final trailIdPattern = RegExp(r'^trail_(\d+)$');
  var highestNumber = 0;

  for (final document in snapshot.docs) {
    final match = trailIdPattern.firstMatch(document.id);
    if (match == null) continue;

    final number = int.parse(match.group(1)!);
    if (number > highestNumber) highestNumber = number;
  }

  final newTrailId = 'trail_${highestNumber + 1}';
  await trails.doc(newTrailId).set({
    ...newTrailData,
    'seedKey': newTrailSeedKey,
    'createdAt': FieldValue.serverTimestamp(),
  });

  // ignore: avoid_print
  print('Created $newTrailId: ${newTrailData['name']}');
  return newTrailId;
}

void _validateNewTrail() {
  if (newTrailSeedKey.trim().isEmpty ||
      newTrailSeedKey == 'CHANGE_ME_UNIQUE_KEY') {
    throw StateError('Change newTrailSeedKey before running the seed.');
  }

  final startLat = newTrailData['startLat'];
  final startLng = newTrailData['startLng'];
  final pathPoints = newTrailData['pathPoints'];

  if (startLat is! num || startLng is! num) {
    throw StateError('startLat and startLng must be numbers.');
  }
  if (startLat == 0 || startLng == 0) {
    throw StateError('Replace the example start coordinates.');
  }
  if (pathPoints is! List || pathPoints.length < 2) {
    throw StateError('pathPoints must contain at least a start and an end.');
  }

  for (var index = 0; index < pathPoints.length; index++) {
    final point = pathPoints[index];
    if (point is! Map || point['lat'] is! num || point['lng'] is! num) {
      throw StateError('pathPoints[$index] must contain numeric lat and lng.');
    }
  }

  final firstPoint = pathPoints.first as Map;
  if (firstPoint['lat'] != startLat || firstPoint['lng'] != startLng) {
    throw StateError(
      'The first pathPoints item must match startLat and startLng.',
    );
  }
}
