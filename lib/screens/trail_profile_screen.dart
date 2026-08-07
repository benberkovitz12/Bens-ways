import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geodesy/geodesy.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as latlong;
import '../theme/app_theme.dart';
import '../services/saved_trails_service.dart';
import 'live_mode_screen.dart';
import 'chat_screen.dart';
import 'write_review_screen.dart';
import '../widgets/trail_image.dart';

// ─────────────────────────────────────────────────────────────────
//  TRAIL PROFILE SCREEN — redesigned
//
//  WHAT CHANGED (the Achilles-ankle surgery):
//  1. Hero buttons: clean white circles with soft shadows instead of
//     the light-blue pills. Back arrow pinned LTR so it actually
//     points RIGHT (RTL "back" direction — Material mirrors arrows).
//  2. The middle: title + region/type subtitle → one stats card
//     (ק״מ / זמן / רמה with icons) → full-width צא למסלול CTA →
//     two LABELED action buttons (ניווט, צ'אט מטיילים) instead of
//     anonymous icon circles. The separate GPS-check circle is gone —
//     the CTA itself runs the location check (as it already did).
//  3. Info tab: now shows EVERYTHING Firestore knows — full
//     description, a פרטי המסלול details card (אזור, סוג, דמי כניסה,
//     מתאים ל...), attraction chips, then the map.
//
//  RTL inherited app-wide. .start = visual RIGHT.
//  Icon rule: directional icons (arrows/chevrons) auto-mirror under
//  RTL — pin textDirection: TextDirection.ltr to draw them literally.
// ─────────────────────────────────────────────────────────────────

class TrailProfileScreen extends StatefulWidget {
  final String trailId;
  const TrailProfileScreen({super.key, required this.trailId});

  @override
  State<TrailProfileScreen> createState() => _TrailProfileScreenState();
}

class _TrailProfileScreenState extends State<TrailProfileScreen>
    with SingleTickerProviderStateMixin {
  Position? _currentPosition;
  bool _isOnTrail = false;
  bool _checkingLocation = false;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _checkLocationPermission();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _checkLocationPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied)
      permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always) _startLocationTracking();
  }

  void _startLocationTracking() {
    Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high, distanceFilter: 10),
    ).listen((pos) => setState(() => _currentPosition = pos));
  }

  Future<void> _checkIfOnTrail(
      double startLat, double startLng, double radiusMeters) async {
    if (_currentPosition == null) {
      _showSnack('מחפש את המיקום שלך...');
      return;
    }
    setState(() => _checkingLocation = true);
    final distance = Geodesy().distanceBetweenTwoGeoPoints(
      LatLng(startLat, startLng),
      LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
    );
    setState(() {
      _checkingLocation = false;
      _isOnTrail = distance <= radiusMeters;
    });
    _showSnack(_isOnTrail
        ? '✓ אתה על המסלול! (${distance.toStringAsFixed(0)}מ מההתחלה)'
        : 'אתה ${distance.toStringAsFixed(0)}מ מנקודת ההתחלה');
  }

  Future<void> _navigateToTrail(double lat, double lng) async {
    final url = Uri.parse(
        'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng');
    if (await canLaunchUrl(url))
      await launchUrl(url, mode: LaunchMode.externalApplication);
    else
      _showSnack('לא ניתן לפתוח את Google Maps');
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('trails')
            .doc(widget.trailId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError)
            return const Center(child: Text('שגיאה בטעינת המסלול'));
          if (snapshot.connectionState == ConnectionState.waiting)
            return const Center(child: CircularProgressIndicator());
          if (!snapshot.hasData || !snapshot.data!.exists)
            return const Center(child: Text('המסלול לא נמצא'));

          final d = snapshot.data!.data() as Map<String, dynamic>;
          final name = d['name'] as String? ?? 'מסלול';
          final description = d['description'] as String? ?? '';
          final startLat = (d['startLat'] as num?)?.toDouble() ?? 0.0;
          final startLng = (d['startLng'] as num?)?.toDouble() ?? 0.0;
          final radius = (d['startRadiusMeters'] as num?)?.toDouble() ?? 50;
          final distanceKm = d['distanceKm'] as String? ?? '';
          final duration = d['duration'] as String? ?? '';
          final difficulty = d['difficulty'] as String? ?? '';
          final imageUrl = d['imageUrl'] as String? ?? '';
          final region = d['region'] as String? ?? '';
          final isWet = d['isWet'] as bool? ?? false;
          final entryFee = d['entryFee'] as String? ?? '';
          final attractions = (d['attractions'] as List<dynamic>? ?? [])
              .map((e) => e.toString())
              .toList();
          final participantTypes =
              (d['participantType'] as List<dynamic>? ?? [])
                  .map((e) => e.toString())
                  .toList();

          // Parse pathPoints from Firestore
          final rawPoints = d['pathPoints'] as List<dynamic>? ?? [];
          final pathPoints = rawPoints.map((p) {
            final map = p as Map<String, dynamic>;
            return latlong.LatLng(
              (map['lat'] as num).toDouble(),
              (map['lng'] as num).toDouble(),
            );
          }).toList();

          return Column(
            children: [
              // ── Hero image ─────────────────────────────────
              SizedBox(
                height: 300,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    TrailImage(
                      trailId: widget.trailId,
                      imageUrl: imageUrl,
                      fit: BoxFit.cover,
                      fallback: _heroGradient(),
                    ),
                    Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.transparent, Color(0x88000000)],
                        ),
                      ),
                    ),
                    SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 10),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Back — visual RIGHT, arrow points RIGHT
                            // (pinned LTR to beat the RTL mirroring).
                            _HeroBtn(
                              icon: Icons.arrow_forward_rounded,
                              onTap: () => Navigator.pop(context),
                            ),
                            Row(children: [
                              // Bookmark — wired to the saved service.
                              _HeroBookmarkBtn(trailId: widget.trailId),
                              const SizedBox(width: 10),
                              // Share — opens the system share sheet.
                              _HeroBtn(
                                icon: Icons.ios_share_rounded,
                                onTap: () => Share.share(
                                  'צאו איתי למסלול $name! 🥾\n'
                                  '$description\n'
                                  'מתוך אפליקציית Ben\'s Way 💚',
                                ),
                              ),
                            ]),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // ── Scrollable body ─────────────────────────────
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // ── Title + region/type line ──────────
                            Text(name,
                                textAlign: TextAlign.right,
                                style: const TextStyle(
                                  fontFamily: AppTheme.font,
                                  fontSize: 25,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -0.5,
                                )),
                            const SizedBox(height: 4),
                            Text(
                              [
                                if (region.isNotEmpty) region,
                                isWet ? 'מסלול מים 💧' : 'מסלול יבש ☀️',
                              ].join(' · '),
                              textAlign: TextAlign.right,
                              style: const TextStyle(
                                fontFamily: AppTheme.font,
                                fontSize: 14,
                                color: AppTheme.textMuted,
                              ),
                            ),
                            const SizedBox(height: 16),

                            // ── Stats card: ק״מ / זמן / רמה ───────
                            Container(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              decoration: BoxDecoration(
                                color: AppTheme.white,
                                borderRadius:
                                    BorderRadius.circular(AppTheme.radiusCard),
                                boxShadow: AppTheme.cardShadow,
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceAround,
                                children: [
                                  _StatBlock(
                                    icon: Icons.straighten_rounded,
                                    value: distanceKm.isNotEmpty
                                        ? distanceKm
                                        : '—',
                                    label: 'ק״מ',
                                  ),
                                  const _StatDivider(),
                                  _StatBlock(
                                    icon: Icons.schedule_rounded,
                                    value: duration.isNotEmpty ? duration : '—',
                                    label: 'זמן',
                                  ),
                                  const _StatDivider(),
                                  _StatBlock(
                                    icon: Icons.trending_up_rounded,
                                    value: difficulty.isNotEmpty
                                        ? difficulty
                                        : '—',
                                    label: 'רמה',
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 14),

                            // ── Primary CTA — full width ──────────
                            //  Not on trail → runs the GPS check.
                            //  On trail → opens live mode.
                            _CtaButton(
                              isOnTrail: _isOnTrail,
                              isChecking: _checkingLocation,
                              onTap: _isOnTrail
                                  ? () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => LiveModeScreen(
                                          trailId: widget.trailId,
                                          trailName: name,
                                          startLat: startLat,
                                          startLng: startLng,
                                        ),
                                      ))
                                  : () => _checkIfOnTrail(
                                      startLat, startLng, radius),
                            ),
                            const SizedBox(height: 10),

                            // ── Labeled secondary actions ─────────
                            Row(
                              children: [
                                // ניווט — visual RIGHT
                                Expanded(
                                  child: _LabeledAction(
                                    icon: Icons.navigation_rounded,
                                    label: 'ניווט להתחלה',
                                    onTap: () =>
                                        _navigateToTrail(startLat, startLng),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                // צ'אט — visual LEFT
                                Expanded(
                                  child: _LabeledAction(
                                    icon: Icons.chat_bubble_outline_rounded,
                                    label: 'צ\'אט מטיילים',
                                    onTap: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => ChatScreen(
                                          trailId: widget.trailId,
                                          trailName: name,
                                          startLat: startLat,
                                          startLng: startLng,
                                          startRadiusMeters: radius,
                                          knownOnTrail: _isOnTrail,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 18),
                          ],
                        ),
                      ),

                      // ── Tab bar ─────────────────────────────
                      Container(
                        decoration: const BoxDecoration(
                          border: Border(
                            bottom:
                                BorderSide(color: AppTheme.divider, width: 1),
                          ),
                        ),
                        child: TabBar(
                          controller: _tabController,
                          labelStyle: const TextStyle(
                              fontFamily: AppTheme.font,
                              fontSize: 14,
                              fontWeight: FontWeight.w700),
                          unselectedLabelStyle: const TextStyle(
                              fontFamily: AppTheme.font, fontSize: 14),
                          labelColor: AppTheme.black,
                          unselectedLabelColor: AppTheme.textMuted,
                          indicatorColor: AppTheme.accentDark,
                          indicatorWeight: 3,
                          tabs: const [
                            Tab(text: 'מידע'),
                            Tab(text: 'מוקדי עניין'),
                            Tab(text: 'ביקורות'),
                          ],
                        ),
                      ),

                      // ── Tab content ─────────────────────────
                      SizedBox(
                        height: MediaQuery.of(context).size.height * 1.2,
                        child: TabBarView(
                          controller: _tabController,
                          children: [
                            _InfoTab(
                              description: description,
                              trailId: widget.trailId,
                              startLat: startLat,
                              startLng: startLng,
                              pathPoints: pathPoints,
                              region: region,
                              isWet: isWet,
                              entryFee: entryFee,
                              attractions: attractions,
                              participantTypes: participantTypes,
                            ),
                            _PoisTab(trailId: widget.trailId),
                            _ReviewsTab(
                                trailId: widget.trailId, trailName: name),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _heroGradient() => Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF4A8A6A), Color(0xFF1A3A3A)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
      );
}

// ── Hero circle button — clean white, soft shadow. Directional icons
//    are pinned LTR so RTL mirroring can't flip them.
class _HeroBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _HeroBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppTheme.white,
            shape: BoxShape.circle,
            boxShadow: AppTheme.cardShadow,
          ),
          child: Icon(
            icon,
            size: 20,
            color: AppTheme.black,
            textDirection: TextDirection.ltr, // ← no RTL mirroring
          ),
        ),
      );
}

// ── Hero bookmark button — white circle; filled bookmark when saved.
class _HeroBookmarkBtn extends StatelessWidget {
  final String trailId;
  const _HeroBookmarkBtn({required this.trailId});

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
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppTheme.white,
              shape: BoxShape.circle,
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

// ── Full-width primary CTA (צא למסלול / כנס למצב חי) ───────────────
class _CtaButton extends StatelessWidget {
  final bool isOnTrail;
  final bool isChecking;
  final VoidCallback onTap;
  const _CtaButton({
    required this.isOnTrail,
    required this.isChecking,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: isChecking ? null : onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 15),
          decoration: BoxDecoration(
            color: AppTheme.accent,
            borderRadius: BorderRadius.circular(18),
            boxShadow: AppTheme.ctaShadow,
          ),
          child: isChecking
              ? const Center(
                  child: SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2.5),
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      isOnTrail
                          ? Icons.play_circle_outline_rounded
                          : Icons.hiking_rounded,
                      size: 21,
                      color: AppTheme.black,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isOnTrail ? 'כנס למצב חי' : 'צא למסלול',
                      style: const TextStyle(
                        fontFamily: AppTheme.font,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
        ),
      );
}

// ── Labeled secondary action (icon + text — no more mystery circles)
class _LabeledAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _LabeledAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: AppTheme.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: AppTheme.cardShadow,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: AppTheme.tagText),
              const SizedBox(width: 7),
              Text(
                label,
                style: const TextStyle(
                  fontFamily: AppTheme.font,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.tagText,
                ),
              ),
            ],
          ),
        ),
      );
}

// ── One stat: small icon, big value, label ─────────────────────────
class _StatBlock extends StatelessWidget {
  final IconData icon;
  final String value, label;
  const _StatBlock({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) => Column(
        children: [
          Icon(icon, size: 17, color: AppTheme.textMuted),
          const SizedBox(height: 6),
          Text(value,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontFamily: AppTheme.font,
                  fontSize: 19,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.tagText,
                  height: 1)),
          const SizedBox(height: 3),
          Text(label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontFamily: AppTheme.font,
                  fontSize: 12.5,
                  color: AppTheme.textMuted)),
        ],
      );
}

class _StatDivider extends StatelessWidget {
  const _StatDivider();
  @override
  Widget build(BuildContext context) =>
      Container(width: 1, height: 48, color: AppTheme.divider);
}

// ─────────────────────────────────────────────────────────────────
//  INFO TAB — now shows everything Firestore knows about the trail:
//    1. תיאור המסלול — the FULL description
//    2. פרטי המסלול  — details card (אזור, סוג, דמי כניסה, מתאים ל)
//    3. מה תראו בדרך — attraction chips
//    4. מהלך הטיול   — the OpenStreetMap with the route polyline
// ─────────────────────────────────────────────────────────────────
class _InfoTab extends StatelessWidget {
  final String description, trailId;
  final double startLat, startLng;
  final List<latlong.LatLng> pathPoints;
  final String region;
  final bool isWet;
  final String entryFee;
  final List<String> attractions;
  final List<String> participantTypes;

  const _InfoTab({
    required this.description,
    required this.trailId,
    required this.startLat,
    required this.startLng,
    required this.pathPoints,
    required this.region,
    required this.isWet,
    required this.entryFee,
    required this.attractions,
    required this.participantTypes,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── 1. Full description ─────────────────────────────
          if (description.isNotEmpty) ...[
            const _InfoSectionTitle('תיאור המסלול'),
            const SizedBox(height: 8),
            Text(description,
                textAlign: TextAlign.right,
                style: const TextStyle(
                    fontFamily: AppTheme.font, fontSize: 14.5, height: 1.65)),
            const SizedBox(height: 22),
          ],

          // ── 2. Details card ─────────────────────────────────
          const _InfoSectionTitle('פרטי המסלול'),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.white,
              borderRadius: BorderRadius.circular(AppTheme.radiusCard),
              boxShadow: AppTheme.cardShadow,
            ),
            child: Column(
              children: [
                if (region.isNotEmpty)
                  _DetailRow(
                    icon: Icons.map_outlined,
                    label: 'אזור',
                    value: region,
                  ),
                _DetailRow(
                  icon: isWet
                      ? Icons.water_drop_outlined
                      : Icons.wb_sunny_outlined,
                  label: 'סוג המסלול',
                  value: isWet ? 'מסלול מים — באים להירטב' : 'מסלול יבש',
                ),
                if (entryFee.isNotEmpty)
                  _DetailRow(
                    icon: Icons.confirmation_number_outlined,
                    label: 'דמי כניסה',
                    value: entryFee,
                  ),
                if (participantTypes.isNotEmpty)
                  _DetailRow(
                    icon: Icons.groups_outlined,
                    label: 'מתאים ל',
                    value: participantTypes.join(', '),
                    isLast: true,
                  ),
              ],
            ),
          ),
          const SizedBox(height: 22),

          // ── 3. Attractions chips ────────────────────────────
          if (attractions.isNotEmpty) ...[
            const _InfoSectionTitle('מה תראו בדרך'),
            const SizedBox(height: 10),
            Wrap(
              alignment: WrapAlignment.start,
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final a in attractions)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
                    decoration: BoxDecoration(
                      color: AppTheme.accent.withOpacity(0.4),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      a,
                      style: const TextStyle(
                        fontFamily: AppTheme.font,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.tagText,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 22),
          ],

          // ── 4. The map ──────────────────────────────────────
          const _InfoSectionTitle('מהלך הטיול'),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: SizedBox(
              width: double.infinity,
              height: 280,
              child: FlutterMap(
                options: MapOptions(
                  initialCenter: latlong.LatLng(startLat, startLng),
                  initialZoom: 14.5,
                  interactionOptions: const InteractionOptions(
                    flags: InteractiveFlag.pinchZoom | InteractiveFlag.drag,
                  ),
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.example.bens_ways',
                  ),
                  if (pathPoints.isNotEmpty)
                    PolylineLayer(
                      polylines: [
                        Polyline(
                          points: pathPoints,
                          strokeWidth: 4.0,
                          color: AppTheme.accentDark,
                        ),
                      ],
                    ),
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: latlong.LatLng(startLat, startLng),
                        width: 36,
                        height: 36,
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppTheme.accent,
                            shape: BoxShape.circle,
                            border: Border.all(color: AppTheme.white, width: 2),
                            boxShadow: AppTheme.cardShadow,
                          ),
                          child: const Icon(Icons.hiking_rounded,
                              color: AppTheme.black, size: 18),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Bold section title inside the info tab.
class _InfoSectionTitle extends StatelessWidget {
  final String text;
  const _InfoSectionTitle(this.text);

  @override
  Widget build(BuildContext context) => Text(
        text,
        textAlign: TextAlign.right,
        style: const TextStyle(
          fontFamily: AppTheme.font,
          fontSize: 16,
          fontWeight: FontWeight.w800,
        ),
      );
}

// One row inside the details card: icon + label (right), value (left).
class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label, value;
  final bool isLast;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : const Border(
                bottom: BorderSide(color: AppTheme.divider, width: 1),
              ),
      ),
      child: Row(
        // RTL: first child = visual RIGHT, last child = visual LEFT.
        children: [
          Icon(icon, size: 18, color: AppTheme.textMuted),
          const SizedBox(width: 10),
          Text(
            label,
            style: const TextStyle(
              fontFamily: AppTheme.font,
              fontSize: 14,
              color: AppTheme.textMuted,
            ),
          ),
          const Spacer(),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.left,
              style: const TextStyle(
                fontFamily: AppTheme.font,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
//  POIS TAB  (מוקדי עניין)
//  Numbered stops along the trail, in walking order — like a little
//  itinerary: 1, 2, 3... Each stop has a name, a short description,
//  and a type icon.
//
//  DATA:  trails/{trailId}/pois/{poiId}
//    - name:        String
//    - description: String
//    - type:        String  (waterfall/spring/lookout/heritage/
//                            cave/pool/nature — picks the icon)
//    - order:       number  (1-based position along the trail)
// ─────────────────────────────────────────────────────────────────
class _PoisTab extends StatelessWidget {
  final String trailId;
  const _PoisTab({required this.trailId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('trails')
          .doc(trailId)
          .collection('pois')
          .orderBy('order')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting)
          return const Center(child: CircularProgressIndicator());
        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty)
          return const _PlaceholderTab(
              icon: Icons.place_outlined, text: 'מוקדי עניין יתווספו בקרוב');

        return ListView.separated(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
          itemCount: docs.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (_, i) {
            final p = docs[i].data() as Map<String, dynamic>;
            return _PoiCard(
              number: (p['order'] as num?)?.toInt() ?? (i + 1),
              name: p['name'] as String? ?? 'מוקד עניין',
              description: p['description'] as String? ?? '',
              type: p['type'] as String? ?? '',
            );
          },
        );
      },
    );
  }
}

// ── A single numbered stop ─────────────────────────────────────────
class _PoiCard extends StatelessWidget {
  final int number;
  final String name, description, type;

  const _PoiCard({
    required this.number,
    required this.name,
    required this.description,
    required this.type,
  });

  IconData get _icon {
    switch (type) {
      case 'waterfall':
        return Icons.water_drop_rounded;
      case 'spring':
        return Icons.water_rounded;
      case 'pool':
        return Icons.pool_rounded;
      case 'lookout':
        return Icons.landscape_rounded;
      case 'heritage':
        return Icons.account_balance_rounded;
      case 'cave':
        return Icons.terrain_rounded;
      case 'nature':
        return Icons.park_rounded;
      default:
        return Icons.place_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        // RTL: first child = visual RIGHT, last child = visual LEFT.
        children: [
          // Number circle — visual RIGHT (leads the stop, like "1.")
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: AppTheme.accent,
              shape: BoxShape.circle,
            ),
            child: Text(
              '$number',
              style: const TextStyle(
                fontFamily: AppTheme.font,
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: AppTheme.black,
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Name + description — fills the middle
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    fontFamily: AppTheme.font,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                if (description.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    description,
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      fontFamily: AppTheme.font,
                      fontSize: 13.5,
                      height: 1.45,
                      color: AppTheme.textMuted,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Type icon — visual LEFT
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppTheme.accent.withOpacity(0.35),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(_icon, size: 20, color: AppTheme.tagText),
          ),
        ],
      ),
    );
  }
}

class _ReviewsTab extends StatelessWidget {
  final String trailId;
  final String trailName;
  const _ReviewsTab({required this.trailId, required this.trailName});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ── Write-review button (always visible) ──────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 4),
          child: GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => WriteReviewScreen(
                  trailId: trailId,
                  trailName: trailName,
                ),
              ),
            ),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 13),
              decoration: BoxDecoration(
                color: AppTheme.accent,
                borderRadius: BorderRadius.circular(AppTheme.radiusPill),
                boxShadow: AppTheme.cardShadow,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.edit_rounded, size: 18, color: AppTheme.black),
                  SizedBox(width: 8),
                  Text(
                    'כתוב ביקורת',
                    style: TextStyle(
                      fontFamily: AppTheme.font,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // ── The reviews stream ─────────────────────────────────
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('trails')
                .doc(trailId)
                .collection('reviews')
                .orderBy('timestamp', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting)
                return const Center(child: CircularProgressIndicator());
              final docs = snapshot.data?.docs ?? [];
              if (docs.isEmpty)
                return const _PlaceholderTab(
                    icon: Icons.rate_review_outlined,
                    text: 'אין עדיין ביקורות - היה הראשון!');

              return ListView.separated(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
                itemCount: docs.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (_, i) {
                  final r = docs[i].data() as Map<String, dynamic>;
                  return _ReviewCard(
                    name: r['userName'] as String? ?? 'משתמש',
                    text: r['text'] as String? ?? '',
                    stars: (r['stars'] as num?)?.toInt() ?? 4,
                    dateStr: _formatDate(r['timestamp']),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  String _formatDate(dynamic ts) {
    if (ts is Timestamp) {
      final d = ts.toDate();
      const m = [
        '',
        'ינואר',
        'פברואר',
        'מרץ',
        'אפריל',
        'מאי',
        'יוני',
        'יולי',
        'אוגוסט',
        'ספטמבר',
        'אוקטובר',
        'נובמבר',
        'דצמבר'
      ];
      return '${m[d.month]} ${d.year}';
    }
    return '';
  }
}

class _ReviewCard extends StatelessWidget {
  final String name, text, dateStr;
  final int stars;
  const _ReviewCard({
    required this.name,
    required this.text,
    required this.stars,
    required this.dateStr,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 16),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(name,
              textAlign: TextAlign.right,
              style: const TextStyle(
                  fontFamily: AppTheme.font,
                  fontSize: 16,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(dateStr,
                  style: const TextStyle(
                      fontFamily: AppTheme.font,
                      fontSize: 12,
                      color: Color(0xFFD0D0D0))),
              Row(
                children: List.generate(
                    5,
                    (i) => Icon(
                          i < stars
                              ? Icons.star_rounded
                              : Icons.star_border_rounded,
                          size: 14,
                          color: AppTheme.black,
                        )),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(text,
              textAlign: TextAlign.right,
              style: const TextStyle(
                  fontFamily: AppTheme.font, fontSize: 14, height: 1.45)),
        ],
      ),
    );
  }
}

class _PlaceholderTab extends StatelessWidget {
  final IconData icon;
  final String text;
  const _PlaceholderTab({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 52, color: const Color(0xFFD0D0D0)),
            const SizedBox(height: 14),
            Text(text,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontFamily: AppTheme.font,
                    fontSize: 15,
                    color: AppTheme.textMuted)),
          ],
        ),
      );
}
