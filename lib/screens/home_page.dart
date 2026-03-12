import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import 'application_editor_screen.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    // Template list — title & subtitle hardcoded in Hindi
    final templates = <_TemplateItem>[
      const _TemplateItem(
        title: 'अपने बचत खाते से बीमा हटवाने हेतु आवेदन',
        subtitle: 'बैंक शाखा बीमा हटवाने का आवेदन पत्र',
        icon: Icons.account_balance_rounded,
        color: Color(0xFF1565C0),
      ),
    ];

    return Scaffold(
      appBar: AppBar(title: Text(loc.appTitle)),
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
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;

  const _TemplateItem({
    required this.title,
    required this.subtitle,
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
              const Icon(Icons.chevron_right_rounded, color: Color(0xFFBDBDBD)),
            ],
          ),
        ),
      ),
    );
  }
}
