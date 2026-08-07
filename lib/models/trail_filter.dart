// ─────────────────────────────────────────────────────────────────
//  TRAIL FILTER MODEL
//
//  A plain data class that holds the user's choices from the filter
//  wizard (the 4 steps: region, type, character, length).
//
//  KEY PRINCIPLE: every field is OPTIONAL.
//  - Empty list / null  = "user didn't choose this" = don't filter on it.
//  - With only 6 trails, applying many strict filters at once would
//    return zero results — so a skipped filter is simply ignored.
//
//  The `matches(...)` method decides whether a single trail passes the
//  filter. The results screen calls it on every trail.
// ─────────────────────────────────────────────────────────────────

class TrailFilter {
  // Step 1 — region(s). Empty = any region.
  final Set<String> regions;

  // Step 2 — wetness. null = either; true = wet only; false = dry only.
  final bool? isWet;
  // Step 2 — attractions the user wants to see. Empty = any.
  // A trail passes if it has AT LEAST ONE of the chosen attractions.
  final Set<String> attractions;

  // Step 3 — entry fee. Empty = any. (e.g. {'חינם'} or {'בתשלום'})
  final Set<String> entryFees;
  // Step 3 — difficulty levels. Empty = any.
  final Set<String> difficulties;
  // Step 3 — participant types. Empty = any. Trail passes if it has
  // at least one of the chosen types.
  final Set<String> participantTypes;

  // Step 4 — max distance in km. null = no limit.
  final double? maxDistanceKm;
  // Step 4 — max duration in hours. null = no limit.
  final double? maxDurationHours;

  const TrailFilter({
    this.regions = const {},
    this.isWet,
    this.attractions = const {},
    this.entryFees = const {},
    this.difficulties = const {},
    this.participantTypes = const {},
    this.maxDistanceKm,
    this.maxDurationHours,
  });

  /// True if NO filters are active at all (everything skipped).
  bool get isEmpty =>
      regions.isEmpty &&
      isWet == null &&
      attractions.isEmpty &&
      entryFees.isEmpty &&
      difficulties.isEmpty &&
      participantTypes.isEmpty &&
      maxDistanceKm == null &&
      maxDurationHours == null;

  /// Decide whether one trail (its raw Firestore data map) passes.
  bool matches(Map<String, dynamic> trail) {
    // ── Region ──────────────────────────────────────────────────
    if (regions.isNotEmpty) {
      final r = trail['region'] as String? ?? '';
      if (!regions.contains(r)) return false;
    }

    // ── Wet / dry ───────────────────────────────────────────────
    if (isWet != null) {
      final wet = trail['isWet'] as bool? ?? false;
      if (wet != isWet) return false;
    }

    // ── Attractions (at least one overlap) ──────────────────────
    if (attractions.isNotEmpty) {
      final raw = trail['attractions'] as List<dynamic>? ?? [];
      final trailAttractions = raw.map((e) => e.toString()).toSet();
      final hasOverlap = trailAttractions.intersection(attractions).isNotEmpty;
      if (!hasOverlap) return false;
    }

    // ── Entry fee ───────────────────────────────────────────────
    if (entryFees.isNotEmpty) {
      final fee = trail['entryFee'] as String? ?? '';
      if (!entryFees.contains(fee)) return false;
    }

    // ── Difficulty ──────────────────────────────────────────────
    if (difficulties.isNotEmpty) {
      final diff = trail['difficulty'] as String? ?? '';
      if (!difficulties.contains(diff)) return false;
    }

    // ── Participant type (at least one overlap) ─────────────────
    if (participantTypes.isNotEmpty) {
      final raw = trail['participantType'] as List<dynamic>? ?? [];
      final trailTypes = raw.map((e) => e.toString()).toSet();
      final hasOverlap = trailTypes.intersection(participantTypes).isNotEmpty;
      if (!hasOverlap) return false;
    }

    // ── Max distance ────────────────────────────────────────────
    if (maxDistanceKm != null) {
      final d = (trail['distanceKmNum'] as num?)?.toDouble() ?? 0;
      if (d > maxDistanceKm!) return false;
    }

    // ── Max duration ────────────────────────────────────────────
    if (maxDurationHours != null) {
      final h = (trail['durationHoursNum'] as num?)?.toDouble() ?? 0;
      if (h > maxDurationHours!) return false;
    }

    // Passed every active filter.
    return true;
  }

  /// Human-readable chips for the results screen — one label per active
  /// choice, each tagged so the screen knows what to remove on tap.
  /// Returns a list of (category, value) pairs.
  List<FilterChipData> activeChips() {
    final chips = <FilterChipData>[];
    for (final r in regions) {
      chips.add(FilterChipData(category: 'region', value: r));
    }
    if (isWet != null) {
      chips.add(
          FilterChipData(category: 'isWet', value: isWet! ? 'רטוב' : 'יבש'));
    }
    for (final a in attractions) {
      chips.add(FilterChipData(category: 'attraction', value: a));
    }
    for (final f in entryFees) {
      chips.add(FilterChipData(category: 'entryFee', value: f));
    }
    for (final d in difficulties) {
      chips.add(FilterChipData(category: 'difficulty', value: d));
    }
    for (final p in participantTypes) {
      chips.add(FilterChipData(category: 'participantType', value: p));
    }
    if (maxDistanceKm != null) {
      chips.add(FilterChipData(
          category: 'maxDistance',
          value: 'עד ${maxDistanceKm!.toStringAsFixed(0)} ק״מ'));
    }
    if (maxDurationHours != null) {
      chips.add(FilterChipData(
          category: 'maxDuration',
          value: 'עד ${maxDurationHours!.toStringAsFixed(0)} שעות'));
    }
    return chips;
  }

  /// Returns a COPY of this filter with one chip's choice removed.
  /// Used when the user taps the × on a chip in the results screen.
  TrailFilter removeChip(FilterChipData chip) {
    return TrailFilter(
      regions: chip.category == 'region'
          ? (Set.of(regions)..remove(chip.value))
          : regions,
      isWet: chip.category == 'isWet' ? null : isWet,
      attractions: chip.category == 'attraction'
          ? (Set.of(attractions)..remove(chip.value))
          : attractions,
      entryFees: chip.category == 'entryFee'
          ? (Set.of(entryFees)..remove(chip.value))
          : entryFees,
      difficulties: chip.category == 'difficulty'
          ? (Set.of(difficulties)..remove(chip.value))
          : difficulties,
      participantTypes: chip.category == 'participantType'
          ? (Set.of(participantTypes)..remove(chip.value))
          : participantTypes,
      maxDistanceKm: chip.category == 'maxDistance' ? null : maxDistanceKm,
      maxDurationHours:
          chip.category == 'maxDuration' ? null : maxDurationHours,
    );
  }
}

/// One removable chip on the results screen.
class FilterChipData {
  final String category; // which filter field it belongs to
  final String value; // the label shown on the chip
  const FilterChipData({required this.category, required this.value});
}
