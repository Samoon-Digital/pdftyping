import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../services/ad_service.dart';
import '../widgets/unlock_sheet.dart';
import 'application_editor_screen.dart';
import 'asha_editor_screen.dart';
import 'death_grameen_editor_screen.dart';
import 'mobile_update_editor_screen.dart';
import 'parmaan_patr_editor_screen.dart';
import 'profile_screen.dart';

class HomePage extends StatefulWidget {
  final VoidCallback? onPdfSaved;
  const HomePage({super.key, this.onPdfSaved});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static const _layoutOptions = <_LayoutOption>[
    _LayoutOption(id: 'classic', title: 'लेआउट 01', accent: Color(0xFF0F766E)),
    _LayoutOption(id: 'formal', title: 'लेआउट 02', accent: Color(0xFF2563EB)),
    _LayoutOption(id: 'modern', title: 'लेआउट 03', accent: Color(0xFFDC2626)),
    _LayoutOption(id: 'minimal', title: 'लेआउट 04', accent: Color(0xFF7C3AED)),
  ];

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
    _TemplateItem(
      id: 'death_grameen',
      title: 'ग्राम प्रधान द्वारा प्रमाणित मृत्यु प्रमाण पत्र',
      subtitle: 'ग्रामीण क्षेत्र का मृत्यु प्रमाण पत्र',
      icon: Icons.description_rounded,
      color: Color(0xFF6A1B9A),
    ),
    _TemplateItem(
      id: 'asha_janm',
      title: 'ग्राम पंचायत आशा द्वारा प्रमाणित मृत्यु प्रमाण पत्र',
      subtitle: 'आशा प्रमाणन श्रेणी का प्रमाण पत्र',
      icon: Icons.child_care_rounded,
      color: Color(0xFF00838F),
    ),
    _TemplateItem(
      id: 'parmaan_patr',
      title: 'प्रधान द्वारा प्रमाणित प्रमाण पत्र',
      subtitle: 'आय / जाति / निवास प्रमाण पत्र (फोटो सहित)',
      icon: Icons.verified_user_rounded,
      color: Color(0xFFC62828),
    ),
  ];

  static const _categories = <_CategorySection>[
    _CategorySection(
      id: 'identity',
      title: 'जाति • आय • निवास',
      subtitle: 'प्रमाणित पत्र और सत्यापन प्रारूप',
      icon: Icons.verified_user_rounded,
      itemIds: ['parmaan_patr'],
    ),
    _CategorySection(
      id: 'birth_death',
      title: 'जन्म / मृत्यु प्रमाण पत्र',
      subtitle: 'ग्रामीण प्रमाणन से जुड़े आवेदन प्रारूप',
      icon: Icons.fact_check_rounded,
      itemIds: ['asha_janm', 'death_grameen'],
    ),
    _CategorySection(
      id: 'banking',
      title: 'बैंकिंग',
      subtitle: 'खाते और सेवा अपडेट आवेदन',
      icon: Icons.account_balance_rounded,
      itemIds: ['bima_hatao', 'mobile_update'],
    ),
  ];

  // Track which templates are unlocked  (id → bool)
  final Map<String, bool> _unlocked = {};
  bool _loading = true;
  String _selectedLayoutId = _layoutOptions.first.id;

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
    if (kIsWeb || _unlocked[t.id] == true) {
      // Web: all templates free | Mobile: already unlocked
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

  Future<void> _showLayoutPicker() async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _LayoutPickerSheet(
        options: _layoutOptions,
        selectedLayoutId: _selectedLayoutId,
      ),
    );

    if (selected != null && mounted) {
      setState(() => _selectedLayoutId = selected);
    }
  }

  void _openCategory(_CategorySection category, List<_TemplateItem> items) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _CategoryTemplatesScreen(
          category: category,
          items: items,
          unlocked: _unlocked,
          onItemTap: _onTemplateTap,
        ),
      ),
    );
  }

  void _openEditor(String templateId) {
    final Widget screen;
    switch (templateId) {
      case 'mobile_update':
        screen = MobileUpdateEditorScreen(onPdfSaved: widget.onPdfSaved);
      case 'death_grameen':
        screen = DeathGrameenEditorScreen(onPdfSaved: widget.onPdfSaved);
      case 'asha_janm':
        screen = AshaEditorScreen(onPdfSaved: widget.onPdfSaved);
      case 'parmaan_patr':
        screen = ParmaanPatrEditorScreen(onPdfSaved: widget.onPdfSaved);
      default:
        screen = ApplicationEditorScreen(onPdfSaved: widget.onPdfSaved);
    }
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final templateMap = {
      for (final template in _templates) template.id: template,
    };
    final selectedLayout = _layoutOptions.firstWhere(
      (layout) => layout.id == _selectedLayoutId,
    );

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
          : CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _DashboardHeroCard(
                          selectedLayout: selectedLayout,
                          onTap: _showLayoutPicker,
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'श्रेणियाँ',
                          style: TextStyle(
                            fontFamily: 'NotoSansDevanagari',
                            fontSize: 21,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF111827),
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'किसी श्रेणी पर टैप करें। अगले पेज पर उसकी पूरी सूची खुलेगी और फिर वहाँ से संबंधित एडिटर खोला जा सकेगा।',
                          style: TextStyle(
                            fontFamily: 'NotoSansDevanagari',
                            fontSize: 13,
                            height: 1.45,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                        const SizedBox(height: 16),
                        for (final category in _categories) ...[
                          _CategoryCard(
                            category: category,
                            itemCount: category.itemIds.length,
                            onTap: () => _openCategory(category, [
                              for (final itemId in category.itemIds)
                                templateMap[itemId]!,
                            ]),
                          ),
                          const SizedBox(height: 14),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

class _LayoutOption {
  final String id;
  final String title;
  final Color accent;

  const _LayoutOption({
    required this.id,
    required this.title,
    required this.accent,
  });
}

class _CategorySection {
  final String id;
  final String title;
  final String subtitle;
  final IconData icon;
  final List<String> itemIds;

  const _CategorySection({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.itemIds,
  });
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

class _DashboardHeroCard extends StatelessWidget {
  final _LayoutOption selectedLayout;
  final VoidCallback onTap;

  const _DashboardHeroCard({required this.selectedLayout, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final primaryContainer = theme.colorScheme.primaryContainer;
    final onPrimaryContainer = theme.colorScheme.onPrimaryContainer;

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            primary,
            Color.alphaBlend(Colors.white.withValues(alpha: 0.12), primary),
          ],
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: primary.withValues(alpha: 0.18),
            blurRadius: 24,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.22),
                        ),
                      ),
                      child: const Icon(
                        Icons.auto_awesome_mosaic_rounded,
                        color: Colors.white,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        selectedLayout.title,
                        style: const TextStyle(
                          fontFamily: 'NotoSansDevanagari',
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                const Text(
                  'कस्टम आवेदन लिखें',
                  style: TextStyle(
                    fontFamily: 'NotoSansDevanagari',
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    height: 1.2,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'यहाँ से अपनी जरूरत के हिसाब से खाली लेआउट चुनकर आगे मनमुताबिक आवेदन लिखा जा सकेगा। अभी 4 प्री-डिफाइन लेआउट प्रीव्यू उपलब्ध हैं।',
                  style: TextStyle(
                    fontFamily: 'NotoSansDevanagari',
                    fontSize: 13,
                    height: 1.45,
                    color: Color(0xFFEFF6FF),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: List.generate(
                    4,
                    (index) => Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(right: index == 3 ? 0 : 10),
                        child: _HeroLayoutPreview(
                          background: primaryContainer,
                          lineColor: onPrimaryContainer.withValues(alpha: 0.85),
                          accent: index == 0
                              ? primaryContainer
                              : index == 1
                              ? primaryContainer.withValues(alpha: 0.92)
                              : index == 2
                              ? primaryContainer.withValues(alpha: 0.84)
                              : primaryContainer.withValues(alpha: 0.76),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'टैप करें और अपने आवेदन का बेस लेआउट चुनें',
                        style: TextStyle(
                          fontFamily: 'NotoSansDevanagari',
                          fontSize: 13,
                          color: Color(0xFFE2E8F0),
                        ),
                      ),
                    ),
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.arrow_forward_rounded,
                        color: selectedLayout.accent,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HeroLayoutPreview extends StatelessWidget {
  final Color accent;
  final Color background;
  final Color lineColor;

  const _HeroLayoutPreview({
    required this.accent,
    required this.background,
    required this.lineColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 68,
      padding: const EdgeInsets.all(7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
      ),
      child: Column(
        children: [
          Container(
            height: 6,
            decoration: BoxDecoration(
              color: lineColor,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          const SizedBox(height: 6),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Column(
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: background,
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                      const SizedBox(height: 5),
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: background.withValues(alpha: 0.8),
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 5),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final _CategorySection category;
  final int itemCount;
  final VoidCallback onTap;

  const _CategoryCard({
    required this.category,
    required this.itemCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: primary.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(category.icon, color: primary, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        category.title,
                        style: const TextStyle(
                          fontFamily: 'NotoSansDevanagari',
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF111827),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        category.subtitle,
                        style: const TextStyle(
                          fontFamily: 'NotoSansDevanagari',
                          fontSize: 12,
                          height: 1.4,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        '$itemCount सूची',
                        style: const TextStyle(
                          fontFamily: 'NotoSansDevanagari',
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF475569),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      color: primary.withValues(alpha: 0.8),
                      size: 16,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CategoryTemplatesScreen extends StatelessWidget {
  final _CategorySection category;
  final List<_TemplateItem> items;
  final Map<String, bool> unlocked;
  final ValueChanged<_TemplateItem> onItemTap;

  const _CategoryTemplatesScreen({
    required this.category,
    required this.items,
    required this.unlocked,
    required this.onItemTap,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(category.title)),
      body: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        itemCount: items.length + 1,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          if (index == 0) {
            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Text(
                category.subtitle,
                style: const TextStyle(
                  fontFamily: 'NotoSansDevanagari',
                  fontSize: 13,
                  height: 1.45,
                  color: Color(0xFF64748B),
                ),
              ),
            );
          }

          final template = items[index - 1];
          return _TemplateListTile(
            template: template,
            isUnlocked: unlocked[template.id] == true,
            onTap: () => onItemTap(template),
          );
        },
      ),
    );
  }
}

class _TemplateListTile extends StatelessWidget {
  final _TemplateItem template;
  final bool isUnlocked;
  final VoidCallback onTap;

  const _TemplateListTile({
    required this.template,
    required this.isUnlocked,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFF8FAFC),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      template.color.withValues(alpha: 0.18),
                      template.color.withValues(alpha: 0.08),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
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
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF111827),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      template.subtitle,
                      style: const TextStyle(
                        fontFamily: 'NotoSansDevanagari',
                        fontSize: 12,
                        height: 1.4,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              ),
              isUnlocked
                  ? Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: template.color.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        Icons.chevron_right_rounded,
                        color: template.color,
                      ),
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

class _LayoutPickerSheet extends StatelessWidget {
  final List<_LayoutOption> options;
  final String selectedLayoutId;

  const _LayoutPickerSheet({
    required this.options,
    required this.selectedLayoutId,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFF8FAFC),
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 46,
                  height: 5,
                  decoration: BoxDecoration(
                    color: const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'लेआउट चुनें',
                style: TextStyle(
                  fontFamily: 'NotoSansDevanagari',
                  fontSize: 21,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF111827),
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'इन 4 प्रीव्यू में अभी कोई टेक्स्ट नहीं है। आगे यही चयन मल्टीस्टेप आवेदन फॉर्म में इस्तेमाल होगा।',
                style: TextStyle(
                  fontFamily: 'NotoSansDevanagari',
                  fontSize: 13,
                  height: 1.45,
                  color: Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 18),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: options.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 14,
                  crossAxisSpacing: 14,
                  childAspectRatio: 0.92,
                ),
                itemBuilder: (context, index) {
                  final option = options[index];
                  final isSelected = option.id == selectedLayoutId;
                  return _LayoutOptionCard(
                    option: option,
                    isSelected: isSelected,
                    onTap: () => Navigator.of(context).pop(option.id),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LayoutOptionCard extends StatelessWidget {
  final _LayoutOption option;
  final bool isSelected;
  final VoidCallback onTap;

  const _LayoutOptionCard({
    required this.option,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isSelected ? option.accent : const Color(0xFFE2E8F0),
              width: isSelected ? 1.8 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: option.accent.withValues(
                  alpha: isSelected ? 0.14 : 0.06,
                ),
                blurRadius: 18,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: option.accent,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const Spacer(),
                  if (isSelected)
                    Icon(
                      Icons.check_circle_rounded,
                      color: option.accent,
                      size: 20,
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: option.accent.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      Container(
                        height: 10,
                        decoration: BoxDecoration(
                          color: option.accent,
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Expanded(
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                children: [
                                  Expanded(
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Expanded(
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(
                                          alpha: 0.82,
                                        ),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.9),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                option.title,
                style: const TextStyle(
                  fontFamily: 'NotoSansDevanagari',
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0F172A),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
