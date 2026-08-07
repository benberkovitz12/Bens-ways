import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geodesy/geodesy.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as latlong;
import '../theme/app_theme.dart';
import 'chat_screen.dart';

class LiveModeScreen extends StatefulWidget {
  final String trailId;
  final String trailName;
  final double startLat;
  final double startLng;

  const LiveModeScreen({
    super.key,
    required this.trailId,
    required this.trailName,
    required this.startLat,
    required this.startLng,
  });

  @override
  State<LiveModeScreen> createState() => _LiveModeScreenState();
}

class _LiveModeScreenState extends State<LiveModeScreen> {
  final List<LatLng> _walkedPath = [];
  Position? _currentPosition;
  double _totalDistanceWalked = 0.0;
  final Set<String> _visitedCheckpoints = {};
  List<Map<String, dynamic>> _checkpoints = [];

  @override
  void initState() {
    super.initState();
    _loadCheckpoints();
    _startTracking();
  }

  Future<void> _loadCheckpoints() async {
    final snap = await FirebaseFirestore.instance
        .collection('trails')
        .doc(widget.trailId)
        .collection('checkpoints')
        .get();
    setState(() => _checkpoints =
        snap.docs.map((d) => {'id': d.id, ...d.data()}).toList());
  }

  void _startTracking() {
    Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high, distanceFilter: 5),
    ).listen((pos) {
      setState(() {
        _currentPosition = pos;
        if (_walkedPath.isEmpty) {
          _walkedPath.add(LatLng(pos.latitude, pos.longitude));
        } else {
          final last = _walkedPath.last;
          final dist = Geodesy().distanceBetweenTwoGeoPoints(
              last, LatLng(pos.latitude, pos.longitude));
          if (dist >= 5) {
            _walkedPath.add(LatLng(pos.latitude, pos.longitude));
            _totalDistanceWalked += dist;
            _checkForCheckpoints();
          }
        }
      });
    });
  }

  void _checkForCheckpoints() {
    for (var cp in _checkpoints) {
      final id = cp['id'] as String;
      final triggerDist = (cp['distanceMeters'] as num?)?.toDouble() ?? 0;
      if (_totalDistanceWalked >= triggerDist &&
          !_visitedCheckpoints.contains(id)) {
        _visitedCheckpoints.add(id);
        _showCheckpointDialog(cp);
        break;
      }
    }
  }

  void _showCheckpointDialog(Map<String, dynamic> cp) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: AppTheme.bg,
        title: Row(children: [
          const Icon(Icons.star_rounded, color: Colors.amber, size: 28),
          const SizedBox(width: 8),
          Expanded(
            child: Text(cp['name'] ?? 'עמדה הושגה!',
                textAlign: TextAlign.right,
                style: const TextStyle(
                    fontFamily: AppTheme.font,
                    fontSize: 18,
                    fontWeight: FontWeight.w700)),
          ),
        ]),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(cp['message'] ?? 'כל הכבוד!',
              textAlign: TextAlign.center,
              style: const TextStyle(fontFamily: AppTheme.font, fontSize: 16)),
          const SizedBox(height: 12),
          Text(
            'מרחק שהלכת: ${_totalDistanceWalked.toStringAsFixed(0)}מ',
            textAlign: TextAlign.center,
            style: const TextStyle(
                fontFamily: AppTheme.font,
                fontSize: 13,
                color: AppTheme.textMuted),
          ),
        ]),
        actions: [
          Center(
            child: GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                    color: AppTheme.accent,
                    borderRadius: BorderRadius.circular(20)),
                child: const Text('המשך ללכת!',
                    style: TextStyle(fontFamily: AppTheme.font, fontSize: 15)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: SafeArea(
        child: Column(
          children: [
            // ── Top bar ───────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
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
                  Text(widget.trailName,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontFamily: AppTheme.font,
                          fontSize: 16,
                          fontWeight: FontWeight.w700)),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.red.shade200, width: 1),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                              color: Colors.red, shape: BoxShape.circle)),
                      const SizedBox(width: 6),
                      const Text('LIVE',
                          style: TextStyle(
                              fontFamily: AppTheme.font,
                              fontSize: 13,
                              color: Colors.red,
                              fontWeight: FontWeight.w700)),
                    ]),
                  ),
                ],
              ),
            ),

            // ── Stats strip ───────────────────────────────────
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: AppTheme.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: AppTheme.cardShadow,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _LiveStat(
                      label: 'מרחק',
                      value: '${_totalDistanceWalked.toStringAsFixed(0)}מ'),
                  Container(width: 1, height: 30, color: AppTheme.divider),
                  _LiveStat(
                      label: 'עמדות',
                      value:
                          '${_visitedCheckpoints.length}/${_checkpoints.length}'),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // ── Map ───────────────────────────────────────────
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: _currentPosition == null
                      ? Container(
                          color: AppTheme.white,
                          child:
                              const Center(child: CircularProgressIndicator()))
                      : FlutterMap(
                          options: MapOptions(
                            initialCenter: latlong.LatLng(
                                _currentPosition!.latitude,
                                _currentPosition!.longitude),
                            initialZoom: 17.0,
                          ),
                          children: [
                            TileLayer(
                              urlTemplate:
                                  'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                              userAgentPackageName: 'com.example.bens_ways',
                            ),
                            if (_walkedPath.isNotEmpty)
                              PolylineLayer(polylines: [
                                Polyline(
                                  points: _walkedPath
                                      .map((p) => latlong.LatLng(
                                          p.latitude, p.longitude))
                                      .toList(),
                                  strokeWidth: 4.0,
                                  color: AppTheme.accentDark,
                                ),
                              ]),
                            MarkerLayer(markers: [
                              Marker(
                                point: latlong.LatLng(
                                    _currentPosition!.latitude,
                                    _currentPosition!.longitude),
                                width: 44,
                                height: 44,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: AppTheme.accentDark,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                        color: AppTheme.white, width: 3),
                                  ),
                                  child: const Icon(Icons.person_rounded,
                                      color: AppTheme.black, size: 22),
                                ),
                              ),
                            ]),
                          ],
                        ),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // ── Chat button — always on trail in live mode ────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ChatScreen(
                      trailId: widget.trailId,
                      trailName: widget.trailName,
                      startLat: widget.startLat,
                      startLng: widget.startLng,
                      forceOnTrail: true, // always on trail in live mode!
                    ),
                  ),
                ),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  decoration: BoxDecoration(
                    color: AppTheme.accent,
                    borderRadius: BorderRadius.circular(AppTheme.radiusPill),
                    boxShadow: AppTheme.cardShadow,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.chat_bubble_outline_rounded,
                          size: 20, color: AppTheme.black),
                      SizedBox(width: 8),
                      Text('צ׳אט המסלול',
                          style: TextStyle(
                              fontFamily: AppTheme.font, fontSize: 16)),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LiveStat extends StatelessWidget {
  final String label, value;
  const _LiveStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Column(
        children: [
          Text(value,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontFamily: AppTheme.font,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.tagText)),
          Text(label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontFamily: AppTheme.font,
                  fontSize: 12,
                  color: AppTheme.textMuted)),
        ],
      );
}
