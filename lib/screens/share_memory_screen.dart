import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme/app_theme.dart';
import '../services/auth_service.dart';

// ─────────────────────────────────────────────────────────────────
//  SHARE MEMORY SCREEN  (שיתוף מחשבה / זיכרון עבור בן והעמותה)
//  A small dedicated screen where a user writes a thought or memory
//  for Ben. Submissions are saved to a top-level Firestore collection
//  the עמותה can read from the console:
//
//    memories/{autoId}
//      - message:    String
//      - userName:   String   (from the signed-in user)
//      - userEmail:  String
//      - timestamp:  Timestamp
//
//  No email server needed — every submission is captured in Firestore.
//  (Real email delivery can later be added via a Cloud Function on this
//  collection, but that's an optional future layer.)
//
//  RTL inherited app-wide. .start = visual RIGHT.
// ─────────────────────────────────────────────────────────────────

class ShareMemoryScreen extends StatefulWidget {
  const ShareMemoryScreen({super.key});

  @override
  State<ShareMemoryScreen> createState() => _ShareMemoryScreenState();
}

class _ShareMemoryScreenState extends State<ShareMemoryScreen> {
  final TextEditingController _ctrl = TextEditingController();
  bool _sending = false;
  bool _sent = false;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty) return;

    setState(() => _sending = true);

    try {
      final user = AuthService.instance.currentUser;
      await FirebaseFirestore.instance.collection('memories').add({
        'message': text,
        'userName': user?.displayName ?? 'אנונימי',
        'userEmail': user?.email ?? '',
        'timestamp': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      setState(() {
        _sending = false;
        _sent = true; // show the thank-you state
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _sending = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('משהו השתבש בשליחה. נסו שוב.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: SafeArea(
        child: Column(
          children: [
            // ── Header with back button ─────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: AppTheme.accentDark,
                        borderRadius: BorderRadius.circular(19),
                      ),
                      child: const Icon(Icons.arrow_forward_rounded, size: 19),
                    ),
                  ),
                  const Text(
                    'שיתוף מחשבה',
                    style: TextStyle(
                      fontFamily: AppTheme.font,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(width: 38),
                ],
              ),
            ),

            Expanded(
              child: _sent ? _buildThankYou() : _buildForm(),
            ),
          ],
        ),
      ),
    );
  }

  // ── The writing form ───────────────────────────────────────────
  Widget _buildForm() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Friendly intro
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.accent.withOpacity(0.4),
              borderRadius: BorderRadius.circular(AppTheme.radiusCard),
            ),
            child: const Text(
              'יש לכם זיכרון, מחשבה או סתם משהו שבא לכם לשתף? '
              'נשמח לשמוע. ההודעה תגיע ישירות אלינו 💚',
              textAlign: TextAlign.right,
              style: TextStyle(
                fontFamily: AppTheme.font,
                fontSize: 14,
                height: 1.5,
                color: AppTheme.tagText,
              ),
            ),
          ),
          const SizedBox(height: 20),

          const Text(
            'ההודעה שלכם',
            textAlign: TextAlign.right,
            style: TextStyle(
              fontFamily: AppTheme.font,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),

          // The text box
          Container(
            decoration: BoxDecoration(
              color: AppTheme.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: AppTheme.cardShadow,
            ),
            child: TextField(
              controller: _ctrl,
              maxLines: 7,
              maxLength: 1000,
              textDirection: TextDirection.rtl,
              textAlign: TextAlign.right,
              style: const TextStyle(
                  fontFamily: AppTheme.font, fontSize: 15, height: 1.5),
              decoration: InputDecoration(
                hintText: 'כתבו כאן...',
                hintStyle: const TextStyle(
                  fontFamily: AppTheme.font,
                  fontSize: 14,
                  color: Color(0xFFC0C0C0),
                ),
                filled: true,
                fillColor: AppTheme.white,
                contentPadding: const EdgeInsets.all(16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: BorderSide.none,
                ),
                counterStyle: const TextStyle(
                    fontFamily: AppTheme.font,
                    fontSize: 11,
                    color: AppTheme.textMuted),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Send button
          GestureDetector(
            onTap: _sending ? null : _submit,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: _sending
                    ? AppTheme.accent.withOpacity(0.6)
                    : AppTheme.accent,
                borderRadius: BorderRadius.circular(AppTheme.radiusPill),
                boxShadow: AppTheme.ctaShadow,
              ),
              child: Center(
                child: _sending
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                            strokeWidth: 2.4, color: AppTheme.black),
                      )
                    : const Text(
                        'שליחה',
                        style: TextStyle(
                          fontFamily: AppTheme.font,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Thank-you state after a successful send ────────────────────
  Widget _buildThankYou() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: const BoxDecoration(
                color: Color(0xFFD3E8D5),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.favorite_rounded,
                  size: 44, color: Color(0xFF2A6A3A)),
            ),
            const SizedBox(height: 22),
            const Text(
              'תודה ששיתפתם 💚',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: AppTheme.font,
                fontSize: 22,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'ההודעה שלכם התקבלה ותגיע אל העמותה והמשפחה.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: AppTheme.font,
                fontSize: 15,
                color: AppTheme.textMuted,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 28),
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 13),
                decoration: BoxDecoration(
                  color: AppTheme.accent,
                  borderRadius: BorderRadius.circular(AppTheme.radiusPill),
                  boxShadow: AppTheme.ctaShadow,
                ),
                child: const Text(
                  'חזרה',
                  style: TextStyle(fontFamily: AppTheme.font, fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
