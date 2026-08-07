import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ─────────────────────────────────────────────────────────────────
//  COMPLETED TRAILS SERVICE
//  Tracks which trails the user has COMPLETED (walked end-to-end in
//  live mode). Mirrors SavedTrailsService exactly:
//    - singleton with an `instance` accessor
//    - ChangeNotifier so UI rebuilds live (AnimatedBuilder)
//    - SharedPreferences persistence (local only — syncing to the
//      user's account comes later, together with saved-trails sync)
//
//  USAGE:
//    await CompletedTrailsService.instance.init();   // in main.dart
//    CompletedTrailsService.instance.markCompleted('trail_7');
//    CompletedTrailsService.instance.count;           // → 3
//    CompletedTrailsService.instance.isCompleted(id); // → true/false
// ─────────────────────────────────────────────────────────────────

class CompletedTrailsService extends ChangeNotifier {
  CompletedTrailsService._();
  static final CompletedTrailsService instance = CompletedTrailsService._();

  static const String _prefsKey = 'completed_trail_ids';

  Set<String> _ids = {};
  bool _initialized = false;

  /// Load persisted IDs. Call once in main.dart, after Firebase init,
  /// right next to SavedTrailsService.instance.init().
  Future<void> init() async {
    if (_initialized) return;
    final prefs = await SharedPreferences.getInstance();
    _ids = (prefs.getStringList(_prefsKey) ?? []).toSet();
    _initialized = true;
    notifyListeners();
  }

  /// How many trails the user has completed.
  int get count => _ids.length;

  /// All completed trail IDs (read-only copy).
  Set<String> get ids => Set.unmodifiable(_ids);

  /// Has this trail been completed?
  bool isCompleted(String trailId) => _ids.contains(trailId);

  /// Mark a trail as completed. Safe to call twice — a trail only
  /// counts once no matter how many times it's walked.
  Future<void> markCompleted(String trailId) async {
    if (trailId.isEmpty || _ids.contains(trailId)) return;
    _ids.add(trailId);
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_prefsKey, _ids.toList());
  }
}
