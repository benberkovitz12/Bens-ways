import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

// ─────────────────────────────────────────────────────────────────
//  WIZARD WIDGETS
//  Shared building blocks for the 4-step filter wizard so every step
//  looks identical: the top header (step counter + ×), section titles,
//  and the rounded pill buttons used for choices.
//
//  These are kept here (not inside each step) so Steps 1–4 reuse the
//  exact same look without copy-pasting.
// ─────────────────────────────────────────────────────────────────

// ── Top header: × (close) on left, "N/4 title" centered, optional
//    forward arrow on the visual-left for "skip to next". ───────────
class WizardHeader extends StatelessWidget {
  final int step; // 1..4
  final String title;
  final VoidCallback onClose;
  final VoidCallback? onNext; // null hides the arrow (e.g. last step)

  const WizardHeader({
    super.key,
    required this.step,
    required this.title,
    required this.onClose,
    this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
      child: Row(
        children: [
          // Close (×) — visual left
          GestureDetector(
            onTap: onClose,
            child: const Icon(Icons.close_rounded, size: 28),
          ),
          // Title block — centered, fills the middle
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: AppTheme.font,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '$step/4',
                  style: const TextStyle(
                    fontFamily: AppTheme.font,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          // Forward arrow (skip) — visual left side of header. In RTL a
          // ">" points to the next step. Hidden when onNext is null.
          onNext != null
              ? GestureDetector(
                  onTap: onNext,
                  child: const Icon(Icons.chevron_left_rounded, size: 30),
                )
              : const SizedBox(width: 30),
        ],
      ),
    );
  }
}

// ── A right-aligned section title (e.g. "סוג המסלול") ──────────────
class WizardSectionTitle extends StatelessWidget {
  final String text;
  const WizardSectionTitle(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(right: 4, bottom: 12, top: 4),
      child: Text(
        text,
        textAlign: TextAlign.right,
        style: const TextStyle(
          fontFamily: AppTheme.font,
          fontSize: 16,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

// ── A rounded pill choice button (selected = blue, idle = white). ──
//    Used for regions, fee, difficulty, etc. Optional icon above text.
class WizardPill extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon; // optional icon shown above the label
  final bool dimmed; // for "not yet supported" decorative options

  const WizardPill({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
    this.dimmed = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: dimmed ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: EdgeInsets.symmetric(
            horizontal: 18, vertical: icon != null ? 14 : 16),
        decoration: BoxDecoration(
          color: dimmed
              ? const Color(0xFFF5F5F5)
              : selected
                  ? AppTheme.accent
                  : AppTheme.white,
          borderRadius: BorderRadius.circular(AppTheme.radiusPill),
          boxShadow: dimmed ? [] : AppTheme.cardShadow,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon,
                  size: 26,
                  color: dimmed ? const Color(0xFFC0C0C0) : AppTheme.black),
              const SizedBox(height: 6),
            ],
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: AppTheme.font,
                fontSize: 14,
                color: dimmed ? const Color(0xFFC0C0C0) : AppTheme.black,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── The bottom area: a "המשך ללא בחירה" skip link + a big CTA. ─────
class WizardFooter extends StatelessWidget {
  final String ctaText;
  final VoidCallback onCta;
  final VoidCallback onSkip;

  const WizardFooter({
    super.key,
    required this.ctaText,
    required this.onCta,
    required this.onSkip,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: onSkip,
            child: const Text(
              'המשך ללא בחירה',
              style: TextStyle(
                fontFamily: AppTheme.font,
                fontSize: 14,
                decoration: TextDecoration.underline,
                color: AppTheme.textMuted,
              ),
            ),
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: onCta,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: const Color(0xFF5A8CA0),
                borderRadius: BorderRadius.circular(AppTheme.radiusPill),
                boxShadow: AppTheme.ctaShadow,
              ),
              child: Text(
                ctaText,
                style: const TextStyle(
                  fontFamily: AppTheme.font,
                  fontSize: 16,
                  color: AppTheme.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
