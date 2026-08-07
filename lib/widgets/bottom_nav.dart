import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

// ─────────────────────────────────────────────────────────────────
//  BOTTOM NAV BAR
//  The floating pill-shaped navigation bar. 5 tabs, laid out by index
//  (RTL flips the visual order automatically):
//
//    index 0 = פרופיל
//    index 1 = עדכונים   (system updates — can show an unread badge)
//    index 2 = מותאם
//    index 3 = שמורים
//    index 4 = בית   (gets the signature circle treatment)
//
//  The selected tab is clearly marked: its icon + label turn dark AND
//  sit on a soft highlight pill, so the user always sees where they
//  are. בית additionally keeps its dark circle when active.
//
//  UNREAD BADGE: pass badgeCounts {index: count}. Any index with a
//  count > 0 shows a small blue bubble on its icon. Used by עדכונים.
//
//  Usage:
//    BottomNav(
//      selectedIndex: _navIndex,
//      onTap: (i) => ...,
//      badgeCounts: {1: unreadUpdates},
//    )
// ─────────────────────────────────────────────────────────────────

class BottomNav extends StatelessWidget {
  final int selectedIndex;
  final void Function(int) onTap;
  final Map<int, int> badgeCounts;

  const BottomNav({
    super.key,
    required this.selectedIndex,
    required this.onTap,
    this.badgeCounts = const {},
  });

  static const _items = [
    _NavItem(icon: Icons.person_outline_rounded, label: 'פרופיל'),
    _NavItem(icon: Icons.notifications_none_rounded, label: 'עדכונים'),
    _NavItem(icon: Icons.tune_rounded, label: 'מותאם'),
    _NavItem(icon: Icons.bookmark_border_rounded, label: 'שמורים'),
    _NavItem(icon: Icons.home_outlined, label: 'בית', isHome: true),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 67,
      decoration: BoxDecoration(
        color: AppTheme.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(60),
        boxShadow: AppTheme.navShadow,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(_items.length, (i) {
          final item = _items[i];
          final active = i == selectedIndex;
          final badge = badgeCounts[i] ?? 0;
          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => onTap(i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOut,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                // Soft highlight pill behind the active tab.
                color: active ? AppTheme.tagGreen : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Icon (with optional unread badge on top).
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      // Home icon gets a circle background when active
                      item.isHome
                          ? Container(
                              width: 30,
                              height: 30,
                              decoration: BoxDecoration(
                                color: active
                                    ? AppTheme.accentDark
                                    : Colors.transparent,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(item.icon,
                                  size: 19,
                                  color: active
                                      ? AppTheme.black
                                      : AppTheme.textMuted),
                            )
                          : Icon(item.icon,
                              size: 22,
                              color:
                                  active ? AppTheme.black : AppTheme.textMuted),
                      // Unread badge — visual left-top corner.
                      if (badge > 0)
                        Positioned(
                          left: -6,
                          top: -4,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 5, vertical: 1),
                            constraints: const BoxConstraints(minWidth: 16),
                            decoration: BoxDecoration(
                              color: const Color(0xFF2F7DA8),
                              borderRadius: BorderRadius.circular(10),
                              border:
                                  Border.all(color: AppTheme.white, width: 1.5),
                            ),
                            child: Text(
                              badge > 9 ? '9+' : '$badge',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontFamily: AppTheme.font,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                height: 1.2,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.label,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: AppTheme.font,
                      fontSize: 12,
                      fontWeight: active ? FontWeight.w700 : FontWeight.w400,
                      color: active ? AppTheme.black : AppTheme.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}

// Internal data class — not exported, only used by BottomNav
class _NavItem {
  final IconData icon;
  final String label;
  final bool isHome;
  const _NavItem({
    required this.icon,
    required this.label,
    this.isHome = false,
  });
}
