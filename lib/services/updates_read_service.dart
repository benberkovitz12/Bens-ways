import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ─────────────────────────────────────────────────────────────────
//  UPDATES READ SERVICE  (עדכונים — read/unread tracking)
//
//  The "brain" for which system updates the user has already read.
//  Mirrors SavedTrailsService exactly so it's familiar:
//    - singleton, extends ChangeNotifier
//    - stores READ update IDs in a Set<String>
//    - persisted to shared_preferences under 'read_update_ids'
//
//  Screens listen via AnimatedBuilder(animation: UpdatesReadService
//  .instance, ...) so the blue→grey switch and the nav unread badge
//  update instantly app-wide.
//
//  LOCAL ONLY for now (no auth yet). The _persist()/_load() internals
//  can later be swapped to Firestore without touching any screen —
//  same approach as the saved service.
// ─────────────────────────────────────────────────────────────────

class UpdatesReadService extends ChangeNotifier {
  UpdatesReadService._();
  static final UpdatesReadService instance = UpdatesReadService._();

  static const _prefsKey = 'read_update_ids';

  final Set<String> _readIds = {};
  bool _ready = false;

  bool get isReady => _ready;
  Set<String> get readIds => Set.unmodifiable(_readIds);

  // Call once at startup (after Firebase init, before runApp).
  Future<void> init() async {
    await _load();
    _ready = true;
    notifyListeners();
  }

  bool isRead(String id) => _readIds.contains(id);

  // Mark a single update as read. No-op if already read.
  Future<void> markRead(String id) async {
    if (_readIds.add(id)) {
      notifyListeners();
      await _persist();
    }
  }

  // Mark several at once (e.g. "mark all as read").
  Future<void> markAllRead(Iterable<String> ids) async {
    final before = _readIds.length;
    _readIds.addAll(ids);
    if (_readIds.length != before) {
      notifyListeners();
      await _persist();
    }
  }

  // Given the full set of update IDs that currently exist, how many
  // are unread? Used by the nav badge.
  int unreadCountAmong(Iterable<String> allIds) {
    var n = 0;
    for (final id in allIds) {
      if (!_readIds.contains(id)) n++;
    }
    return n;
  }

  // ── Persistence (swap these two to Firestore later) ────────────
  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_prefsKey) ?? const [];
    _readIds
      ..clear()
      ..addAll(list);
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_prefsKey, _readIds.toList());
  }
}
