import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ─────────────────────────────────────────────────────────────────
//  SAVED TRAILS SERVICE
//  The single source of truth for which trails the user has saved.
//
//  HOW IT WORKS:
//  - Saved trail IDs (e.g. 'trail_6') are kept in a Set in memory AND
//    persisted to the device via shared_preferences, so they survive
//    app restarts.
//  - This is a ChangeNotifier: any widget that listens to it rebuilds
//    the instant a trail is saved/unsaved. That's how the bookmark
//    icon on a card and the שמורים screen stay in sync automatically.
//  - It's a singleton — use SavedTrailsService.instance everywhere so
//    the whole app shares one list.
//
//  USAGE:
//    // once, early in app startup (main.dart):
//    await SavedTrailsService.instance.init();
//
//    // anywhere:
//    SavedTrailsService.instance.isSaved('trail_6');   // -> bool
//    SavedTrailsService.instance.toggle('trail_6');    // save/unsave
//    SavedTrailsService.instance.savedIds;             // -> Set<String>
//
//    // to rebuild on change (e.g. in a card):
//    AnimatedBuilder(
//      animation: SavedTrailsService.instance,
//      builder: (_, __) => ...,
//    )
//
//  NOTE: This is local-only storage for now. When user auth lands,
//  we can swap the _persist()/_load() internals for Firestore without
//  touching any screen that uses this service.
// ─────────────────────────────────────────────────────────────────

class SavedTrailsService extends ChangeNotifier {
  SavedTrailsService._();
  static final SavedTrailsService instance = SavedTrailsService._();

  static const _prefsKey = 'saved_trail_ids';

  final Set<String> _savedIds = <String>{};
  bool _ready = false;

  /// True once init() has finished loading from disk.
  bool get isReady => _ready;

  /// A read-only copy of the saved trail IDs.
  Set<String> get savedIds => Set.unmodifiable(_savedIds);

  /// How many trails are currently saved (for the header count).
  int get count => _savedIds.length;

  /// Load saved IDs from the device. Call once at app startup.
  Future<void> init() async {
    if (_ready) return;
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getStringList(_prefsKey) ?? <String>[];
    _savedIds
      ..clear()
      ..addAll(stored);
    _ready = true;
    notifyListeners();
  }

  /// Is this trail currently saved?
  bool isSaved(String trailId) => _savedIds.contains(trailId);

  /// Save or unsave a trail (whichever it currently isn't), then persist.
  Future<void> toggle(String trailId) async {
    if (_savedIds.contains(trailId)) {
      _savedIds.remove(trailId);
    } else {
      _savedIds.add(trailId);
    }
    notifyListeners(); // update the UI immediately
    await _persist(); // then save to disk in the background
  }

  /// Force a trail to saved (no-op if already saved).
  Future<void> save(String trailId) async {
    if (_savedIds.add(trailId)) {
      notifyListeners();
      await _persist();
    }
  }

  /// Force a trail to unsaved (no-op if not saved).
  Future<void> remove(String trailId) async {
    if (_savedIds.remove(trailId)) {
      notifyListeners();
      await _persist();
    }
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_prefsKey, _savedIds.toList());
  }
}
