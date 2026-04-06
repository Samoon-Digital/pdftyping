import 'package:flutter/material.dart';
import '../services/suggestions_service.dart';

/// A text form field that shows saved suggestions as tappable chips
/// below the field when it gains focus. Suggestions are persisted via
/// [SuggestionsService] and keyed by [fieldKey].
///
/// For read-only fields (e.g. date pickers) pass [readOnly] = true —
/// suggestions are disabled and the field behaves identically to a
/// plain _InputField.
class SuggestibleInputField extends StatefulWidget {
  final TextEditingController controller;
  final String fieldKey; // unique key for persistence
  final String label;
  final String hint;
  final TextInputType keyboardType;
  final ValueChanged<String>? onChanged;
  final bool readOnly;
  final bool enableSuggestions;
  final VoidCallback? onTap;
  final Widget? suffixIcon;
  final String? Function(String?)? validator;

  const SuggestibleInputField({
    super.key,
    required this.controller,
    required this.fieldKey,
    required this.label,
    required this.hint,
    this.keyboardType = TextInputType.text,
    this.onChanged,
    this.readOnly = false,
    this.enableSuggestions = true,
    this.onTap,
    this.suffixIcon,
    this.validator,
  });

  @override
  State<SuggestibleInputField> createState() => _SuggestibleInputFieldState();
}

class _SuggestibleInputFieldState extends State<SuggestibleInputField> {
  final _focusNode = FocusNode();
  List<String> _suggestions = [];
  bool _showSuggestions = false;
  // On web, mousedown removes focus before onPressed fires, hiding chips from
  // the tree before the tap completes. This flag suppresses that hide.
  bool _suppressFocusHide = false;

  @override
  void initState() {
    super.initState();
    if (!widget.enableSuggestions) {
      _focusNode.addListener(() {
        if (!_focusNode.hasFocus && _showSuggestions) {
          setState(() => _showSuggestions = false);
        }
      });
      return;
    }

    // Initialise service (no-op if already done)
    SuggestionsService.instance.init().then((_) {
      if (mounted) {
        setState(() {
          _suggestions = SuggestionsService.instance.getSuggestions(
            widget.fieldKey,
          );
        });
      }
    });

    _focusNode.addListener(() {
      if (_focusNode.hasFocus && !widget.readOnly) {
        _refresh();
        setState(() => _showSuggestions = true);
      } else {
        if (_suppressFocusHide) return; // chip tap in progress — don't hide
        setState(() => _showSuggestions = false);
        // Save value when field loses focus
        _save();
      }
    });
  }

  void _refresh() {
    setState(() {
      _suggestions = SuggestionsService.instance.getSuggestions(
        widget.fieldKey,
      );
    });
  }

  Future<void> _save() async {
    final v = widget.controller.text.trim();
    if (v.isNotEmpty) {
      await SuggestionsService.instance.addSuggestion(widget.fieldKey, v);
    }
  }

  void _applySuggestion(String value) {
    _suppressFocusHide = false;
    widget.controller.text = value;
    widget.controller.selection = TextSelection.collapsed(offset: value.length);
    widget.onChanged?.call(value);
    setState(() => _showSuggestions = false);
  }

  Future<void> _deleteSuggestion(String value) async {
    _suppressFocusHide = false;
    await SuggestionsService.instance.removeSuggestion(widget.fieldKey, value);
    _refresh();
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final showChips =
        widget.enableSuggestions &&
        _showSuggestions &&
        !widget.readOnly &&
        _suggestions.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            controller: widget.controller,
            focusNode: _focusNode,
            keyboardType: widget.keyboardType,
            readOnly: widget.readOnly,
            onTap: widget.onTap,
            onChanged: (v) {
              widget.onChanged?.call(v);
            },
            style: const TextStyle(
              fontFamily: 'NotoSansDevanagari',
              fontSize: 16,
            ),
            decoration: InputDecoration(
              labelText: widget.label,
              hintText: widget.hint,
              labelStyle: const TextStyle(fontFamily: 'NotoSansDevanagari'),
              hintStyle: TextStyle(
                fontFamily: 'NotoSansDevanagari',
                color: Colors.grey.shade400,
              ),
              suffixIcon: widget.suffixIcon == null
                  ? null
                  : GestureDetector(
                      onTap: widget.onTap,
                      child: widget.suffixIcon,
                    ),
            ),
            validator:
                widget.validator ??
                (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'कृपया सभी फ़ील्ड भरें';
                  }
                  return null;
                },
          ),

          // ── Suggestion chips ──
          if (showChips)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Wrap(
                spacing: 8,
                runSpacing: 4,
                children: _suggestions.map((s) {
                  return Listener(
                    // Capture pointer-down BEFORE focus leaves the text field.
                    // On web, mousedown fires first → focus lost → chips hidden
                    // → onPressed never fires.  Setting the flag here prevents
                    // the focus listener from collapsing the chip list.
                    onPointerDown: (_) =>
                        setState(() => _suppressFocusHide = true),
                    child: GestureDetector(
                      onLongPress: () => _deleteSuggestion(s),
                      child: ActionChip(
                        label: Text(
                          s,
                          style: const TextStyle(
                            fontFamily: 'NotoSansDevanagari',
                            fontSize: 13,
                          ),
                        ),
                        backgroundColor: const Color(0xFFE3F2FD),
                        side: const BorderSide(color: Color(0xFF90CAF9)),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 0,
                        ),
                        onPressed: () => _applySuggestion(s),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }
}
