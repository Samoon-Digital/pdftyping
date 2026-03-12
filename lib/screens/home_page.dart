import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../main.dart';
import 'application_editor_screen.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  void _showLanguageDialog(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(loc.chooseLanguage),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _LanguageTile(
              label: loc.hindi,
              locale: const Locale('hi'),
              flag: '🇮🇳',
            ),
            const SizedBox(height: 8),
            _LanguageTile(
              label: loc.english,
              locale: const Locale('en'),
              flag: '🇬🇧',
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    // Template list data
    final templates = <_TemplateItem>[
      _TemplateItem(
        titleHi: 'अपने बचत खाते से बीमा हटवाने हेतु आवेदन',
        titleEn: loc.template1Title,
        subtitleEn: loc.template1Subtitle,
        icon: Icons.account_balance_rounded,
        color: const Color(0xFF1565C0),
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.appTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.translate_rounded),
            tooltip: loc.language,
            onPressed: () => _showLanguageDialog(context),
          ),
        ],
      ),
      body: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        itemCount: templates.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final t = templates[index];
          return _TemplateCard(
            template: t,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const ApplicationEditorScreen(),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// ── Data class for template items ──
class _TemplateItem {
  final String titleHi;
  final String titleEn;
  final String subtitleEn;
  final IconData icon;
  final Color color;

  const _TemplateItem({
    required this.titleHi,
    required this.titleEn,
    required this.subtitleEn,
    required this.icon,
    required this.color,
  });
}

// ── Template card widget ──
class _TemplateCard extends StatelessWidget {
  final _TemplateItem template;
  final VoidCallback onTap;

  const _TemplateCard({required this.template, required this.onTap});

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
                      template.titleEn,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF212121),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      template.subtitleEn,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF757575),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: Color(0xFFBDBDBD)),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Language tile for dialog ──
class _LanguageTile extends StatelessWidget {
  final String label;
  final Locale locale;
  final String flag;

  const _LanguageTile({
    required this.label,
    required this.locale,
    required this.flag,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Text(flag, style: const TextStyle(fontSize: 24)),
      title: Text(label),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      tileColor: const Color(0xFFF5F7FA),
      onTap: () {
        MainApp.setLocale(context, locale);
        Navigator.of(context).pop();
      },
    );
  }
}

// ── Quick action card ──
class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.08),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 26),
              ),
              const SizedBox(height: 10),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
