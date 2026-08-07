import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme/app_theme.dart';
import '../models/trail_filter.dart';
import '../widgets/trail_image.dart';
import 'trail_profile_screen.dart';

// ─────────────────────────────────────────────────────────────────
//  FILTER RESULTS SCREEN
//  Shows trails matching the user's filter choices.
//  Matches the Figma "X התוצאות הטובות ביותר בשבילך!" screen:
//    - count header with a refresh/reset button
//    - removable blue filter chips (× clears that filter, re-runs)
//    - full-width result cards (image, stats, difficulty, tags, desc)
//
//  HOW IT WORKS:
//  We load ALL trails from Firestore once (cheap at this scale),
//  then filter them in memory with TrailFilter.matches(). This avoids
//  complex Firestore composite-index queries and lets every filter be
//  optional. The filter lives in state so removing a chip re-runs it.
//
//  IMAGE FIX: cards now render through TrailImage (the same widget
//  home/search use), so local webp assets load — previously this
//  screen used raw Image.network, which showed nothing for trails
//  whose images are bundled webp files rather than URLs.
// ─────────────────────────────────────────────────────────────────

class FilterResultsScreen extends StatefulWidget {
  final TrailFilter filter;
  const FilterResultsScreen({super.key, required this.filter});

  @override
  State<FilterResultsScreen> createState() => _FilterResultsScreenState();
}

class _FilterResultsScreenState extends State<FilterResultsScreen> {
  late TrailFilter _filter;

  @override
  void initState() {
    super.initState();
    _filter = widget.filter; // start from what the wizard passed in
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: SafeArea(
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('trails').snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return const Center(child: Text('שגיאה בטעינת המסלולים'));
            }

            final allDocs = snapshot.data?.docs ?? [];

            // Filter in memory.
            final matches = allDocs.where((doc) {
              final data = doc.data() as Map<String, dynamic>;
              return _filter.matches(data);
            }).toList();

            final chips = _filter.activeChips();

            return Column(
              children: [
                // ── Header row: close + count + reset ─────────────
                _buildHeader(matches.length),

                // ── Active filter chips ───────────────────────────
                if (chips.isNotEmpty) _buildChips(chips),

                const SizedBox(height: 8),

                // ── Results list ──────────────────────────────────
                Expanded(
                  child: matches.isEmpty
                      ? _buildEmptyState()
                      : ListView.separated(
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                          itemCount: matches.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 18),
                          itemBuilder: (_, i) {
                            final doc = matches[i];
                            final data = doc.data() as Map<String, dynamic>;
                            return _ResultCard(
                              trailId: doc.id,
                              data: data,
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      TrailProfileScreen(trailId: doc.id),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  // ── Header: close (×) on right, title centered, reset on left ────
  Widget _buildHeader(int count) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Close button (visual left in RTL)
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: const Icon(Icons.close_rounded, size: 28),
          ),
          // Count title
          Expanded(
            child: Text(
              '$count התוצאות הטובות ביותר בשבילך!',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: AppTheme.font,
                fontSize: 19,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          // Reset button — clears all filters
          GestureDetector(
            onTap: () => setState(() => _filter = const TrailFilter()),
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppTheme.accentDark,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.refresh_rounded,
                  size: 20, color: AppTheme.black),
            ),
          ),
        ],
      ),
    );
  }

  // ── Horizontal scrolling row of removable filter chips ───────────
  Widget _buildChips(List<FilterChipData> chips) {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        reverse: true, // RTL: first chip on the right
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: chips.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final chip = chips[i];
          return GestureDetector(
            onTap: () => setState(() => _filter = _filter.removeChip(chip)),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.accent,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.close_rounded, size: 15),
                  const SizedBox(width: 6),
                  Text(
                    chip.value,
                    style: const TextStyle(
                        fontFamily: AppTheme.font, fontSize: 14),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ── Empty state ──────────────────────────────────────────────────
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.search_off_rounded,
              size: 56, color: Color(0xFFD0D0D0)),
          const SizedBox(height: 14),
          const Text(
            'לא נמצאו מסלולים מתאימים',
            style: TextStyle(
                fontFamily: AppTheme.font,
                fontSize: 16,
                fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          const Text(
            'נסה להסיר כמה מסננים',
            style: TextStyle(
                fontFamily: AppTheme.font,
                fontSize: 14,
                color: AppTheme.textMuted),
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: () => setState(() => _filter = const TrailFilter()),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 11),
              decoration: BoxDecoration(
                color: AppTheme.accent,
                borderRadius: BorderRadius.circular(AppTheme.radiusPill),
              ),
              child: const Text('נקה את כל המסננים',
                  style: TextStyle(fontFamily: AppTheme.font, fontSize: 15)),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
//  RESULT CARD — full-width trail card for the results list.
//  Layout: big image on top (bookmark overlay), then a row with
//  stats (km/hours) on the right-visual-left and tag pills, then the
//  trail name and description.
// ─────────────────────────────────────────────────────────────────
class _ResultCard extends StatelessWidget {
  final String trailId;
  final Map<String, dynamic> data;
  final VoidCallback onTap;

  const _ResultCard({
    required this.trailId,
    required this.data,
    required this.onTap,
  });

  static const _gradients = [
    [Color(0xFF4A8A6A), Color(0xFF2A5A4A)],
    [Color(0xFF5A9AAA), Color(0xFF2A6A7A)],
    [Color(0xFF8A7A5A), Color(0xFF5A5030)],
    [Color(0xFF6A7A9A), Color(0xFF3A4A6A)],
  ];

  @override
  Widget build(BuildContext context) {
    final name = data['name'] as String? ?? 'מסלול';
    final description = data['description'] as String? ?? '';
    final imageUrl = data['imageUrl'] as String? ?? '';
    final difficulty = data['difficulty'] as String? ?? '';
    final isWet = data['isWet'] as bool? ?? false;
    final entryFee = data['entryFee'] as String? ?? '';
    final distanceKm = data['distanceKm'] as String? ?? '';
    final duration = data['duration'] as String? ?? '';

    final grad = _gradients[name.hashCode.abs() % _gradients.length];

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.white,
          borderRadius: BorderRadius.circular(AppTheme.radiusCard),
          boxShadow: AppTheme.cardShadow,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Image with bookmark overlay ─────────────────────
            //  Rendered through TrailImage — the same widget home and
            //  search use — so bundled webp assets load correctly,
            //  URLs still work, and a gradient covers missing images.
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(20),
                    bottom: Radius.circular(8),
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    height: 180,
                    child: TrailImage(
                      trailId: trailId,
                      imageUrl: imageUrl,
                      fit: BoxFit.cover,
                      fallback: _gradientBox(grad),
                    ),
                  ),
                ),
                // Bookmark — top-left (visual) in RTL
                Positioned(
                  top: 10,
                  left: 10,
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: AppTheme.white,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: AppTheme.cardShadow,
                    ),
                    child: const Icon(Icons.bookmark_border_rounded,
                        size: 20, color: AppTheme.black),
                  ),
                ),
              ],
            ),

            // ── Body ─────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Stats (left) + tag pills (right)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Stats — visual left
                      _MiniStat(
                          value: distanceKm.isNotEmpty ? distanceKm : '—',
                          label: 'ק״מ'),
                      const SizedBox(width: 14),
                      _MiniStat(
                          value: duration.isNotEmpty
                              ? duration
                                  .replaceAll('עד ', '')
                                  .replaceAll(' שעות', '')
                              : '—',
                          label: 'שעות'),
                      const Spacer(),
                      // Tag pills — visual right
                      ..._buildTagPills(isWet, entryFee, difficulty),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // Name
                  Text(
                    name,
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      fontFamily: AppTheme.font,
                      fontSize: 19,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Description
                  Text(
                    description,
                    textAlign: TextAlign.right,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: AppTheme.font,
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Small icon pills: wet drop, fee shekel, difficulty text
  List<Widget> _buildTagPills(bool isWet, String entryFee, String difficulty) {
    final pills = <Widget>[];

    if (difficulty.isNotEmpty) {
      pills.add(_TextPill(difficulty));
      pills.add(const SizedBox(width: 6));
    }
    if (entryFee.isNotEmpty) {
      pills.add(_IconPill(
        entryFee == 'חינם'
            ? Icons.money_off_rounded
            : Icons.attach_money_rounded,
      ));
      pills.add(const SizedBox(width: 6));
    }
    if (isWet) {
      pills.add(const _IconPill(Icons.water_drop_outlined));
    }
    // Drop trailing spacer if present
    if (pills.isNotEmpty && pills.last is SizedBox) {
      pills.removeLast();
    }
    return pills;
  }

  Widget _gradientBox(List<Color> colors) => Container(
        width: double.infinity,
        height: 180,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: colors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
      );
}

// ── Big number + small label (distance / hours) ───────────────────
class _MiniStat extends StatelessWidget {
  final String value, label;
  const _MiniStat({required this.value, required this.label});

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(value,
              style: const TextStyle(
                  fontFamily: AppTheme.font,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  height: 1,
                  color: AppTheme.tagText)),
          const SizedBox(height: 2),
          Text(label,
              style: const TextStyle(
                  fontFamily: AppTheme.font,
                  fontSize: 11,
                  color: AppTheme.textMuted)),
        ],
      );
}

// ── A grey rounded text pill (e.g. difficulty) ────────────────────
class _TextPill extends StatelessWidget {
  final String text;
  const _TextPill(this.text);

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: AppTheme.tagGreen,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(text,
            style: const TextStyle(
                fontFamily: AppTheme.font,
                fontSize: 12,
                color: AppTheme.tagText)),
      );
}

// ── A round grey pill holding a single icon ───────────────────────
class _IconPill extends StatelessWidget {
  final IconData icon;
  const _IconPill(this.icon);

  @override
  Widget build(BuildContext context) => Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: const Color(0xFFF0F0F0),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 16, color: AppTheme.tagText),
      );
}
