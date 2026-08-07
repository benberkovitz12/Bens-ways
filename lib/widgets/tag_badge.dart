import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

// ─────────────────────────────────────────────────────────────────
//  TAG BADGE
//  The small green pill labels you see on trail cards.
//  Examples: "קל", "רטוב", "למשפחות", "2.5 ק״מ"
//
//  Usage:
//    TagBadge('קל')
//    TagBadge('2.5 ק״מ')
// ─────────────────────────────────────────────────────────────────

class TagBadge extends StatelessWidget {
  final String label;

  const TagBadge(this.label, {super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: AppTheme.tagGreen.withOpacity(0.92),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: AppTheme.tagStyle,
      ),
    );
  }
}
