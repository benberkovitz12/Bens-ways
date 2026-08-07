import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────────
//  TRAIL IMAGE
//  One shared widget for showing a trail's picture everywhere in the
//  app, with a graceful three-step fallback chain:
//
//    1. imageUrl (Cloudinary/network) — if the Firestore field is set
//    2. Local asset  assets/images/N.png  (then N.jpg)
//       where N is the trail number: trail_7 → 7.png
//    3. The provided fallback widget (usually a gradient)
//
//  So: put an image file named after the trail number into
//  assets/images/ and it just appears — no Firestore edit needed.
//  A Cloudinary URL in Firestore always wins if present.
//
//  SETUP (one-time, in pubspec.yaml):
//    flutter:
//      assets:
//        - assets/images/
//  And create the folders at the PROJECT ROOT (next to lib/, not
//  inside it):  assets/images/
// ─────────────────────────────────────────────────────────────────

class TrailImage extends StatelessWidget {
  final String trailId;
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget fallback;

  const TrailImage({
    super.key,
    required this.trailId,
    required this.imageUrl,
    required this.fallback,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
  });

  // "trail_7" → "7"
  String get _n => trailId.replaceAll('trail_', '');

  @override
  Widget build(BuildContext context) {
    // Step 1: network URL from Firestore, if set.
    if (imageUrl.isNotEmpty) {
      return Image.network(
        imageUrl,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (_, __, ___) => _assetWebp(),
      );
    }
    return _assetWebp();
  }

  // Step 2a: assets/images/N.webp (the preferred format)
  Widget _assetWebp() => Image.asset(
        'assets/images/$_n.webp',
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (_, __, ___) => _assetPng(),
      );

  // Step 2b: assets/images/N.png
  Widget _assetPng() => Image.asset(
        'assets/images/$_n.png',
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (_, __, ___) => _assetJpg(),
      );

  // Step 2c: assets/images/N.jpg (in case a download saved as jpg)
  Widget _assetJpg() => Image.asset(
        'assets/images/$_n.jpg',
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (_, __, ___) => fallback,
      );
}
