import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme/app_theme.dart';
import '../models/trail_filter.dart';
import 'filter_results_screen.dart';

// ─────────────────────────────────────────────────────────────────
//  FILTER SCREEN  (מותאם) — single-page edition
//
//  The old 4-step PageView wizard is gone. Everything now lives on
//  ONE scrollable screen, grouped into white section cards:
//
//    1. אזור בארץ        — region chips (multi-select)
//    2. סוג המסלול        — רטוב 💧 / יבש ☀️ big toggle cards
//    3. מה אני רוצה לראות — attraction chips with icons
//    4. אופי הטיול        — fee / difficulty / participants pills
//    5. אורך המסלול       — max distance + max duration sliders
//
//  THE LIVE COUNT: the whole screen sits inside one Firestore stream
//  of the trails collection. Every toggle re-runs the in-memory
//  filter, and the sticky bottom button always shows exactly how many
//  trails match RIGHT NOW — "הצג 12 מסלולים". No more guessing, no
//  more landing on an empty results screen.
//
//  Every filter is still optional; nothing selected = all trails.
//  "נקה הכל" in the header resets everything.
//
//  NOTE: class name stays FilterWizardScreen so home_screen.dart's
//  nav wiring (index 2 → push) needs zero changes.
//
//  RTL: inherited app-wide. .start = visual RIGHT.
//  Row rule: first child = visual RIGHT, last = visual LEFT.
// ─────────────────────────────────────────────────────────────────

// Available regions (same list as before — kept identical so existing
// Firestore region values keep matching).
const List<String> kRegions = [
  'הגליל העליון',
  'הגליל התחתון',
  'חיפה והכרמל',
  'הבקעה והעמקים',
  'השרון',
  'מרכז',
  'ירושלים והסביבה',
  'הנגב',
];

// The attraction options that exist in the trail data.
const List<_Attraction> kAttractions = [
  _Attraction(label: 'מפלים', icon: Icons.water_rounded),
  _Attraction(label: 'הרים', icon: Icons.terrain_rounded),
  _Attraction(label: 'נחל', icon: Icons.waves_rounded),
  _Attraction(label: 'תצפית', icon: Icons.visibility_outlined),
  _Attraction(label: 'מעיין', icon: Icons.opacity_rounded),
];

class _Attraction {
  final String label;
  final IconData icon;
  const _Attraction({required this.label, required this.icon});
}

const List<String> kEntryFees = ['חינם', 'בתשלום'];

const List<String> kDifficulties = [
  'קל',
  'קל-בינוני',
  'בינוני',
  'בינוני-קשה',
  'קשה',
  'מטיבי לכת',
];

const List<String> kParticipantTypes = [
  'משפחתי',
  'זוגי',
  'קבוצתי',
  'אדם אחד',
];

const double kMaxDistance = 30; // km upper bound on the slider
const double kMaxDuration = 12; // hours upper bound on the slider

// Mutable draft that collects the user's choices.
class _Draft {
  Set<String> regions = {};
  bool? isWet;
  Set<String> attractions = {};
  Set<String> entryFees = {};
  Set<String> difficulties = {};
  Set<String> participantTypes = {};
  double? maxDistanceKm;
  double? maxDurationHours;

  void clear() {
    regions.clear();
    isWet = null;
    attractions.clear();
    entryFees.clear();
    difficulties.clear();
    participantTypes.clear();
    maxDistanceKm = null;
    maxDurationHours = null;
  }

  bool get isEmpty =>
      regions.isEmpty &&
      isWet == null &&
      attractions.isEmpty &&
      entryFees.isEmpty &&
      difficulties.isEmpty &&
      participantTypes.isEmpty &&
      maxDistanceKm == null &&
      maxDurationHours == null;

  TrailFilter toFilter() => TrailFilter(
        regions: regions,
        isWet: isWet,
        attractions: attractions,
        entryFees: entryFees,
        difficulties: difficulties,
        participantTypes: participantTypes,
        maxDistanceKm: maxDistanceKm,
        maxDurationHours: maxDurationHours,
      );
}

class FilterWizardScreen extends StatefulWidget {
  const FilterWizardScreen({super.key});

  @override
  State<FilterWizardScreen> createState() => _FilterWizardScreenState();
}

class _FilterWizardScreenState extends State<FilterWizardScreen> {
  final _Draft _draft = _Draft();

  // Freeze the draft and open the results screen.
  void _finish() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => FilterResultsScreen(filter: _draft.toFilter()),
      ),
    );
  }

  // Toggle a value in/out of a set, then refresh.
  void _toggle(Set<String> set, String value) {
    setState(() {
      if (set.contains(value)) {
        set.remove(value);
      } else {
        set.add(value);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: SafeArea(
        // ONE stream feeds both the live count and (via the results
        // screen later) the actual list — only a few dozen docs, cheap.
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('trails').snapshots(),
          builder: (context, snap) {
            // Live match count for the sticky button. While the stream
            // warms up we show null → the button says "טוען...".
            int? count;
            if (snap.hasData) {
              final filter = _draft.toFilter();
              count = snap.data!.docs.where((doc) {
                final data = doc.data() as Map<String, dynamic>;
                return filter.matches(data);
              }).length;
            }

            return Column(
              children: [
                _buildHeader(),

                // ── The one big scroll ────────────────────────
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // 1 ── אזור ─────────────────────────────
                        _SectionCard(
                          icon: Icons.map_outlined,
                          title: 'אזור בארץ',
                          child: _chipWrap(
                            children: [
                              for (final r in kRegions)
                                _FilterPill(
                                  label: r,
                                  selected: _draft.regions.contains(r),
                                  onTap: () => _toggle(_draft.regions, r),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),

                        // 2 ── סוג המסלול ───────────────────────
                        _SectionCard(
                          icon: Icons.water_drop_outlined,
                          title: 'סוג המסלול',
                          child: Row(
                            children: [
                              // רטוב — visual RIGHT
                              Expanded(
                                child: _TypeCard(
                                  emoji: '💧',
                                  label: 'רטוב',
                                  hint: 'מים בדרך',
                                  selected: _draft.isWet == true,
                                  onTap: () => setState(() {
                                    _draft.isWet =
                                        _draft.isWet == true ? null : true;
                                  }),
                                ),
                              ),
                              const SizedBox(width: 12),
                              // יבש — visual LEFT
                              Expanded(
                                child: _TypeCard(
                                  emoji: '☀️',
                                  label: 'יבש',
                                  hint: 'בלי להירטב',
                                  selected: _draft.isWet == false,
                                  onTap: () => setState(() {
                                    _draft.isWet =
                                        _draft.isWet == false ? null : false;
                                  }),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),

                        // 3 ── אטרקציות ─────────────────────────
                        _SectionCard(
                          icon: Icons.photo_camera_outlined,
                          title: 'מה אני רוצה לראות',
                          child: _chipWrap(
                            children: [
                              for (final a in kAttractions)
                                _FilterPill(
                                  label: a.label,
                                  icon: a.icon,
                                  selected:
                                      _draft.attractions.contains(a.label),
                                  onTap: () =>
                                      _toggle(_draft.attractions, a.label),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),

                        // 4 ── אופי הטיול ───────────────────────
                        _SectionCard(
                          icon: Icons.tune_rounded,
                          title: 'אופי הטיול',
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const _SubTitle('דמי כניסה'),
                              _chipWrap(
                                children: [
                                  for (final f in kEntryFees)
                                    _FilterPill(
                                      label: f,
                                      selected: _draft.entryFees.contains(f),
                                      onTap: () => _toggle(_draft.entryFees, f),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              const _SubTitle('רמת קושי'),
                              _chipWrap(
                                children: [
                                  for (final d in kDifficulties)
                                    _FilterPill(
                                      label: d,
                                      selected: _draft.difficulties.contains(d),
                                      onTap: () =>
                                          _toggle(_draft.difficulties, d),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              const _SubTitle('אופי המשתתפים'),
                              _chipWrap(
                                children: [
                                  for (final p in kParticipantTypes)
                                    _FilterPill(
                                      label: p,
                                      selected:
                                          _draft.participantTypes.contains(p),
                                      onTap: () =>
                                          _toggle(_draft.participantTypes, p),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),

                        // 5 ── אורך המסלול ──────────────────────
                        _SectionCard(
                          icon: Icons.straighten_rounded,
                          title: 'אורך המסלול',
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _SliderBlock(
                                title: 'מרחק מקסימלי',
                                unit: 'ק״מ',
                                max: kMaxDistance,
                                value: _draft.maxDistanceKm,
                                onChanged: (v) =>
                                    setState(() => _draft.maxDistanceKm = v),
                                onClear: () =>
                                    setState(() => _draft.maxDistanceKm = null),
                              ),
                              const SizedBox(height: 20),
                              _SliderBlock(
                                title: 'משך מקסימלי',
                                unit: 'שעות',
                                max: kMaxDuration,
                                value: _draft.maxDurationHours,
                                onChanged: (v) =>
                                    setState(() => _draft.maxDurationHours = v),
                                onClear: () => setState(
                                    () => _draft.maxDurationHours = null),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // ── Sticky bottom: the live-count CTA ───────────
                _buildFooter(count),
              ],
            );
          },
        ),
      ),
    );
  }

  // ── Header: title (right) + נקה הכל + close X (left) ────────────
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
      child: Row(
        children: [
          // Title — visual RIGHT
          const Expanded(
            child: Text(
              'סינון מותאם אישית',
              textAlign: TextAlign.right,
              style: TextStyle(
                fontFamily: AppTheme.font,
                fontSize: 21,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.5,
              ),
            ),
          ),
          // Clear-all link — only when something is selected
          if (!_draft.isEmpty) ...[
            GestureDetector(
              onTap: () => setState(() => _draft.clear()),
              child: const Text(
                'נקה הכל',
                style: TextStyle(
                  fontFamily: AppTheme.font,
                  fontSize: 13,
                  color: AppTheme.textMuted,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
            const SizedBox(width: 14),
          ],
          // Close — visual LEFT
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppTheme.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: const [
                  BoxShadow(
                      color: AppTheme.shadow,
                      blurRadius: 4,
                      offset: Offset(2, 1)),
                ],
              ),
              child: const Icon(Icons.close_rounded, size: 22),
            ),
          ),
        ],
      ),
    );
  }

  // ── Sticky footer with the live count button ────────────────────
  Widget _buildFooter(int? count) {
    final loading = count == null;
    final empty = count == 0;

    final String text;
    if (loading) {
      text = 'טוען...';
    } else if (empty) {
      text = 'אין מסלולים מתאימים 😕';
    } else if (_draft.isEmpty) {
      text = 'הצג את כל המסלולים ($count)';
    } else {
      text = 'הצג $count מסלולים';
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
      decoration: const BoxDecoration(
        color: AppTheme.bg,
        boxShadow: [
          BoxShadow(
              color: AppTheme.shadow, blurRadius: 8, offset: Offset(0, -2)),
        ],
      ),
      child: GestureDetector(
        onTap: (loading || empty) ? null : _finish,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          height: 54,
          decoration: BoxDecoration(
            color: (loading || empty)
                ? const Color(0xFFE0E0E0)
                : AppTheme.accentDark,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Center(
            child: Text(
              text,
              style: TextStyle(
                fontFamily: AppTheme.font,
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: (loading || empty) ? AppTheme.textMuted : AppTheme.black,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // A right-starting wrap of pills (RTL is inherited app-wide).
  Widget _chipWrap({required List<Widget> children}) {
    return Wrap(
      alignment: WrapAlignment.start,
      spacing: 8,
      runSpacing: 10,
      children: children,
    );
  }
}

// ─────────────────────────────────────────────────────────────────
//  SECTION CARD — a white rounded card with an icon + title header.
//  Groups each filter category so the long scroll reads cleanly.
// ─────────────────────────────────────────────────────────────────
class _SectionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget child;

  const _SectionCard({
    required this.icon,
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
              color: AppTheme.shadow, blurRadius: 4, offset: Offset(2, 1)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            // RTL: icon first = visual RIGHT, then the title.
            children: [
              Icon(icon, size: 19, color: AppTheme.tagText),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontFamily: AppTheme.font,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

// Small grey sub-section label inside אופי הטיול.
class _SubTitle extends StatelessWidget {
  final String text;
  const _SubTitle(this.text);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(
          text,
          textAlign: TextAlign.right,
          style: const TextStyle(
            fontFamily: AppTheme.font,
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppTheme.textMuted,
          ),
        ),
      );
}

// ─────────────────────────────────────────────────────────────────
//  FILTER PILL — a tappable chip with a clear selected state:
//  selected = accent fill + dark border + bold; unselected = light grey.
// ─────────────────────────────────────────────────────────────────
class _FilterPill extends StatelessWidget {
  final String label;
  final IconData? icon;
  final bool selected;
  final VoidCallback onTap;

  const _FilterPill({
    required this.label,
    this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? AppTheme.accent : const Color(0xFFF4F4F4),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppTheme.accentDark : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 16, color: AppTheme.tagText),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                fontFamily: AppTheme.font,
                fontSize: 14,
                fontWeight: selected ? FontWeight.w800 : FontWeight.w400,
                color: AppTheme.tagText,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
//  TYPE CARD — the big רטוב/יבש toggle. Tapping the selected one
//  again clears it (back to "either").
// ─────────────────────────────────────────────────────────────────
class _TypeCard extends StatelessWidget {
  final String emoji;
  final String label;
  final String hint;
  final bool selected;
  final VoidCallback onTap;

  const _TypeCard({
    required this.emoji,
    required this.label,
    required this.hint,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: selected ? AppTheme.accent : const Color(0xFFF4F4F4),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? AppTheme.accentDark : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 26)),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontFamily: AppTheme.font,
                fontSize: 15,
                fontWeight: selected ? FontWeight.w900 : FontWeight.w700,
                color: AppTheme.tagText,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              hint,
              style: const TextStyle(
                fontFamily: AppTheme.font,
                fontSize: 11.5,
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
//  SLIDER BLOCK — one labelled slider with a live value and a
//  "נקה / ללא הגבלה" link. Sliding to 0 = no limit (clears it).
// ─────────────────────────────────────────────────────────────────
class _SliderBlock extends StatelessWidget {
  final String title, unit;
  final double max;
  final double? value; // null = no limit set
  final ValueChanged<double> onChanged;
  final VoidCallback onClear;

  const _SliderBlock({
    required this.title,
    required this.unit,
    required this.max,
    required this.value,
    required this.onChanged,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final hasValue = value != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Title — visual RIGHT
            Text(
              title,
              style: const TextStyle(
                fontFamily: AppTheme.font,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
            // Value or "ללא הגבלה" — visual LEFT
            GestureDetector(
              onTap: hasValue ? onClear : null,
              child: Text(
                hasValue
                    ? 'עד ${value!.toStringAsFixed(0)} $unit ✕'
                    : 'ללא הגבלה',
                style: TextStyle(
                  fontFamily: AppTheme.font,
                  fontSize: 13,
                  fontWeight: hasValue ? FontWeight.w800 : FontWeight.w400,
                  color: hasValue ? AppTheme.tagText : AppTheme.textMuted,
                ),
              ),
            ),
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: AppTheme.accentDark,
            inactiveTrackColor: const Color(0xFFE5E5E5),
            thumbColor: const Color(0xFF1A2A3A),
            overlayColor: AppTheme.accent.withOpacity(0.3),
            trackHeight: 4,
          ),
          child: Slider(
            value: value ?? 0,
            min: 0,
            max: max,
            divisions: max.toInt(),
            onChanged: (v) {
              // A value of 0 means "no limit" → clear it.
              if (v == 0) {
                onClear();
              } else {
                onChanged(v);
              }
            },
          ),
        ),
      ],
    );
  }
}
