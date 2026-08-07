import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme/app_theme.dart';
import '../models/trail.dart';
import '../widgets/trail_image.dart';
import 'trail_profile_screen.dart';

// ─────────────────────────────────────────────────────────────────
//  SEARCH SCREEN  (חיפוש חופשי)
//  Live as-you-type search over all trails, matching NAME and REGION.
//
//  - Empty query → the 8 region chips as tap-to-search shortcuts
//    (the "find by area" promise), plus a friendly hint.
//  - Typing → instant in-memory filtering of the streamed trails.
//  - Result rows: webp thumbnail (via TrailImage), name, region +
//    distance, chevron. Tap → trail profile.
//  - No matches → a gentle empty state, never a blank screen.
//
//  RTL: inherited app-wide from main.dart.
//  Row rule: first child = visual RIGHT, last = visual LEFT.
//  Column rule: CrossAxisAlignment.start = visual RIGHT.
// ─────────────────────────────────────────────────────────────────

// The 8 regions — must match the exact strings stored in Firestore
// (same list the filter wizard uses).
const List<String> _kRegions = [
  'הגליל העליון',
  'הגליל התחתון',
  'הבקעה והעמקים',
  'הכרמל והחוף',
  'השרון והמרכז',
  'ירושלים והסביבה',
  'יהודה ושומרון',
  'הנגב',
];

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _ctrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _setQuery(String q) => setState(() => _query = q.trim());

  // Tap a region chip → fill the field and search it immediately.
  void _searchRegion(String region) {
    _ctrl.text = region;
    // Put the cursor at the end so the user can keep typing naturally.
    _ctrl.selection = TextSelection.collapsed(offset: region.length);
    _setQuery(region);
  }

  // Clear button inside the field.
  void _clear() {
    _ctrl.clear();
    _setQuery('');
  }

  // The actual matching logic: case-insensitive "contains" over the
  // trail's name AND region. Hebrew has no upper/lower case, but the
  // toLowerCase() keeps any Latin text (e.g. future English names) safe.
  bool _matches(TrailData t, String q) {
    final needle = q.toLowerCase();
    return t.name.toLowerCase().contains(needle) ||
        t.region.toLowerCase().contains(needle);
  }

  void _openTrail(TrailData trail) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TrailProfileScreen(trailId: trail.firestoreId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 10),

            // ── Top row: search field (right) + close (left) ──────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  // The live search field — visual RIGHT, autofocused
                  // so the keyboard pops the moment the screen opens.
                  Expanded(
                    child: Container(
                      height: 52,
                      decoration: BoxDecoration(
                        color: AppTheme.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: const [
                          BoxShadow(
                            color: AppTheme.shadow,
                            blurRadius: 4,
                            offset: Offset(2, 1),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          const SizedBox(width: 14),
                          Expanded(
                            child: TextField(
                              controller: _ctrl,
                              autofocus: true,
                              onChanged: _setQuery,
                              textAlign: TextAlign.right,
                              textInputAction: TextInputAction.search,
                              style: const TextStyle(
                                fontFamily: AppTheme.font,
                                fontSize: 15,
                              ),
                              decoration: const InputDecoration(
                                isDense: true,
                                border: InputBorder.none,
                                hintText: 'חיפוש חופשי — לפי שם או אזור',
                                hintStyle: TextStyle(
                                  fontFamily: AppTheme.font,
                                  fontSize: 13,
                                  color: Color(0xFFB0B0B0),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Clear (x) appears only while typing;
                          // otherwise the search icon sits there.
                          if (_query.isNotEmpty)
                            GestureDetector(
                              onTap: _clear,
                              child: const Icon(Icons.close_rounded,
                                  color: AppTheme.textMuted, size: 20),
                            )
                          else
                            const Icon(Icons.search_rounded,
                                color: AppTheme.textMuted, size: 20),
                          const SizedBox(width: 12),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Close button — visual LEFT, pops back home.
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: AppTheme.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: const [
                          BoxShadow(
                            color: AppTheme.shadow,
                            blurRadius: 4,
                            offset: Offset(2, 1),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.arrow_forward_rounded,
                          color: AppTheme.textMuted, size: 22),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            // ── Body: chips (empty query) or live results ─────────
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('trails')
                    .snapshots(),
                builder: (context, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final all = (snap.data?.docs ?? [])
                      .map((d) => TrailData.fromFirestore(
                          d.id, d.data() as Map<String, dynamic>))
                      .toList();

                  // Empty query → region shortcuts, not an empty list.
                  if (_query.isEmpty) {
                    return _buildRegionShortcuts();
                  }

                  final results =
                      all.where((t) => _matches(t, _query)).toList();

                  if (results.isEmpty) {
                    return _buildNoResults();
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 110),
                    physics: const BouncingScrollPhysics(),
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    itemCount: results.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, i) => _SearchResultRow(
                      trail: results[i],
                      onTap: () => _openTrail(results[i]),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Empty-query state: the 8 region chips ──────────────────────
  Widget _buildRegionShortcuts() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 110),
      physics: const BouncingScrollPhysics(),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'או חפשו לפי אזור:',
            textAlign: TextAlign.right,
            style: TextStyle(
              fontFamily: AppTheme.font,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 14),
          // Wrap flows naturally right-to-left because the whole app
          // is RTL — no extra work needed.
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final r in _kRegions)
                GestureDetector(
                  onTap: () => _searchRegion(r),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppTheme.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: const [
                        BoxShadow(
                          color: AppTheme.shadow,
                          blurRadius: 4,
                          offset: Offset(2, 1),
                        ),
                      ],
                    ),
                    child: Text(
                      r,
                      style: const TextStyle(
                        fontFamily: AppTheme.font,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  // ── No-results state ────────────────────────────────────────────
  Widget _buildNoResults() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.search_off_rounded,
                size: 52, color: AppTheme.textMuted),
            const SizedBox(height: 14),
            Text(
              'לא נמצאו מסלולים עבור "$_query"',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: AppTheme.font,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'נסו שם אחר או אחד מהאזורים',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: AppTheme.font,
                fontSize: 13,
                color: AppTheme.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
//  SEARCH RESULT ROW
//  A compact tappable row: thumbnail (right) → name + region/distance
//  (middle) → chevron pointing LEFT (the RTL "forward" direction).
// ─────────────────────────────────────────────────────────────────
class _SearchResultRow extends StatelessWidget {
  final TrailData trail;
  final VoidCallback onTap;

  const _SearchResultRow({required this.trail, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppTheme.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: AppTheme.shadow,
              blurRadius: 4,
              offset: Offset(2, 1),
            ),
          ],
        ),
        child: Row(
          children: [
            // Thumbnail — visual RIGHT
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                width: 62,
                height: 62,
                child: TrailImage(
                  trailId: trail.firestoreId,
                  imageUrl: trail.imageUrl,
                  fit: BoxFit.cover,
                  fallback: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF4A8A6A), Color(0xFF2A5A4A)],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Name + region/distance — middle, hugging right
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    trail.name,
                    textAlign: TextAlign.right,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: AppTheme.font,
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    [
                      if (trail.region.isNotEmpty) trail.region,
                      if (trail.distanceKm.isNotEmpty)
                        '${trail.distanceKm} ק״מ',
                    ].join(' · '),
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      fontFamily: AppTheme.font,
                      fontSize: 12.5,
                      color: AppTheme.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Chevron — visual LEFT
            const Icon(Icons.chevron_left_rounded,
                size: 22, color: AppTheme.textMuted),
          ],
        ),
      ),
    );
  }
}