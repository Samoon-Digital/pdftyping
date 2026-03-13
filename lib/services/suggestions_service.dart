import 'package:shared_preferences/shared_preferences.dart';

/// Persists per-field suggestion history using SharedPreferences.
/// Each field is identified by a unique [fieldKey].
/// At most [maxItems] suggestions are stored per field (newest first).
class SuggestionsService {
  SuggestionsService._();
  static final SuggestionsService instance = SuggestionsService._();

  static const int maxItems = 8;
  static const String _prefix = 'suggestions_';

  SharedPreferences? _prefs;

  Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  List<String> getSuggestions(String fieldKey) {
    return _prefs?.getStringList('$_prefix$fieldKey') ?? [];
  }

  Future<void> addSuggestion(String fieldKey, String value) async {
    final v = value.trim();
    if (v.isEmpty) return;
    await init();
    final list = getSuggestions(fieldKey);
    list.remove(v); // remove duplicate
    list.insert(0, v); // newest first
    if (list.length > maxItems) list.removeLast();
    await _prefs!.setStringList('$_prefix$fieldKey', list);
  }

  Future<void> removeSuggestion(String fieldKey, String value) async {
    await init();
    final list = getSuggestions(fieldKey);
    list.remove(value);
    await _prefs!.setStringList('$_prefix$fieldKey', list);
  }
}
