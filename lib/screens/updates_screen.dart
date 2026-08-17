import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme/app_theme.dart';
import '../services/updates_read_service.dart';

// ─────────────────────────────────────────────────────────────────
//  UPDATES SCREEN  (עדכונים)
//  A simple list of system / admin updates — trail closures, weather
//  alerts, app news. NOT chat or social activity; just broadcasts.
//
//  DATA (top-level Firestore collection, app-wide, editable from the
//  console):
//    updates/{updateId}
//      - title:     String   (bold line)
//      - body:      String   (subtitle line)
//      - type:      String   ('closure' | 'weather' | 'news')
//      - timestamp: Timestamp
//
//  READ STATE: tracked locally via UpdatesReadService. Unread = blue,
//  read = grey. Tapping a row marks it read. A "סמן הכל כנקרא" action
//  in the header clears everything at once.
//
//  EMBEDDED MODE: like SavedScreen, pass embedded: true when shown as
//  a tab inside HomeScreen (skips its own Scaffold so the floating nav
//  bar stays visible).
//
//  RTL: inherited app-wide. .start = visual RIGHT. Icons sit on the
//  visual LEFT (row uses spaceBetween: text right, icon left).
// ─────────────────────────────────────────────────────────────────

class UpdatesScreen extends StatelessWidget {
  final bool embedded;
  const UpdatesScreen({super.key, this.embedded = false});

  @override
  Widget build(BuildContext context) {
    final content = AnimatedBuilder(
      // Rebuild when read-state changes (blue→grey, badge, etc.)
      animation: UpdatesReadService.instance,
      builder: (context, _) {
        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('updates')
              .orderBy('timestamp', descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return const Center(child: Text('שגיאה בטעינת העדכונים'));
            }

            final docs = snapshot.data?.docs ?? [];
            final read = UpdatesReadService.instance;
            final allIds = docs.map((d) => d.id).toList();
            final unread = read.unreadCountAmong(allIds);

            return CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: _Header(
                    unreadCount: unread,
                    onMarkAll:
                        unread == 0 ? null : () => read.markAllRead(allIds),
                  ),
                ),
                if (docs.isEmpty)
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: _EmptyState(),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(0, 0, 0, 110),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, i) {
                          final doc = docs[i];
                          final data = doc.data() as Map<String, dynamic>;
                          return _UpdateRow(
                            id: doc.id,
                            title: data['title'] as String? ?? 'עדכון',
                            body: data['body'] as String? ?? '',
                            type: data['type'] as String? ?? '',
                            timestamp: data['timestamp'] as Timestamp?,
                            isRead: read.isRead(doc.id),
                            onTap: () => read.markRead(doc.id),
                          );
                        },
                        childCount: docs.length,
                      ),
                    ),
                  ),
              ],
            );
          },
        );
      },
    );

    if (embedded) {
      return SafeArea(bottom: false, child: content);
    }
    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: SafeArea(child: content),
    );
  }
}

// ── Header: title (right) + "mark all read" (left) ─────────────────
class _Header extends StatelessWidget {
  final int unreadCount;
  final VoidCallback? onMarkAll;
  const _Header({required this.unreadCount, required this.onMarkAll});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Title + unread subtitle — visual right in RTL.
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'עדכונים',
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
                unreadCount == 0 ? 'הכל מעודכן' : '$unreadCount עדכונים חדשים',
                textAlign: TextAlign.right,
                style: const TextStyle(
                  fontFamily: AppTheme.font,
                  fontSize: 14,
                  color: AppTheme.textMuted,
                ),
              ),
            ],
          ),

          // "Mark all read" — visual left. Hidden when nothing unread.
          if (onMarkAll != null)
            GestureDetector(
              onTap: onMarkAll,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: AppTheme.tagGreen,
                  borderRadius: BorderRadius.circular(AppTheme.radiusPill),
                ),
                child: const Text(
                  'סמן הכל כנקרא',
                  style: TextStyle(
                    fontFamily: AppTheme.font,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.tagText,
                  ),
                ),
              ),
            )
          else
            const SizedBox(),
        ],
      ),
    );
  }
}

// ── A single update row ────────────────────────────────────────────
class _UpdateRow extends StatelessWidget {
  final String id, title, body, type;
  final Timestamp? timestamp;
  final bool isRead;
  final VoidCallback onTap;

  const _UpdateRow({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.timestamp,
    required this.isRead,
    required this.onTap,
  });

  // Blue when unread, muted grey when read.
  static const _unreadColor = Color(0xFF2F7DA8);

  @override
  Widget build(BuildContext context) {
    final titleColor = isRead ? AppTheme.textMuted : _unreadColor;
    final bodyColor =
        isRead ? const Color(0xFFB0B0B0) : _unreadColor.withOpacity(0.85);
    final iconColor = isRead ? AppTheme.textMuted : _unreadColor;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        decoration: const BoxDecoration(
          border: Border(
            bottom: BorderSide(color: AppTheme.divider, width: 1),
          ),
        ),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon — visual left
            Icon(_iconFor(type), size: 26, color: iconColor),
            const SizedBox(width: 14),
            // Text block — fills, aligned right
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontFamily: AppTheme.font,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: titleColor,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    body,
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontFamily: AppTheme.font,
                      fontSize: 14,
                      height: 1.4,
                      color: bodyColor,
                    ),
                  ),
                  if (timestamp != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      _relativeTime(timestamp!.toDate()),
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        fontFamily: AppTheme.font,
                        fontSize: 12,
                        color: Color(0xFFC0C0C0),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Pick an icon from the update type. Unknown → neutral bell, so a
  // malformed doc never breaks the row.
  IconData _iconFor(String type) {
    switch (type) {
      case 'closure':
        return Icons.warning_amber_rounded;
      case 'weather':
        return Icons.cloud_outlined;
      case 'news':
        return Icons.campaign_outlined;
      default:
        return Icons.notifications_none_rounded;
    }
  }

  // Hebrew relative time: "עכשיו" / "לפני X דקות" / "אתמול" / date.
  String _relativeTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);

    if (diff.inMinutes < 1) return 'עכשיו';
    if (diff.inMinutes < 60) return 'לפני ${diff.inMinutes} דקות';
    if (diff.inHours < 24) {
      final h = diff.inHours;
      return h == 1 ? 'לפני שעה' : 'לפני $h שעות';
    }
    if (diff.inDays == 1) return 'אתמול';
    if (diff.inDays < 7) return 'לפני ${diff.inDays} ימים';

    // Older → plain date dd.mm.yyyy
    final d = dt.day.toString().padLeft(2, '0');
    final m = dt.month.toString().padLeft(2, '0');
    return '$d.$m.${dt.year}';
  }
}

// ── Empty state — no updates at all ────────────────────────────────
class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.notifications_none_rounded,
                size: 60, color: Color(0xFFD0D0D0)),
            SizedBox(height: 16),
            Text(
              'אין עדכונים חדשים',
              style: TextStyle(
                  fontFamily: AppTheme.font,
                  fontSize: 17,
                  fontWeight: FontWeight.w700),
            ),
            SizedBox(height: 6),
            Text(
              'כאן יופיעו עדכונים על מסלולים, מזג אוויר וחדשות',
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
