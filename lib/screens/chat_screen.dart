import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geodesy/geodesy.dart';
import '../theme/app_theme.dart';

// ─────────────────────────────────────────────────────────────────
//  CHAT SCREEN
//  Two modes, decided by GPS proximity to the trailhead:
//
//  ON TRAIL  → user is within startRadiusMeters of the trailhead.
//              Full open chat — type and send anything.
//  OFF TRAIL → user is too far away.
//              Only 5 preset questions, shown as tappable buttons.
//              Tapping sends the question so hikers currently on
//              the trail can answer it later.
//
//  The GPS check lives HERE (self-contained). Any screen that opens
//  chat just passes the trailhead coords; chat decides the mode
//  itself. The one exception is Live Mode, which is already tracking
//  the user on the trail, so it passes forceOnTrail: true to skip
//  the redundant check.
//
//  Firestore structure:
//    trails/{trailId}/chat/{messageId}
//      - message:   String
//      - timestamp: Timestamp
//      - userId:    String
//      - isPreset:  bool (true if sent from preset buttons)
// ─────────────────────────────────────────────────────────────────

// ── 5 preset questions for off-trail users ────────────────────────
const List<String> kPresetQuestions = [
  'האם המסלול עמוס עכשיו? 👥',
  'מה מצב המים במסלול? 💧',
  'האם המסלול מתאים לילדים? 👨‍👩‍👧',
  'כמה זמן לקח לכם? ⏱️',
  'מה כדאי להביא? 🎒',
];

// ── The three states the screen can be in ─────────────────────────
enum _TrailStatus { checking, onTrail, offTrail }

class ChatScreen extends StatefulWidget {
  final String trailId;
  final String trailName;

  // Trailhead location — used for the GPS proximity check.
  final double startLat;
  final double startLng;
  final double startRadiusMeters;

  // When true, skip the GPS check and go straight to full chat.
  // Live Mode passes this because it's already tracking the user.
  final bool forceOnTrail;

  // Optional pre-computed answer from the caller. The trail profile
  // already runs its own GPS check (the "check location" button), so
  // it passes that result here — chat trusts it and skips re-checking.
  // Leave null and chat will run its own GPS check on open.
  final bool? knownOnTrail;

  const ChatScreen({
    super.key,
    required this.trailId,
    required this.trailName,
    required this.startLat,
    required this.startLng,
    this.startRadiusMeters = 100,
    this.forceOnTrail = false,
    this.knownOnTrail,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _msgCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();

  // Track which preset questions have been sent (so they dim)
  final Set<String> _sentPresets = {};

  // Mode is now STATE, not a fixed widget field.
  _TrailStatus _status = _TrailStatus.checking;

  bool get _isOnTrail => _status == _TrailStatus.onTrail;

  @override
  void initState() {
    super.initState();
    if (widget.forceOnTrail) {
      // Live Mode already knows we're on the trail.
      _status = _TrailStatus.onTrail;
    } else if (widget.knownOnTrail != null) {
      // The caller (e.g. trail profile) already did the GPS check.
      // Trust it — no need to re-check and risk disagreeing.
      _status =
          widget.knownOnTrail! ? _TrailStatus.onTrail : _TrailStatus.offTrail;
    } else {
      // No answer handed to us — figure it out ourselves.
      _checkProximity();
    }
  }

  @override
  void dispose() {
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  // ── GPS check: are we within startRadiusMeters of the trailhead? ─
  Future<void> _checkProximity() async {
    try {
      // Make sure location services are on.
      final serviceOn = await Geolocator.isLocationServiceEnabled();
      if (!serviceOn) {
        if (mounted) setState(() => _status = _TrailStatus.offTrail);
        return;
      }

      // Make sure we have permission.
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        if (mounted) setState(() => _status = _TrailStatus.offTrail);
        return;
      }

      // Grab one fix and measure distance to the trailhead.
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final dist = Geodesy().distanceBetweenTwoGeoPoints(
        LatLng(pos.latitude, pos.longitude),
        LatLng(widget.startLat, widget.startLng),
      );

      if (!mounted) return;
      setState(() => _status = dist <= widget.startRadiusMeters
          ? _TrailStatus.onTrail
          : _TrailStatus.offTrail);
    } catch (_) {
      // Any failure → safest default is off-trail (presets only).
      if (mounted) setState(() => _status = _TrailStatus.offTrail);
    }
  }

  // ── Send any message to Firestore ─────────────────────────────
  Future<void> _sendMessage(String text, {bool isPreset = false}) async {
    if (text.trim().isEmpty) return;
    _msgCtrl.clear();

    await FirebaseFirestore.instance
        .collection('trails')
        .doc(widget.trailId)
        .collection('chat')
        .add({
      'message': text.trim(),
      'timestamp': FieldValue.serverTimestamp(),
      'userId': 'user_${DateTime.now().millisecondsSinceEpoch}',
      'isPreset': isPreset,
    });

    // Mark preset as sent so it dims
    if (isPreset) {
      setState(() => _sentPresets.add(text));
    }

    // Scroll to bottom
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ──────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Back — left in RTL
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                          color: AppTheme.accentDark,
                          borderRadius: BorderRadius.circular(18)),
                      child: const Icon(Icons.arrow_forward_rounded, size: 18),
                    ),
                  ),
                  // Title
                  Column(children: [
                    Text(widget.trailName,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            fontFamily: AppTheme.font,
                            fontSize: 16,
                            fontWeight: FontWeight.w700)),
                    const Text('צ׳אט המסלול',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontFamily: AppTheme.font,
                            fontSize: 12,
                            color: AppTheme.textMuted)),
                  ]),
                  const SizedBox(width: 36),
                ],
              ),
            ),

            // ── Status strip — changes based on mode ─────────
            _StatusStrip(status: _status),
            const SizedBox(height: 8),

            // ── OFF TRAIL: Preset questions ───────────────────
            if (_status == _TrailStatus.offTrail) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'שאל את המטיילים:',
                      textAlign: TextAlign.right,
                      style: TextStyle(
                          fontFamily: AppTheme.font,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.tagText),
                    ),
                    const SizedBox(height: 8),
                    // 5 preset question buttons
                    ...kPresetQuestions.map((q) {
                      final sent = _sentPresets.contains(q);
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: GestureDetector(
                          onTap: sent
                              ? null
                              : () => _sendMessage(q, isPreset: true),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: sent
                                  ? const Color(0xFFF0F0F0)
                                  : AppTheme.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: sent
                                    ? const Color(0xFFE0E0E0)
                                    : AppTheme.accent,
                                width: 1.5,
                              ),
                              boxShadow: sent ? [] : AppTheme.cardShadow,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                // Sent indicator
                                sent
                                    ? const Icon(Icons.check_rounded,
                                        size: 16, color: Color(0xFF2A6A3A))
                                    : const Icon(Icons.send_rounded,
                                        size: 16, color: AppTheme.textMuted),
                                // Question text
                                Expanded(
                                  child: Text(q,
                                      textAlign: TextAlign.right,
                                      style: TextStyle(
                                          fontFamily: AppTheme.font,
                                          fontSize: 14,
                                          color: sent
                                              ? AppTheme.textMuted
                                              : AppTheme.black)),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ],
                ),
              ),
            ],

            // ── Messages list ────────────────────────────────
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('trails')
                    .doc(widget.trailId)
                    .collection('chat')
                    .orderBy('timestamp', descending: false)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting)
                    return const Center(child: CircularProgressIndicator());

                  final docs = snapshot.data?.docs ?? [];

                  if (docs.isEmpty)
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.chat_bubble_outline_rounded,
                              size: 52, color: Color(0xFFD0D0D0)),
                          const SizedBox(height: 12),
                          Text(
                            _isOnTrail
                                ? 'אין הודעות עדיין\nהיה הראשון לכתוב!'
                                : 'אין מטיילים פעילים כרגע\nשאל שאלה ותקבל תשובה מאוחר יותר!',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                fontFamily: AppTheme.font,
                                fontSize: 14,
                                color: AppTheme.textMuted,
                                height: 1.5),
                          ),
                        ],
                      ),
                    );

                  return ListView.separated(
                    controller: _scrollCtrl,
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                    itemCount: docs.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, i) {
                      final d = docs[i].data() as Map<String, dynamic>;
                      final msg = d['message'] as String? ?? '';
                      final ts = d['timestamp'] as Timestamp?;
                      final isPreset = d['isPreset'] as bool? ?? false;

                      String time = '';
                      if (ts != null) {
                        final dt = ts.toDate();
                        time =
                            '${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
                      }

                      return _MessageBubble(
                        message: msg,
                        time: time,
                        isPreset: isPreset,
                      );
                    },
                  );
                },
              ),
            ),

            // ── Bottom bar — depends on mode ──────────────────
            _buildBottomBar(),
          ],
        ),
      ),
    );
  }

  // ── Bottom bar: input (on trail) / note (off trail) / nothing ──
  Widget _buildBottomBar() {
    switch (_status) {
      case _TrailStatus.checking:
        // Still figuring out location — show nothing yet.
        return const SizedBox.shrink();

      case _TrailStatus.onTrail:
        // Full text input.
        return Container(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
          decoration: const BoxDecoration(
            color: AppTheme.white,
            boxShadow: [
              BoxShadow(
                  color: AppTheme.shadow, blurRadius: 8, offset: Offset(0, -2)),
            ],
          ),
          child: Row(
            children: [
              // Send button
              GestureDetector(
                onTap: () => _sendMessage(_msgCtrl.text),
                child: Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                      color: AppTheme.accent,
                      borderRadius: BorderRadius.circular(21)),
                  child: const Icon(Icons.send_rounded,
                      size: 18, color: AppTheme.black),
                ),
              ),
              const SizedBox(width: 10),
              // Text field
              Expanded(
                child: TextField(
                  controller: _msgCtrl,
                  textDirection: TextDirection.rtl,
                  textAlign: TextAlign.right,
                  onSubmitted: (t) => _sendMessage(t),
                  decoration: InputDecoration(
                    hintText: 'כתוב הודעה...',
                    hintStyle: const TextStyle(
                        fontFamily: AppTheme.font,
                        fontSize: 14,
                        color: Color(0xFFD0D0D0)),
                    filled: true,
                    fillColor: AppTheme.bg,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 11),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(22),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );

      case _TrailStatus.offTrail:
        // No input bar, just a note explaining why.
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          color: AppTheme.bg,
          child: const Text(
            'הגע למסלול כדי לשוחח בחופשיות 🥾',
            textAlign: TextAlign.center,
            style: TextStyle(
                fontFamily: AppTheme.font,
                fontSize: 13,
                color: AppTheme.textMuted),
          ),
        );
    }
  }
}

// ── Status strip widget ───────────────────────────────────────────
class _StatusStrip extends StatelessWidget {
  final _TrailStatus status;
  const _StatusStrip({required this.status});

  @override
  Widget build(BuildContext context) {
    // Colors + text + icon per status.
    late final Color bgColor;
    late final Color fgColor;
    late final String text;
    late final IconData icon;

    switch (status) {
      case _TrailStatus.checking:
        bgColor = AppTheme.accent.withOpacity(0.25);
        fgColor = const Color(0xFF6A6A6A);
        text = 'בודק את המיקום שלך...';
        icon = Icons.my_location_rounded;
        break;
      case _TrailStatus.onTrail:
        bgColor = const Color(0xFFD3E8D5).withOpacity(0.6);
        fgColor = const Color(0xFF2A6A3A);
        text = 'אתה על המסלול — שוחח עם המטיילים! 🥾';
        icon = Icons.check_circle_outline_rounded;
        break;
      case _TrailStatus.offTrail:
        bgColor = AppTheme.accent.withOpacity(0.4);
        fgColor = const Color(0xFF3A7A9A);
        text = 'שאל מטיילים שנמצאים עכשיו על המסלול';
        icon = Icons.info_outline_rounded;
        break;
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              text,
              textAlign: TextAlign.right,
              style: TextStyle(
                  fontFamily: AppTheme.font, fontSize: 12, color: fgColor),
            ),
          ),
          const SizedBox(width: 8),
          // Spinner while checking, otherwise the status icon.
          if (status == _TrailStatus.checking)
            SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(strokeWidth: 2, color: fgColor),
            )
          else
            Icon(icon, size: 16, color: fgColor),
        ],
      ),
    );
  }
}

// ── Message bubble ────────────────────────────────────────────────
class _MessageBubble extends StatelessWidget {
  final String message, time;
  final bool isPreset;

  const _MessageBubble({
    required this.message,
    required this.time,
    this.isPreset = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        // Preset questions get a slightly different style
        color: isPreset ? AppTheme.accent.withOpacity(0.3) : AppTheme.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: isPreset ? [] : AppTheme.cardShadow,
        border: isPreset ? Border.all(color: AppTheme.accent, width: 1) : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Preset label
          if (isPreset)
            const Padding(
              padding: EdgeInsets.only(bottom: 4),
              child: Text('שאלה מלפני הטיול',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                      fontFamily: AppTheme.font,
                      fontSize: 10,
                      color: AppTheme.textMuted)),
            ),
          Text(message,
              textAlign: TextAlign.right,
              style: const TextStyle(fontFamily: AppTheme.font, fontSize: 15)),
          const SizedBox(height: 4),
          Text(time,
              textAlign: TextAlign.left,
              style: const TextStyle(
                  fontFamily: AppTheme.font,
                  fontSize: 11,
                  color: AppTheme.textMuted)),
        ],
      ),
    );
  }
}
