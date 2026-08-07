import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/trail.dart';
import '../theme/app_theme.dart';
import '../services/updates_read_service.dart';
import '../services/auth_service.dart';
import '../widgets/bottom_nav.dart';
import '../widgets/trail_card.dart';
import '../widgets/trail_image.dart';
import 'trail_profile_screen.dart';
import 'filter_wizard_screen.dart';
import 'saved_screen.dart';
import 'updates_screen.dart';
import 'profile_screen.dart';
import 'search_screen.dart';
import 'memory_wall_screen.dart';

// ─────────────────────────────────────────────────────────────────
//  HOME SCREEN  (the app shell)
//
//  This screen owns the bottom nav and acts as the shell for the
//  in-place tabs. Its body is an IndexedStack driven by _navIndex,
//  so switching tabs swaps the content WITHOUT pushing a new route —
//  which keeps the floating nav bar visible and the correct tab
//  highlighted at all times.
//
//  NAV INDEX MAP (must match the order in bottom_nav.dart):
//    0 = פרופיל   → "coming soon" placeholder (in-place)
//    1 = עדכונים   → UpdatesScreen embedded in-place (nav stays visible)
//    2 = מותאם    → filter wizard (FULL PUSH, no nav bar). Its "x"
//                   pops back here; we snap selection to בית (4).
//    3 = שמורים   → SavedScreen embedded in-place (nav stays visible)
//    4 = בית      → the real home content (default)
//
//  RTL is forced app-wide in main.dart (MaterialApp builder), so every
//  screen inherits it. .start = visual RIGHT.
// ─────────────────────────────────────────────────────────────────

// ─────────────────────────────────────────────────────────────────
//  BEN'S FAVORITES — the 7 trails shown in האהובים על בן, in display
//  order. ✏️ EDIT THIS LIST to change the selection — nothing else.
// ─────────────────────────────────────────────────────────────────
const List<String> kBensFavoriteIds = [
  'trail_7', // נחל דוד (עין גדי)
  'trail_1', // נחל חרמון (הבניאס)
  'trail_24', // הר ארבל
  'trail_16', // גן השלושה (סחנה)
  'trail_11', // טיילת מכתש רמון
  'trail_27', // שמורת תל דן
  'trail_15', // מצדה — שביל הנחש
];

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _navIndex = 4; // בית tab is active by default

  // The order of these MUST line up with the nav index map above.
  // Index 2 (מותאם) is a placeholder here only because it's never
  // actually shown in-place — it's a full push. We keep a slot so the
  // IndexedStack indices stay aligned with the nav indices.
  List<Widget> get _tabs => [
        ProfileScreen(
          embedded: true,
          // Tapping the saved stat switches to the שמורים tab in-place.
          onOpenSaved: () => setState(() => _navIndex = 3),
          // Tapping the עדכונים settings row → the עדכונים tab in-place.
          onOpenUpdates: () => setState(() => _navIndex = 1),
        ), // index 0 — פרופיל
        const UpdatesScreen(embedded: true), // index 1 — עדכונים
        // Slot for מותאם (index 2) — never displayed (full push instead).
        const SizedBox.shrink(),
        const SavedScreen(embedded: true), // index 3 — שמורים
        _buildHomeContent(), // index 4 — בית
      ];

  // ── Nav tap handler ────────────────────────────────────────────
  void _onNavTap(int i) {
    // מותאם (index 2) → push the filter wizard full-screen. We do NOT
    // leave index 2 selected: snap back to בית so when the wizard's
    // "x" pops, בית is shown and highlighted.
    if (i == 2) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const FilterWizardScreen()),
      );
      setState(() => _navIndex = 4);
      return;
    }
    // All other tabs swap in-place.
    setState(() => _navIndex = i);
  }

  @override
  Widget build(BuildContext context) {
    // Make status bar transparent with dark icons
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ));

    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: Stack(
        children: [
          // ── Tab content (swaps in-place) ──────────────────
          IndexedStack(
            index: _navIndex,
            children: _tabs,
          ),

          // ── Floating bottom nav bar (always on top) ───────
          Positioned(
            bottom: 16,
            left: 10,
            right: 10,
            child: _NavWithBadge(
              selectedIndex: _navIndex,
              onTap: _onNavTap,
            ),
          ),
        ],
      ),
    );
  }

  // ── בית (index 4): the real home content ───────────────────────
  //  Now FIRESTORE-DRIVEN: one stream of the trails collection feeds
  //  every section, so images (via TrailImage) and data are always
  //  live — the hardcoded lists in trail.dart are gone.
  Widget _buildHomeContent() {
    return SafeArea(
      bottom: false,
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('trails').snapshots(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final all = (snap.data?.docs ?? [])
              .map((d) => TrailData.fromFirestore(
                  d.id, d.data() as Map<String, dynamic>))
              .toList();

          // בסביבה שלי — honest "nearby": the location label says
          // כפר בלום, so nearby = Upper Galilee trails.
          final nearby = all.where((t) => t.region == 'הגליל העליון').toList();

          // האהובים על בן — the 7 hand-picked IDs, in display order.
          final bens = [
            for (final id in kBensFavoriteIds)
              ...all.where((t) => t.firestoreId == id),
          ];

          // מסלולי מים — every wet trail. Perfect for summer.
          final water = all.where((t) => t.isWet).toList();

          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 10),
                      _buildTopBar(),
                      const SizedBox(height: 18),
                      _buildGreeting(),
                      const SizedBox(height: 20),
                      _buildSearchRow(),
                      const SizedBox(height: 24),
                      // ── המסלול של השבוע — Firestore-driven banner ──
                      const _FeaturedBanner(),
                    ],
                  ),
                ),
              ),

              // ── בסביבה שלי ──────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _buildSectionHeader(title: 'בסביבה שלי'),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 12)),
              SliverToBoxAdapter(
                child: _TrailRow(
                  trails: nearby,
                  cardWidth: 260,
                  onTrailTap: _openTrail,
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 28)),

              // ── האהובים על בן ────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _buildSectionHeader(title: 'האהובים על בן'),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 12)),
              SliverToBoxAdapter(
                child: _TrailRow(
                  trails: bens,
                  cardWidth: 220,
                  onTrailTap: _openTrail,
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 28)),

              // ── מסלולי מים 💧 ────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _buildSectionHeader(title: 'מסלולי מים 💧'),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 12)),
              SliverToBoxAdapter(
                child: _TrailRow(
                  trails: water,
                  cardWidth: 220,
                  onTrailTap: _openTrail,
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 28)),

              // ── לזכרו של בן — tribute (console-editable) ──
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: _TributeCard(),
                ),
              ),

              // Space so content clears the floating nav bar
              const SliverToBoxAdapter(child: SizedBox(height: 110)),
            ],
          );
        },
      ),
    );
  }

  // ── Navigate to trail profile ──────────────────────────────────
  void _openTrail(TrailData trail) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TrailProfileScreen(trailId: trail.firestoreId),
      ),
    );
  }

  // ── Open the search screen ─────────────────────────────────────
  void _openSearch() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SearchScreen()),
    );
  }

  // ── עמותה badge — top right ────────────────────────────────────
  //  Tapping opens Ben's memorial page (יזכור) in the browser.
  static const String _izkorUrl =
      'https://www.izkor.gov.il/%D7%91%D7%9F%20%D7%A9%D7%9C%D7%99/en_861ea833663d0be567e2145f59f619c1';

  Future<void> _openIzkor() async {
    try {
      await launchUrl(
        Uri.parse(_izkorUrl),
        mode: LaunchMode.externalApplication,
      );
    } catch (_) {
      // No browser available — fail silently.
    }
  }

  // ── Header row: app title (right) + עמותה badge (left) ──────────
  //  Tapping the badge opens Ben's memorial page (יזכור).
  Widget _buildTopBar() {
    return Row(
      // RTL: first child = visual RIGHT, last child = visual LEFT.
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // App title — visual RIGHT
        const Text(
          'בדרכי בן',
          textAlign: TextAlign.right,
          style: TextStyle(
            fontFamily: AppTheme.font,
            fontSize: 21,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.5,
          ),
        ),
        // עמותה badge — visual LEFT
        GestureDetector(
          onTap: _openIzkor,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            decoration: BoxDecoration(
              color: AppTheme.accent,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Text('עמותה',
                    style: TextStyle(fontFamily: AppTheme.font, fontSize: 15)),
                SizedBox(width: 6),
                Icon(Icons.link_rounded, size: 20),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ── Greeting text ──────────────────────────────────────────────
  Widget _buildGreeting() {
    // Pull the signed-in user's name; use just the first word so a
    // full name like "דנה כהן" greets as "שלום דנה,". Falls back to
    // "מטייל" if for some reason there's no name.
    final fullName = AuthService.instance.displayName;
    final firstName = fullName.split(' ').first;

    return SizedBox(
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'שלום $firstName,',
            textAlign: TextAlign.right,
            style: const TextStyle(
              fontFamily: AppTheme.font,
              fontSize: 24,
              fontWeight: FontWeight.w400,
              height: 1.2,
              letterSpacing: -0.5,
            ),
          ),
          const Text(
            'לאן מטיילים היום?',
            textAlign: TextAlign.right,
            style: TextStyle(
              fontFamily: AppTheme.font,
              fontSize: 24,
              fontWeight: FontWeight.w700,
              height: 1.2,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
    );
  }

  // ── Search bar (full width) — tap opens the search screen ──────
  Widget _buildSearchRow() {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _openSearch,
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color: AppTheme.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(
                color: AppTheme.shadow, blurRadius: 4, offset: Offset(2, 1)),
          ],
        ),
        child: Row(
          children: const [
            SizedBox(width: 14),
            Expanded(
              child: Text(
                'חיפוש חופשי — לפי שם או אזור',
                textAlign: TextAlign.right,
                style: TextStyle(
                  fontFamily: AppTheme.font,
                  fontSize: 13,
                  color: Color(0xFFB0B0B0),
                ),
              ),
            ),
            SizedBox(width: 10),
            Icon(Icons.search_rounded, color: AppTheme.textMuted, size: 20),
            SizedBox(width: 12),
          ],
        ),
      ),
    );
  }

  // ── Section header: title right, optional link left ────────────
  Widget _buildSectionHeader({
    required String title,
    String? linkText,
    VoidCallback? onTap,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.max,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      // RTL: first child = visual RIGHT — so the TITLE must come first,
      // and the optional link lands on the visual LEFT.
      children: [
        Text(
          title,
          textAlign: TextAlign.right,
          style: const TextStyle(
            fontFamily: AppTheme.font,
            fontSize: 16,
            fontWeight: FontWeight.w400,
          ),
        ),
        if (linkText != null)
          GestureDetector(
            onTap: onTap,
            child: Text(
              linkText,
              style: const TextStyle(
                fontFamily: AppTheme.font,
                fontSize: 13,
                decoration: TextDecoration.underline,
              ),
            ),
          )
        else
          const SizedBox(),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────
//  FEATURED BANNER  (המסלול של השבוע)
//  A Firestore-driven highlight card the עמותה controls from the
//  console — no code changes needed to swap the featured trail:
//
//    featured/current
//      - trailId:  String  (e.g. 'trail_7')
//      - tagline:  String  (optional, e.g. 'מושלם לחורף!')
//
//  If the doc doesn't exist (or trailId is missing/bad), the banner
//  simply doesn't render — home looks like before. Tapping opens the
//  trail's profile.
// ─────────────────────────────────────────────────────────────────
class _FeaturedBanner extends StatelessWidget {
  const _FeaturedBanner();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('featured')
          .doc('current')
          .snapshots(),
      builder: (context, featSnap) {
        final feat = featSnap.data?.data() as Map<String, dynamic>?;
        final trailId = feat?['trailId'] as String?;
        if (trailId == null || trailId.isEmpty) {
          return const SizedBox(height: 4); // hidden — keep layout calm
        }
        final tagline = feat?['tagline'] as String? ?? '';

        return StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('trails')
              .doc(trailId)
              .snapshots(),
          builder: (context, trailSnap) {
            if (!trailSnap.hasData || !trailSnap.data!.exists) {
              return const SizedBox(height: 4);
            }
            final t = trailSnap.data!.data() as Map<String, dynamic>;
            final name = t['name'] as String? ?? '';
            final region = t['region'] as String? ?? '';
            final distanceKm = t['distanceKm'] as String? ?? '';

            return Column(
              children: [
                GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => TrailProfileScreen(trailId: trailId),
                    ),
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(AppTheme.radiusCard),
                      boxShadow: AppTheme.cardShadow,
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(AppTheme.radiusCard),
                      child: Stack(
                        children: [
                          // Trail photo background (webp/URL), gradient
                          // fallback when no image exists.
                          Positioned.fill(
                            child: TrailImage(
                              trailId: trailId,
                              imageUrl: t['imageUrl'] as String? ?? '',
                              fit: BoxFit.cover,
                              fallback: Container(
                                decoration: const BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Color(0xFF4A8A6A),
                                      Color(0xFF1A3A3A)
                                    ],
                                    begin: Alignment.topRight,
                                    end: Alignment.bottomLeft,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          // Dark scrim so the white text stays readable
                          // over any photo.
                          Positioned.fill(
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.black.withOpacity(0.30),
                                    Colors.black.withOpacity(0.55),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          // Content
                          Padding(
                            padding: const EdgeInsets.all(18),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // "Trail of the week" pill
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.22),
                                    borderRadius: BorderRadius.circular(
                                        AppTheme.radiusPill),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: const [
                                      Icon(Icons.star_rounded,
                                          size: 15, color: Color(0xFFF2D06B)),
                                      SizedBox(width: 5),
                                      Text(
                                        'המסלול של השבוע',
                                        style: TextStyle(
                                          fontFamily: AppTheme.font,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  name,
                                  textAlign: TextAlign.right,
                                  style: const TextStyle(
                                    fontFamily: AppTheme.font,
                                    fontSize: 22,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                if (tagline.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    tagline,
                                    textAlign: TextAlign.right,
                                    style: TextStyle(
                                      fontFamily: AppTheme.font,
                                      fontSize: 14,
                                      height: 1.4,
                                      color: Colors.white.withOpacity(0.85),
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    // Region + distance chips — visual right
                                    if (region.isNotEmpty)
                                      _FeaturedChip(text: region),
                                    if (distanceKm.isNotEmpty) ...[
                                      const SizedBox(width: 8),
                                      _FeaturedChip(text: '$distanceKm ק״מ'),
                                    ],
                                    const Spacer(),
                                    // "Open" arrow — visual left
                                    Row(
                                      children: [
                                        Text(
                                          'לצפייה במסלול',
                                          style: TextStyle(
                                            fontFamily: AppTheme.font,
                                            fontSize: 13,
                                            fontWeight: FontWeight.w700,
                                            color:
                                                Colors.white.withOpacity(0.9),
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        Icon(Icons.arrow_back_rounded,
                                            size: 16,
                                            color:
                                                Colors.white.withOpacity(0.9)),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 28),
              ],
            );
          },
        );
      },
    );
  }
}

// Small translucent chip used inside the featured banner.
class _FeaturedChip extends StatelessWidget {
  final String text;
  const _FeaturedChip({required this.text});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.18),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          text,
          style: const TextStyle(
            fontFamily: AppTheme.font,
            fontSize: 12,
            color: Colors.white,
          ),
        ),
      );
}

// ─────────────────────────────────────────────────────────────────
//  TRIBUTE CARD  (לזכרו של בן)
//  A warm, console-editable block reminding users this app honors
//  Ben. Same pattern as the featured banner:
//
//    content/tribute
//      - title: String  (e.g. 'לזכרו של בן 💚')
//      - body:  String  (a sentence or two from the עמותה)
//
//  Doc missing → the card simply doesn't render.
// ─────────────────────────────────────────────────────────────────
class _TributeCard extends StatelessWidget {
  const _TributeCard();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('content')
          .doc('tribute')
          .snapshots(),
      builder: (context, snap) {
        final d = snap.data?.data() as Map<String, dynamic>?;
        if (d == null) return const SizedBox.shrink();
        final title = d['title'] as String? ?? '';
        final body = d['body'] as String? ?? '';
        if (title.isEmpty && body.isEmpty) return const SizedBox.shrink();

        return GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const MemoryWallScreen()),
          ),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppTheme.accent.withOpacity(0.35),
              borderRadius: BorderRadius.circular(AppTheme.radiusCard),
              border:
                  Border.all(color: AppTheme.accent.withOpacity(0.6), width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  // RTL: first child = visual RIGHT.
                  children: [
                    const Icon(Icons.favorite_rounded,
                        size: 20, color: Color(0xFF2A6A3A)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        title,
                        textAlign: TextAlign.right,
                        style: const TextStyle(
                          fontFamily: AppTheme.font,
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                          color: AppTheme.tagText,
                        ),
                      ),
                    ),
                  ],
                ),
                if (body.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    body,
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      fontFamily: AppTheme.font,
                      fontSize: 14,
                      height: 1.55,
                      color: AppTheme.tagText,
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                // Footer link → the memory wall.
                Row(
                  children: const [
                    Text(
                      'לקיר הזיכרונות',
                      style: TextStyle(
                        fontFamily: AppTheme.font,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.tagText,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                    SizedBox(width: 4),
                    // Chevron pinned LTR so it actually points left.
                    Icon(
                      Icons.chevron_left_rounded,
                      size: 18,
                      color: AppTheme.tagText,
                      textDirection: TextDirection.ltr,
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────
//  NAV WITH BADGE
//  Wraps BottomNav and feeds it a live unread-updates count for the
//  עדכונים tab (index 1). Listens to the updates collection (just the
//  doc IDs) and the read service; recomputes unread whenever either
//  changes. Cheap — only ~a handful of update docs.
// ─────────────────────────────────────────────────────────────────
class _NavWithBadge extends StatelessWidget {
  final int selectedIndex;
  final void Function(int) onTap;

  const _NavWithBadge({
    required this.selectedIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: UpdatesReadService.instance,
      builder: (context, _) {
        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('updates').snapshots(),
          builder: (context, snapshot) {
            final ids =
                snapshot.data?.docs.map((d) => d.id) ?? const <String>[];
            final unread = UpdatesReadService.instance.unreadCountAmong(ids);
            return BottomNav(
              selectedIndex: selectedIndex,
              onTap: onTap,
              badgeCounts: unread > 0 ? {1: unread} : const {},
            );
          },
        );
      },
    );
  }
}

class _TrailRow extends StatelessWidget {
  final List<TrailData> trails;
  final double cardWidth;
  final void Function(TrailData) onTrailTap;

  const _TrailRow({
    required this.trails,
    required this.cardWidth,
    required this.onTrailTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 202, // a little breathing room — fixes the 2px overflow
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        reverse: true, // RTL: first item starts from the right
        padding: const EdgeInsets.symmetric(horizontal: 16),
        physics: const BouncingScrollPhysics(),
        itemCount: trails.length,
        separatorBuilder: (_, __) => const SizedBox(width: 14),
        itemBuilder: (_, i) => TrailCard(
          trail: trails[i],
          width: cardWidth,
          onTap: onTrailTap,
        ),
      ),
    );
  }
}
