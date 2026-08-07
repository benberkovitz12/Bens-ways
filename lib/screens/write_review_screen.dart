import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme/app_theme.dart';
import '../services/auth_service.dart';

// ─────────────────────────────────────────────────────────────────
//  WRITE REVIEW SCREEN  (כתיבת ביקורת)
//  Stars (1–5) + free text. Saves to the same subcollection the
//  reviews tab already displays:
//
//    trails/{trailId}/reviews/{autoId}
//      - userName:  String   (from the signed-in user)
//      - text:      String
//      - stars:     int (1–5)
//      - timestamp: Timestamp
//
//  On success we pop back — the reviews tab is a live stream, so the
//  new review appears at the top instantly. Satisfying!
//
//  RTL inherited app-wide. Stars row is centered so direction is moot.
// ─────────────────────────────────────────────────────────────────

class WriteReviewScreen extends StatefulWidget {
  final String trailId;
  final String trailName;

  const WriteReviewScreen({
    super.key,
    required this.trailId,
    required this.trailName,
  });

  @override
  State<WriteReviewScreen> createState() => _WriteReviewScreenState();
}

class _WriteReviewScreenState extends State<WriteReviewScreen> {
  final TextEditingController _ctrl = TextEditingController();
  int _stars = 0;
  bool _sending = false;
  String? _error;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final text = _ctrl.text.trim();

    if (_stars == 0) {
      setState(() => _error = 'בחרו דירוג כוכבים.');
      return;
    }
    if (text.isEmpty) {
      setState(() => _error = 'כתבו כמה מילים על החוויה.');
      return;
    }

    setState(() {
      _sending = true;
      _error = null;
    });

    try {
      await FirebaseFirestore.instance
          .collection('trails')
          .doc(widget.trailId)
          .collection('reviews')
          .add({
        'userName': AuthService.instance.displayName,
        'text': text,
        'stars': _stars,
        'timestamp': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('הביקורת פורסמה! תודה ששיתפתם 💚')),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _sending = false;
        _error = 'משהו השתבש בשליחה. נסו שוב.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ──────────────────────────────────────────
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
                  Column(
                    children: [
                      const Text(
                        'כתיבת ביקורת',
                        style: TextStyle(
                          fontFamily: AppTheme.font,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        widget.trailName,
                        style: const TextStyle(
                          fontFamily: AppTheme.font,
                          fontSize: 12,
                          color: AppTheme.textMuted,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 38),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Star picker ─────────────────────────────
                    const Center(
                      child: Text(
                        'איך היה המסלול?',
                        style: TextStyle(
                          fontFamily: AppTheme.font,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: List.generate(5, (i) {
                          final filled = i < _stars;
                          return GestureDetector(
                            onTap: () => setState(() => _stars = i + 1),
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 4),
                              child: Icon(
                                filled
                                    ? Icons.star_rounded
                                    : Icons.star_border_rounded,
                                size: 42,
                                color: filled
                                    ? const Color(0xFFF2B01E)
                                    : const Color(0xFFD0D0D0),
                              ),
                            ),
                          );
                        }),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // ── Text ────────────────────────────────────
                    const Text(
                      'ספרו על החוויה',
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontFamily: AppTheme.font,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      decoration: BoxDecoration(
                        color: AppTheme.white,
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: AppTheme.cardShadow,
                      ),
                      child: TextField(
                        controller: _ctrl,
                        maxLines: 6,
                        maxLength: 500,
                        textDirection: TextDirection.rtl,
                        textAlign: TextAlign.right,
                        style: const TextStyle(
                            fontFamily: AppTheme.font,
                            fontSize: 15,
                            height: 1.5),
                        decoration: InputDecoration(
                          hintText:
                              'מה אהבתם? למי המסלול מתאים? טיפים למטיילים הבאים...',
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

                    // ── Error ───────────────────────────────────
                    if (_error != null) ...[
                      const SizedBox(height: 12),
                      Center(
                        child: Text(
                          _error!,
                          style: const TextStyle(
                            fontFamily: AppTheme.font,
                            fontSize: 13,
                            color: Color(0xFFC0392B),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(height: 20),

                    // ── Submit ──────────────────────────────────
                    GestureDetector(
                      onTap: _sending ? null : _submit,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          color: _sending
                              ? AppTheme.accent.withOpacity(0.6)
                              : AppTheme.accent,
                          borderRadius:
                              BorderRadius.circular(AppTheme.radiusPill),
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
                                  'פרסום הביקורת',
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
              ),
            ),
          ],
        ),
      ),
    );
  }
}
