import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme/app_theme.dart';
import 'share_memory_screen.dart';

// ─────────────────────────────────────────────────────────────────
//  MEMORY WALL SCREEN  (קיר הזיכרונות)
//  The living-memorial screen: shows EVERY memory people have shared
//  about Ben, newest first. Reached from the tribute card on home.
//
//  NO APPROVAL STEP (school-project mode): whatever ShareMemoryScreen
//  writes to the memories collection appears here immediately. If
//  moderation is ever wanted, filter the docs on an approved==true
//  field where marked below.
//
//  READING IS DEFENSIVE: the memory text is read from 'text' with
//  fallbacks to 'memory' / 'message', and the author from 'userName'
//  with fallbacks to 'name' — so it works with whatever field names
//  ShareMemoryScreen writes.
//
//  RTL inherited app-wide. Row rule: first child = visual RIGHT.
//  Directional icons pinned LTR (the mirroring rule).
// ─────────────────────────────────────────────────────────────────

class MemoryWallScreen extends StatelessWidget {
  const MemoryWallScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Header: title (right) + back (left) ────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'קיר הזיכרונות 💚',
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontFamily: AppTheme.font,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppTheme.white,
                        shape: BoxShape.circle,
                        boxShadow: AppTheme.cardShadow,
                      ),
                      // Back in RTL points RIGHT — pinned LTR so the
                      // auto-mirroring can't flip it.
                      child: const Icon(
                        Icons.arrow_forward_rounded,
                        size: 20,
                        color: AppTheme.black,
                        textDirection: TextDirection.ltr,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'זיכרונות, סיפורים ומילים טובות מהאנשים שהכירו את בן',
                textAlign: TextAlign.right,
                style: TextStyle(
                  fontFamily: AppTheme.font,
                  fontSize: 13.5,
                  color: AppTheme.textMuted,
                ),
              ),
            ),
            const SizedBox(height: 14),

            // ── The wall ───────────────────────────────────────
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('memories')
                    .orderBy('timestamp', descending: true)
                    .snapshots(),
                builder: (context, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snap.hasError) {
                    return const Center(
                      child: Text(
                        'שגיאה בטעינת הזיכרונות',
                        style: TextStyle(fontFamily: AppTheme.font),
                      ),
                    );
                  }

                  // Every shared memory goes straight on the wall —
                  // no approval step (school-project mode 🎓). If the
                  // עמותה ever wants moderation, filter here on an
                  // approved==true field.
                  final docs = snap.data?.docs ?? [];

                  if (docs.isEmpty) {
                    return _buildEmptyState(context);
                  }

                  return ListView.separated(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 30),
                    itemCount: docs.length + 1, // +1 for the share CTA
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (_, i) {
                      // First item: the "share yours" invitation.
                      if (i == 0) return _ShareCta(compact: true);
                      final m = docs[i - 1].data() as Map<String, dynamic>;
                      return _MemoryCard(
                        name: _readName(m),
                        text: _readText(m),
                        dateStr: _formatDate(m['timestamp']),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Defensive field reading — works with whatever ShareMemoryScreen
  // writes today or tomorrow.
  static String _readName(Map<String, dynamic> m) {
    for (final key in ['userName', 'name', 'author']) {
      final v = m[key];
      if (v is String && v.trim().isNotEmpty) return v.trim();
    }
    return 'אנונימי';
  }

  static String _readText(Map<String, dynamic> m) {
    for (final key in ['text', 'memory', 'message', 'body']) {
      final v = m[key];
      if (v is String && v.trim().isNotEmpty) return v.trim();
    }
    return '';
  }

  static String _formatDate(dynamic ts) {
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

  // Empty wall → a warm invitation instead of a blank screen.
  Widget _buildEmptyState(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 30, 20, 30),
      child: Column(
        children: [
          const Icon(Icons.favorite_rounded,
              size: 52, color: Color(0xFFD9C2C2)),
          const SizedBox(height: 14),
          const Text(
            'הקיר עדיין ריק',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: AppTheme.font,
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'היו הראשונים לשתף זיכרון או מילה טובה על בן',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: AppTheme.font,
              fontSize: 14,
              color: AppTheme.textMuted,
            ),
          ),
          const SizedBox(height: 20),
          _ShareCta(compact: false),
        ],
      ),
    );
  }
}

// ── The "share yours" invitation card ──────────────────────────────
class _ShareCta extends StatelessWidget {
  final bool compact;
  const _ShareCta({required this.compact});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const ShareMemoryScreen()),
      ),
      child: Container(
        padding:
            EdgeInsets.symmetric(horizontal: 18, vertical: compact ? 14 : 16),
        decoration: BoxDecoration(
          color: AppTheme.accent.withOpacity(0.4),
          borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        ),
        child: Row(
          // RTL: first child = visual RIGHT, last child = visual LEFT.
          children: [
            const Icon(Icons.favorite_outline_rounded,
                size: 22, color: AppTheme.tagText),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'גם לכם יש זיכרון? שתפו אותו כאן',
                textAlign: TextAlign.right,
                style: TextStyle(
                  fontFamily: AppTheme.font,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.tagText,
                ),
              ),
            ),
            // Chevron — visual LEFT, pinned so it points left.
            const Icon(
              Icons.chevron_left_rounded,
              size: 22,
              color: AppTheme.tagText,
              textDirection: TextDirection.ltr,
            ),
          ],
        ),
      ),
    );
  }
}

// ── One memory on the wall ─────────────────────────────────────────
class _MemoryCard extends StatelessWidget {
  final String name, text, dateStr;
  const _MemoryCard({
    required this.name,
    required this.text,
    required this.dateStr,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            // RTL: first child = visual RIGHT, last child = visual LEFT.
            children: [
              const Icon(Icons.favorite_rounded,
                  size: 16, color: Color(0xFF2A6A3A)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  name,
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    fontFamily: AppTheme.font,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              if (dateStr.isNotEmpty)
                Text(
                  dateStr,
                  style: const TextStyle(
                    fontFamily: AppTheme.font,
                    fontSize: 12,
                    color: Color(0xFFC0C0C0),
                  ),
                ),
            ],
          ),
          if (text.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              text,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontFamily: AppTheme.font,
                fontSize: 14.5,
                height: 1.6,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
