import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/trail.dart';
import '../services/saved_trails_service.dart';
import 'tag_badge.dart';
import 'trail_image.dart';

// ─────────────────────────────────────────────────────────────────
//  TRAIL CARD
//  The scrollable card shown in the home screen trail rows.
//  Displays: image (via TrailImage: network → local asset webp/png/
//  jpg → gradient), bookmark, tags, distance, duration, name, desc.
//
//  RTL is inherited from the app root (main.dart). In RTL, the
//  "start" side is the RIGHT — so to hug content to the right we use
//  CrossAxisAlignment.start (NOT .end, which is the left in RTL).
//
//  SAVE/BOOKMARK:
//  The bookmark button sits top-LEFT of the image (visual left in
//  RTL, matching the Figma). It listens to SavedTrailsService via an
//  AnimatedBuilder, so it fills in the moment the trail is saved and
//  empties when unsaved — anywhere in the app, instantly.
//
//  Usage:
//    TrailCard(
//      trail: trail,
//      width: 260,
//      onTap: (trail) => navigateToProfile(trail),
//    )
// ─────────────────────────────────────────────────────────────────

class TrailCard extends StatelessWidget {
  final TrailData trail;
  final double width;
  final void Function(TrailData) onTap;

  const TrailCard({
    super.key,
    required this.trail,
    required this.width,
    required this.onTap,
  });

  // Placeholder gradients — used when no image is available at all
  static const _gradients = [
    [Color(0xFF4A8A6A), Color(0xFF2A5A4A)],
    [Color(0xFF5A9AAA), Color(0xFF2A6A7A)],
    [Color(0xFF8A7A5A), Color(0xFF5A5030)],
    [Color(0xFF6A7A9A), Color(0xFF3A4A6A)],
  ];

  @override
  Widget build(BuildContext context) {
    // Pick a gradient based on trail name so each trail
    // always gets the same color (not random each rebuild)
    final grad = _gradients[trail.name.hashCode.abs() % _gradients.length];

    return GestureDetector(
      onTap: () => onTap(trail),
      child: Container(
        width: width,
        decoration: BoxDecoration(
          color: AppTheme.white,
          borderRadius: BorderRadius.circular(AppTheme.radiusCard),
          boxShadow: AppTheme.cardShadow,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          // RTL: .start = RIGHT side. This hugs content to the right.
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Image section ───────────────────────────────────
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(20),
                    bottom: Radius.circular(14),
                  ),
                  // TrailImage tries: Firestore URL → assets/images/
                  // N.webp → N.png → N.jpg → gradient.
                  child: SizedBox(
                    width: width,
                    height: 110,
                    child: TrailImage(
                      trailId: trail.firestoreId,
                      imageUrl: trail.imageUrl,
                      fit: BoxFit.cover,
                      fallback: _buildGradient(width, grad),
                    ),
                  ),
                ),

                // Bookmark button — top LEFT of the image (visual left
                // in RTL). Tapping toggles saved state via the service.
                Positioned(
                  top: 8,
                  left: 8,
                  child: _BookmarkButton(trailId: trail.firestoreId),
                ),

                // Tags overlay — bottom right of the image.
                // In RTL, "right: 8" still means the visual right edge,
                // so this stays correct.
                Positioned(
                  bottom: 6,
                  right: 8,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: trail.tags
                        .take(3)
                        .map((t) => Padding(
                              padding: const EdgeInsets.only(left: 4),
                              child: TagBadge(t),
                            ))
                        .toList(),
                  ),
                ),
              ],
            ),

            // ── Card body ───────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 4, 12, 6),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                // RTL: .start = RIGHT side.
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Distance + duration row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Duration — visual left side
                      Row(children: [
                        const Icon(Icons.access_time_rounded,
                            size: 13, color: Color(0xFF555555)),
                        const SizedBox(width: 3),
                        Text(
                          trail.duration,
                          style: const TextStyle(
                            fontFamily: AppTheme.font,
                            fontSize: 11,
                            color: Color(0xFF555555),
                          ),
                        ),
                      ]),
                      // Distance badge — visual right side
                      TagBadge('${trail.distanceKm} ק״מ'),
                    ],
                  ),
                  const SizedBox(height: 3),

                  // Trail name
                  Text(
                    trail.name,
                    textAlign: TextAlign.right,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: AppTheme.font,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),

                  // Short description
                  Text(
                    trail.description,
                    textAlign: TextAlign.right,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: AppTheme.font,
                      fontSize: 12,
                      height: 1.25,
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

  Widget _buildGradient(double w, List<Color> colors) => Container(
        width: w,
        height: 110,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: colors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
      );
}

// ─────────────────────────────────────────────────────────────────
//  BOOKMARK BUTTON
//  A small white rounded button holding a bookmark icon. Listens to
//  SavedTrailsService so it always reflects the live saved state and
//  updates instantly when tapped. Reused on the result cards and the
//  שמורים screen so every bookmark in the app behaves identically.
// ─────────────────────────────────────────────────────────────────
class _BookmarkButton extends StatelessWidget {
  final String trailId;
  const _BookmarkButton({required this.trailId});

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
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppTheme.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: AppTheme.cardShadow,
            ),
            child: Icon(
              isSaved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
              size: 18,
              color: isSaved ? AppTheme.accentDark : AppTheme.black,
            ),
          ),
        );
      },
    );
  }
}
