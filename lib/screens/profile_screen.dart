import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_theme.dart';
import '../services/auth_service.dart';
import '../services/saved_trails_service.dart';
import '../services/completed_trails_service.dart';
import 'share_memory_screen.dart';

// ─────────────────────────────────────────────────────────────────
//  PROFILE SCREEN  (פרופיל)
//  Minimal account hub:
//    - identity block: initial-avatar + name + email (from auth)
//    - one real stat: saved-trails count (live, from SavedTrailsService)
//    - three WIRED settings rows:
//        עדכונים        → switches to the עדכונים tab in-place
//        אודות העמותה   → bottom sheet, console-editable (content/about)
//        עזרה וצור קשר  → bottom sheet with tappable contact rows,
//                          console-editable (content/contact)
//    - "בא לכם לשתף משהו?" → ShareMemoryScreen
//    - sign out (red, with a confirm dialog)
//
//  EMBEDDED MODE: like Saved/Updates, pass embedded: true when shown as
//  a tab inside HomeScreen so the floating nav bar stays visible.
//
//  ⚠️ RTL ICON-MIRRORING RULE (new to the rulebook!):
//  Material auto-mirrors directional icons (chevrons, arrows) under
//  app-wide RTL — so Icons.chevron_left RENDERS pointing right. To draw
//  a chevron literally, force textDirection: TextDirection.ltr on the
//  Icon itself. All chevrons here do this via _RtlChevron.
//
//  RTL inherited app-wide. .start = visual RIGHT.
// ─────────────────────────────────────────────────────────────────

class ProfileScreen extends StatelessWidget {
  final bool embedded;
  // Called when the user taps the saved-trails stat. Home passes this
  // so the profile can switch to the שמורים tab in-place (instead of
  // pushing a new screen and losing the nav bar).
  final VoidCallback? onOpenSaved;
  // Same idea for the עדכונים settings row → the עדכונים tab.
  final VoidCallback? onOpenUpdates;

  const ProfileScreen({
    super.key,
    this.embedded = false,
    this.onOpenSaved,
    this.onOpenUpdates,
  });

  @override
  Widget build(BuildContext context) {
    final content = SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Title ───────────────────────────────────────────
          const Text(
            'הפרופיל שלי',
            textAlign: TextAlign.right,
            style: TextStyle(
              fontFamily: AppTheme.font,
              fontSize: 26,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 20),

          // ── Identity block ──────────────────────────────────
          const _IdentityBlock(),
          const SizedBox(height: 20),

          // ── Stats row: saved (taps to שמורים) + completed ───
          _StatsRow(onOpenSaved: onOpenSaved),
          const SizedBox(height: 24),

          // ── Settings rows (all wired) ───────────────────────
          _SettingsRow(
            icon: Icons.notifications_none_rounded,
            label: 'עדכונים',
            onTap: onOpenUpdates ?? () {},
          ),
          _SettingsRow(
            icon: Icons.info_outline_rounded,
            label: 'אודות העמותה',
            onTap: () => _openAbout(context),
          ),
          _SettingsRow(
            icon: Icons.help_outline_rounded,
            label: 'עזרה וצור קשר',
            onTap: () => _openContact(context),
          ),

          const SizedBox(height: 12),

          // ── בא לכם לשתף משהו? ───────────────────────────────
          _ShareMemoryRow(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ShareMemoryScreen()),
            ),
          ),

          const SizedBox(height: 24),

          // ── Sign out ────────────────────────────────────────
          _SignOutButton(onTap: () => _confirmSignOut(context)),
        ],
      ),
    );

    if (embedded) {
      return SafeArea(bottom: false, child: content);
    }
    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: SafeArea(child: content),
    );
  }

  // ── אודות העמותה — bottom sheet ─────────────────────────────────
  //  The עמותה story, with a button to Ben's memorial page (יזכור).
  static const String _izkorUrl =
      'https://www.izkor.gov.il/%D7%91%D7%9F%20%D7%A9%D7%9C%D7%99/en_861ea833663d0be567e2145f59f619c1';

  void _openAbout(BuildContext context) {
    _showSheet(
      context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'אודות העמותה',
            textAlign: TextAlign.right,
            style: TextStyle(
              fontFamily: AppTheme.font,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'עמותת בן הוקמה במטרה להמשיך את דרכו ואת הערכים שלאורם חי.\n'
            'לאורך השנה העמותה מארגנת אירועים לזכרו ולהנצחתו של בן ובכך שומרת על מורשת חייו.\n'
            'פרטים נוספים באתר העמותה',
            textAlign: TextAlign.right,
            style: TextStyle(
              fontFamily: AppTheme.font,
              fontSize: 15,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 20),
          // Button → Ben's memorial page on the יזכור website.
          GestureDetector(
            onTap: () => _launch(_izkorUrl),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: AppTheme.accentDark,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.local_florist_rounded,
                      size: 20, color: AppTheme.black),
                  SizedBox(width: 8),
                  Text(
                    'לדף ההנצחה של בן באתר יזכור',
                    style: TextStyle(
                      fontFamily: AppTheme.font,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.black,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── עזרה וצור קשר — bottom sheet with tappable rows ─────────────
  //  Reads content/contact:  email, phone, whatsapp (all Strings, all
  //  optional — empty/missing fields simply don't show a row).
  //  whatsapp should be digits in international format, e.g. 972501234567.
  void _openContact(BuildContext context) {
    _showSheet(
      context,
      child: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('content')
            .doc('contact')
            .snapshots(),
        builder: (context, snap) {
          final d = snap.data?.data() as Map<String, dynamic>?;
          final email = (d?['email'] as String? ?? '').trim();
          final phone = (d?['phone'] as String? ?? '').trim();
          final whatsapp = (d?['whatsapp'] as String? ?? '').trim();
          final hasAny =
              email.isNotEmpty || phone.isNotEmpty || whatsapp.isNotEmpty;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'עזרה וצור קשר',
                textAlign: TextAlign.right,
                style: TextStyle(
                  fontFamily: AppTheme.font,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'נשמח לשמוע מכם — בכל שאלה, רעיון או בעיה',
                textAlign: TextAlign.right,
                style: TextStyle(
                  fontFamily: AppTheme.font,
                  fontSize: 13,
                  color: AppTheme.textMuted,
                ),
              ),
              const SizedBox(height: 16),
              if (!hasAny)
                const Text(
                  'פרטי הקשר יתווספו בקרוב 💚',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontFamily: AppTheme.font,
                    fontSize: 15,
                    height: 1.6,
                  ),
                ),
              if (email.isNotEmpty)
                _ContactRow(
                  icon: Icons.mail_outline_rounded,
                  label: 'אימייל',
                  value: email,
                  onTap: () => _launch('mailto:$email'),
                ),
              if (phone.isNotEmpty)
                _ContactRow(
                  icon: Icons.phone_outlined,
                  label: 'טלפון',
                  value: phone,
                  onTap: () => _launch('tel:$phone'),
                ),
              if (whatsapp.isNotEmpty)
                _ContactRow(
                  icon: Icons.chat_outlined,
                  label: 'וואטסאפ',
                  value: 'שלחו לנו הודעה',
                  onTap: () => _launch('https://wa.me/$whatsapp'),
                ),
            ],
          );
        },
      ),
    );
  }

  // Open a URL outside the app (mail app, dialer, WhatsApp).
  Future<void> _launch(String url) async {
    final uri = Uri.parse(url);
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      // Silently ignore — e.g. no mail app on the device.
    }
  }

  // Shared bottom-sheet shell: rounded top, drag handle, padding.
  void _showSheet(BuildContext context, {required Widget child}) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.bg,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag handle
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 18),
                decoration: BoxDecoration(
                  color: const Color(0xFFD5D5D5),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              child,
            ],
          ),
        ),
      ),
    );
  }

  // ── Confirm dialog before signing out ──────────────────────────
  void _confirmSignOut(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: AppTheme.bg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'התנתקות',
          textAlign: TextAlign.right,
          style: TextStyle(
            fontFamily: AppTheme.font,
            fontSize: 18,
            fontWeight: FontWeight.w900,
          ),
        ),
        content: const Text(
          'האם אתם בטוחים שברצונכם להתנתק?',
          textAlign: TextAlign.right,
          style: TextStyle(fontFamily: AppTheme.font, fontSize: 15),
        ),
        actionsAlignment: MainAxisAlignment.spaceBetween,
        actions: [
          // Confirm — sign out
          GestureDetector(
            onTap: () async {
              Navigator.pop(dialogCtx); // close dialog first
              await AuthService.instance.signOut();
              // AuthGate reacts and shows the login screen automatically.
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFC0392B),
                borderRadius: BorderRadius.circular(AppTheme.radiusPill),
              ),
              child: const Text(
                'התנתקות',
                style: TextStyle(
                  fontFamily: AppTheme.font,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          // Cancel
          GestureDetector(
            onTap: () => Navigator.pop(dialogCtx),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFF0F0F0),
                borderRadius: BorderRadius.circular(AppTheme.radiusPill),
              ),
              child: const Text(
                'ביטול',
                style: TextStyle(
                  fontFamily: AppTheme.font,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.tagText,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
//  RTL CHEVRON — a chevron that ACTUALLY points left.
//  Material mirrors chevron icons under RTL, so we pin the icon's own
//  textDirection to LTR to draw it literally. In RTL, "forward" = left.
// ─────────────────────────────────────────────────────────────────
class _RtlChevron extends StatelessWidget {
  final Color color;
  const _RtlChevron({this.color = AppTheme.textMuted});

  @override
  Widget build(BuildContext context) => Icon(
        Icons.chevron_left_rounded,
        size: 22,
        color: color,
        textDirection: TextDirection.ltr, // ← disables RTL mirroring
      );
}

// ── Identity: initial-avatar + name + email ────────────────────────
class _IdentityBlock extends StatelessWidget {
  const _IdentityBlock();

  @override
  Widget build(BuildContext context) {
    final user = AuthService.instance.currentUser;
    final name = (user?.displayName?.trim().isNotEmpty == true)
        ? user!.displayName!.trim()
        : 'מטייל';
    final email = user?.email ?? '';
    final initial = name.isNotEmpty ? name.characters.first : '🙂';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Row(
        children: [
          // Text — visual right (so put it first in the row, fills space)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    fontFamily: AppTheme.font,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                if (email.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    email,
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      fontFamily: AppTheme.font,
                      fontSize: 14,
                      color: AppTheme.textMuted,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 14),
          // Avatar — visual left
          Container(
            width: 64,
            height: 64,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: AppTheme.accent,
              shape: BoxShape.circle,
            ),
            child: Text(
              initial,
              style: const TextStyle(
                fontFamily: AppTheme.font,
                fontSize: 28,
                fontWeight: FontWeight.w900,
                color: AppTheme.black,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Stats row: two live cards side by side ─────────────────────────
//  Right: מסלולים שמורים (SavedTrailsService, taps to the שמורים tab)
//  Left:  הלכת בדרכי בן (CompletedTrailsService — trails walked
//         end-to-end in live mode)
class _StatsRow extends StatelessWidget {
  final VoidCallback? onOpenSaved;
  const _StatsRow({this.onOpenSaved});

  @override
  Widget build(BuildContext context) {
    return Row(
      // RTL: first child = visual RIGHT, last child = visual LEFT.
      children: [
        Expanded(
          child: AnimatedBuilder(
            animation: SavedTrailsService.instance,
            builder: (context, _) => _MiniStatCard(
              icon: Icons.bookmark_rounded,
              count: SavedTrailsService.instance.count,
              label: 'מסלולים שמורים',
              onTap: onOpenSaved,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: AnimatedBuilder(
            animation: CompletedTrailsService.instance,
            builder: (context, _) => _MiniStatCard(
              icon: Icons.hiking_rounded,
              count: CompletedTrailsService.instance.count,
              label: 'הלכת בדרכי בן',
            ),
          ),
        ),
      ],
    );
  }
}

// One compact stat card: icon, big count, label.
class _MiniStatCard extends StatelessWidget {
  final IconData icon;
  final int count;
  final String label;
  final VoidCallback? onTap;

  const _MiniStatCard({
    required this.icon,
    required this.count,
    required this.label,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
        decoration: BoxDecoration(
          color: AppTheme.white,
          borderRadius: BorderRadius.circular(AppTheme.radiusCard),
          boxShadow: AppTheme.cardShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppTheme.accent.withOpacity(0.5),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(icon, size: 20, color: AppTheme.black),
            ),
            const SizedBox(height: 10),
            Text(
              '$count',
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontFamily: AppTheme.font,
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: AppTheme.tagText,
                height: 1,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontFamily: AppTheme.font,
                fontSize: 13,
                color: AppTheme.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── A simple settings row (icon right, label, chevron left) ────────
class _SettingsRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _SettingsRow({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          // RTL: first child = visual RIGHT, last child = visual LEFT.
          children: [
            // Leading icon — visual RIGHT
            Icon(icon, size: 22, color: AppTheme.tagText),
            const SizedBox(width: 12),
            // Label — next to the icon on the right
            Text(
              label,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontFamily: AppTheme.font,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const Spacer(),
            // Chevron — visual LEFT, pointing left
            const _RtlChevron(),
          ],
        ),
      ),
    );
  }
}

// ── "בא לכם לשתף משהו?" — highlighted row ──────────────────────────
class _ShareMemoryRow extends StatelessWidget {
  final VoidCallback onTap;
  const _ShareMemoryRow({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
          color: AppTheme.accent.withOpacity(0.4),
          borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        ),
        child: Row(
          // RTL: first child = visual RIGHT, last child = visual LEFT.
          children: [
            // Heart icon — visual RIGHT
            const Icon(Icons.favorite_outline_rounded,
                size: 24, color: AppTheme.tagText),
            const SizedBox(width: 12),
            // Title + subtitle — next to the icon on the right
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: const [
                Text(
                  'בא לכם לשתף משהו? 💚',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontFamily: AppTheme.font,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.tagText,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'זיכרון, סיפור או מילה טובה — נשמח לשמוע',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontFamily: AppTheme.font,
                    fontSize: 12,
                    color: AppTheme.tagText,
                  ),
                ),
              ],
            ),
            const Spacer(),
            // Chevron — visual LEFT, pointing left
            const _RtlChevron(color: AppTheme.tagText),
          ],
        ),
      ),
    );
  }
}

// ── A tappable contact row inside the עזרה וצור קשר sheet ──────────
class _ContactRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;

  const _ContactRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          color: AppTheme.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
                color: AppTheme.shadow, blurRadius: 4, offset: Offset(2, 1)),
          ],
        ),
        child: Row(
          // RTL: first child = visual RIGHT, last child = visual LEFT.
          children: [
            Icon(icon, size: 20, color: AppTheme.tagText),
            const SizedBox(width: 12),
            Text(
              label,
              style: const TextStyle(
                fontFamily: AppTheme.font,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
            const Spacer(),
            Text(
              value,
              style: const TextStyle(
                fontFamily: AppTheme.font,
                fontSize: 13,
                color: AppTheme.textMuted,
              ),
            ),
            const SizedBox(width: 8),
            const _RtlChevron(),
          ],
        ),
      ),
    );
  }
}

// ── Sign out button (red, with confirm handled by caller) ──────────
class _SignOutButton extends StatelessWidget {
  final VoidCallback onTap;
  const _SignOutButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(
          color: const Color(0xFFFCEAE8),
          borderRadius: BorderRadius.circular(AppTheme.radiusPill),
          border: Border.all(color: const Color(0xFFE8C5C0), width: 1),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.logout_rounded, size: 20, color: Color(0xFFC0392B)),
            SizedBox(width: 8),
            Text(
              'התנתקות',
              style: TextStyle(
                fontFamily: AppTheme.font,
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xFFC0392B),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
