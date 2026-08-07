import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme/app_theme.dart';
import '../services/saved_trails_service.dart';
import '../widgets/trail_image.dart';
import 'trail_profile_screen.dart';

// ─────────────────────────────────────────────────────────────────
//  SAVED SCREEN  (שמורים)
//  Shows the trails the user has bookmarked, grouped by region in
//  collapsible accordions, matching the Figma:
//    - header "מסלולים ששמרתי" + live count subtitle
//    - one accordion per region that HAS at least one saved trail
//    - tapping a region header expands/collapses its trail cards
//
//  HOW IT WORKS:
//  We listen to SavedTrailsService for the set of saved IDs, and we
//  stream ALL trails from Firestore (only 6, cheap). We keep only the
//  trails whose id is saved, bucket them by their 'region' field, then
//  render a section per non-empty region in a fixed display order.
//
//  Unsaving from a card here removes it live (the service notifies,
//  the StreamBuilder/AnimatedBuilder rebuilds, the card disappears).
//
//  EMBEDDED MODE:
//  When used as a TAB inside HomeScreen (so the bottom nav stays
//  visible), pass embedded: true. That skips this screen's own
//  Scaffold/SafeArea (the host already provides them) and adds bottom
//  padding so cards clear the floating nav bar. When pushed as its own
//  full screen, leave embedded false (the default) and it behaves as
//  before.
//
//  RTL: inherited app-wide. .start = visual RIGHT. The chevron uses
//  chevron_left when collapsed so it visually points RIGHT (toward the
//  text) in RTL, matching the "<" in the mockup; chevron points down
//  when expanded.
// ─────────────────────────────────────────────────────────────────

// Flip to true if you ever want every region shown even with 0 saved.
const bool _showEmptyRegions = false;

// Fixed top-to-bottom display order for regions. Any region not in
// this list still shows (appended at the end) so nothing is ever lost.
const List<String> _regionOrder = [
  'הגליל העליון',
  'הגליל התחתון',
  'הבקעה והעמקים',
  'הכרמל והחוף',
  'השרון והמרכז',
  'ירושלים והסביבה',
  'יהודה ושומרון',
  'הנגב',
];

class SavedScreen extends StatelessWidget {
  // When true, render as a tab body (no own Scaffold/SafeArea).
  final bool embedded;

  const SavedScreen({super.key, this.embedded = false});

  @override
  Widget build(BuildContext context) {
    // The actual content, independent of whether we're embedded.
    final content = AnimatedBuilder(
      // Rebuild whenever the saved set changes (e.g. user unsaves
      // a trail from a card here).
      animation: SavedTrailsService.instance,
      builder: (context, _) {
        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('trails').snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return const Center(child: Text('שגיאה בטעינת המסלולים'));
            }

            final savedIds = SavedTrailsService.instance.savedIds;
            final allDocs = snapshot.data?.docs ?? [];

            // Keep only saved trails.
            final savedDocs =
                allDocs.where((doc) => savedIds.contains(doc.id)).toList();

            // Bucket saved trails by region.
            final Map<String, List<QueryDocumentSnapshot>> byRegion = {};
            for (final doc in savedDocs) {
              final data = doc.data() as Map<String, dynamic>;
              final region =
                  (data['region'] as String?)?.trim().isNotEmpty == true
                      ? (data['region'] as String).trim()
                      : 'אחר';
              byRegion.putIfAbsent(region, () => []).add(doc);
            }

            // Build the ordered list of regions to display.
            final orderedRegions = <String>[];
            for (final r in _regionOrder) {
              if (byRegion.containsKey(r) || _showEmptyRegions) {
                orderedRegions.add(r);
              }
            }
            // Append any regions present in data but not in our order.
            for (final r in byRegion.keys) {
              if (!orderedRegions.contains(r)) orderedRegions.add(r);
            }

            return CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: _Header(count: savedIds.length),
                ),
                if (savedDocs.isEmpty)
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: _EmptyState(),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 110),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, i) {
                          final region = orderedRegions[i];
                          final docs = byRegion[region] ?? const [];
                          return _RegionSection(
                            region: region,
                            docs: docs,
                            // First non-empty region starts open.
                            initiallyExpanded: i == 0,
                          );
                        },
                        childCount: orderedRegions.length,
                      ),
                    ),
                  ),
              ],
            );
          },
        );
      },
    );

    // Embedded as a tab → return the content bare; the host
    // (HomeScreen) already provides Scaffold + SafeArea + nav bar.
    if (embedded) {
      return SafeArea(bottom: false, child: content);
    }

    // Standalone (pushed) → wrap in its own Scaffold as before.
    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: SafeArea(child: content),
    );
  }
}

// ── Header: search icon (left) + title block (right) ───────────────
class _Header extends StatelessWidget {
  final int count;
  const _Header({required this.count});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Search button — visual left (inert for now, no search screen)
          GestureDetector(
            onTap: () {},
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppTheme.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: AppTheme.cardShadow,
              ),
              child: const Icon(Icons.search_rounded,
                  size: 24, color: AppTheme.black),
            ),
          ),
          // Title + subtitle — visual right
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text(
                'מסלולים ששמרתי',
                textAlign: TextAlign.right,
                style: TextStyle(
                  fontFamily: AppTheme.font,
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '$count מסלולים שמורים',
                textAlign: TextAlign.right,
                style: const TextStyle(
                  fontFamily: AppTheme.font,
                  fontSize: 14,
                  color: AppTheme.textMuted,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── A collapsible region accordion ─────────────────────────────────
class _RegionSection extends StatefulWidget {
  final String region;
  final List<QueryDocumentSnapshot> docs;
  final bool initiallyExpanded;

  const _RegionSection({
    required this.region,
    required this.docs,
    required this.initiallyExpanded,
  });

  @override
  State<_RegionSection> createState() => _RegionSectionState();
}

class _RegionSectionState extends State<_RegionSection> {
  late bool _expanded = widget.initiallyExpanded;

  @override
  Widget build(BuildContext context) {
    final count = widget.docs.length;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: _expanded ? AppTheme.white : AppTheme.bg,
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        border: Border.all(color: AppTheme.divider, width: 1),
        boxShadow: _expanded ? AppTheme.cardShadow : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Region header (tap to toggle) ────────────────────
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Count + chevron — visual left
                  Row(
                    children: [
                      Icon(
                        _expanded
                            ? Icons.keyboard_arrow_down_rounded
                            : Icons.chevron_left_rounded,
                        size: 24,
                        color: AppTheme.black,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '$count מסלולים',
                        style: const TextStyle(
                          fontFamily: AppTheme.font,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  // Region name — visual right
                  Text(
                    widget.region,
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      fontFamily: AppTheme.font,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.tagText,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Expanded trail cards ─────────────────────────────
          if (_expanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Column(
                children: [
                  for (final doc in widget.docs) ...[
                    _SavedCard(
                      trailId: doc.id,
                      data: doc.data() as Map<String, dynamic>,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => TrailProfileScreen(trailId: doc.id),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
//  SAVED CARD — full-width trail card (mirrors the results screen
//  card). Image with a working bookmark overlay, stats, tag pills,
//  name, description. Tapping the bookmark unsaves and removes it.
// ─────────────────────────────────────────────────────────────────
class _SavedCard extends StatelessWidget {
  final String trailId;
  final Map<String, dynamic> data;
  final VoidCallback onTap;

  const _SavedCard({
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
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(20),
                    bottom: Radius.circular(8),
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    height: 170,
                    child: TrailImage(
                      trailId: trailId,
                      imageUrl: imageUrl,
                      fit: BoxFit.cover,
                      fallback: _gradientBox(grad),
                    ),
                  ),
                ),
                // Bookmark — top-left (visual) in RTL. Tap to unsave.
                Positioned(
                  top: 10,
                  left: 10,
                  child: _CardBookmark(trailId: trailId),
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
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
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
                      ..._buildTagPills(isWet, entryFee, difficulty),
                    ],
                  ),
                  const SizedBox(height: 10),
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
    if (pills.isNotEmpty && pills.last is SizedBox) {
      pills.removeLast();
    }
    return pills;
  }

  Widget _gradientBox(List<Color> colors) => Container(
        width: double.infinity,
        height: 170,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: colors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
      );
}

// ── Bookmark on a saved card — always filled here; tap to unsave ───
class _CardBookmark extends StatelessWidget {
  final String trailId;
  const _CardBookmark({required this.trailId});

  @override
  Widget build(BuildContext context) {
    final saved = SavedTrailsService.instance;
    return AnimatedBuilder(
      animation: saved,
      builder: (context, _) {
        final isSaved = saved.isSaved(trailId);
        return GestureDetector(
          onTap: () => saved.toggle(trailId),
          child: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppTheme.accentDark,
              borderRadius: BorderRadius.circular(14),
              boxShadow: AppTheme.cardShadow,
            ),
            child: Icon(
              isSaved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
              size: 20,
              color: AppTheme.black,
            ),
          ),
        );
      },
    );
  }
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

// ── Empty state — nothing saved yet ────────────────────────────────
class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.bookmark_border_rounded,
                size: 60, color: Color(0xFFD0D0D0)),
            SizedBox(height: 16),
            Text(
              'עוד לא שמרת מסלולים',
              style: TextStyle(
                  fontFamily: AppTheme.font,
                  fontSize: 17,
                  fontWeight: FontWeight.w700),
            ),
            SizedBox(height: 6),
            Text(
              'לחץ על הסימניה במסלול כדי לשמור אותו כאן',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontFamily: AppTheme.font,
                  fontSize: 14,
                  color: AppTheme.textMuted),
            ),
          ],
        ),
      );
}
