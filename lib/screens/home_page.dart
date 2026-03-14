import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../services/ad_service.dart';
import '../widgets/unlock_sheet.dart';
import 'application_editor_screen.dart';
import 'mobile_update_editor_screen.dart';
import 'profile_screen.dart';

class HomePage extends StatefulWidget {
  final VoidCallback? onPdfSaved;
  const HomePage({super.key, this.onPdfSaved});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // Template list — each has a unique id for unlock tracking
  static const _templates = <_TemplateItem>[
    _TemplateItem(
      id: 'bima_hatao',
      title: 'अपने बचत खाते से बीमा हटवाने हेतु आवेदन',
      subtitle: 'बैंक शाखा बीमा हटवाने का आवेदन पत्र',
      icon: Icons.account_balance_rounded,
      color: Color(0xFF1565C0),
    ),
    _TemplateItem(
      id: 'mobile_update',
      title: 'बैंक मोबाईल नंबर अपडेट आवेदन',
      subtitle: 'बचत खाते में मोबाइल नंबर परिवर्तन हेतु आवेदन',
      icon: Icons.phone_android_rounded,
      color: Color(0xFF00897B),
    ),
  ];

  // Track which templates are unlocked  (id → bool)
  final Map<String, bool> _unlocked = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadUnlockStates();
  }

  Future<void> _loadUnlockStates() async {
    final ad = AdService.instance;
    for (final t in _templates) {
      _unlocked[t.id] = await ad.isUnlocked(t.id);
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _onTemplateTap(_TemplateItem t) async {
    if (_unlocked[t.id] == true) {
      // Already unlocked — open editor
      _openEditor(t.id);
      return;
    }

    // Show unlock sheet
    final unlocked = await showUnlockSheet(
      context: context,
      templateId: t.id,
      templateTitle: t.title,
    );

    if (unlocked) {
      setState(() => _unlocked[t.id] = true);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              '🎉 आवेदन अनलॉक हो गया!',
              style: TextStyle(fontFamily: 'NotoSansDevanagari'),
            ),
            backgroundColor: const Color(0xFF00897B),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            duration: const Duration(seconds: 2),
          ),
        );
        _openEditor(t.id);
      }
    }
  }

  void _openEditor(String templateId) {
    final Widget screen;
    switch (templateId) {
      case 'mobile_update':
        screen = MobileUpdateEditorScreen(onPdfSaved: widget.onPdfSaved);
      default:
        screen = ApplicationEditorScreen(onPdfSaved: widget.onPdfSaved);
    }
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.appTitle),
        actions: [
          IconButton(
            tooltip: 'प्रोफाइल',
            icon: const Icon(Icons.account_circle_rounded),
            onPressed: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const ProfileScreen())),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              itemCount: _templates.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final t = _templates[index];
                final isUnlocked = _unlocked[t.id] == true;
                return _TemplateCard(
                  template: t,
                  isUnlocked: isUnlocked,
                  onTap: () => _onTemplateTap(t),
                );
              },
            ),
    );
  }
}

// ── Data class for template items ──
class _TemplateItem {
  final String id;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;

  const _TemplateItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
  });
}

// ── Template card widget ──
class _TemplateCard extends StatelessWidget {
  final _TemplateItem template;
  final bool isUnlocked;
  final VoidCallback onTap;

  const _TemplateCard({
    required this.template,
    required this.isUnlocked,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      elevation: 1,
      shadowColor: template.color.withValues(alpha: 0.15),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: template.color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(template.icon, color: template.color, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      template.title,
                      style: const TextStyle(
                        fontFamily: 'NotoSansDevanagari',
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF212121),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      template.subtitle,
                      style: const TextStyle(
                        fontFamily: 'NotoSansDevanagari',
                        fontSize: 13,
                        color: Color(0xFF757575),
                      ),
                    ),
                  ],
                ),
              ),
              // Lock / Unlock indicator
              isUnlocked
                  ? const Icon(
                      Icons.chevron_right_rounded,
                      color: Color(0xFFBDBDBD),
                    )
                  : Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.orange.shade200),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.lock_rounded,
                            size: 14,
                            color: Colors.orange.shade700,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'अनलॉक',
                            style: TextStyle(
                              fontFamily: 'NotoSansDevanagari',
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.orange.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
