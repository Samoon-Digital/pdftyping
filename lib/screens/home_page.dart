import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import 'aadhar_seeding_editor_screen.dart';
import 'application_editor_screen.dart';
import 'asha_editor_screen.dart';
import 'asha_janm_editor_screen.dart';
import 'custom_layout_one_editor_screen.dart';
import 'death_grameen_editor_screen.dart';
import 'mobile_update_editor_screen.dart';
import 'parmaan_patr_editor_screen.dart';
import 'shahri_sabhashad_editor_screen.dart';
import 'sabhashad_mrityu_editor_screen.dart';
import 'profile_screen.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/update_service.dart';

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
      title: 'आशा द्वारा प्रमाणित मृत्यु प्रमाण पत्र - ग्रामीण',
      subtitle: 'आशा प्रमाणित मृत्यु प्रमाण पत्र प्रारूप',
      icon: Icons.local_hospital_rounded,
      color: Color(0xFF00838F),
    ),
    _TemplateItem(
      id: 'sabhashad_mrityu',
      title: 'सभासद द्वारा प्रमाणित मृत्यु प्रमाण पत्र - शहरी',
      subtitle: 'शहरी क्षेत्र का सभासद प्रमाणित मृत्यु प्रमाण पत्र',
      icon: Icons.location_city_rounded,
      color: Color(0xFF37474F),
    ),
    _TemplateItem(
      id: 'asha_janm_cert',
      title: 'आशा द्वारा प्रमाणित जन्म प्रमाण पत्र - ग्रामीण',
      subtitle: 'आशा प्रमाणित जन्म प्रमाण पत्र प्रारूप',
      icon: Icons.child_care_rounded,
      color: Color(0xFF2E7D32),
    ),
    _TemplateItem(
      id: 'parmaan_patr',
      title: 'प्रधान द्वारा प्रमाणित प्रमाण पत्र',
      subtitle: 'आय / जाति / निवास प्रमाण पत्र (फोटो सहित)',
      icon: Icons.verified_user_rounded,
      color: Color(0xFFC62828),
    ),
    _TemplateItem(
      id: 'shahri_sabhashad',
      title: 'सभासद द्वारा प्रमाणित प्रमाण पत्र',
      subtitle: 'शहरी क्षेत्र का आय / जाति / निवास प्रमाण पत्र',
      icon: Icons.location_city_rounded,
      color: Color(0xFF6A1B9A),
    ),
    _TemplateItem(
      id: 'aadhar_seeding',
      title: 'आधार सीडिंग कराने हेतु आवेदन',
      subtitle: 'बैंक खाते से आधार संख्या लिंक (सीडिंग) कराने का आवेदन',
      icon: Icons.fingerprint_rounded,
      color: Color(0xFF00897B),
    ),
  ];

  static const _categories = <_CategorySection>[
    _CategorySection(
      id: 'identity',
      title: 'जाति • आय • निवास',
      subtitle: 'प्रमाणित पत्र और सत्यापन प्रारूप',
      icon: Icons.verified_user_rounded,
      itemIds: ['parmaan_patr', 'shahri_sabhashad'],
    ),
    _CategorySection(
      id: 'birth_death',
      title: 'जन्म / मृत्यु प्रमाण पत्र',
      subtitle: 'ग्रामीण प्रमाणन से जुड़े आवेदन प्रारूप',
      icon: Icons.fact_check_rounded,
      itemIds: [
        'asha_janm',
        'sabhashad_mrityu',
        'asha_janm_cert',
        'death_grameen',
      ],
    ),
    _CategorySection(
      id: 'banking',
      title: 'बैंकिंग',
      subtitle: 'खाते और सेवा अपडेट आवेदन',
      icon: Icons.account_balance_rounded,
      itemIds: ['bima_hatao', 'mobile_update', 'aadhar_seeding'],
    ),
  ];

  String _selectedLayoutId = _layoutOptions.first.id;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _maybeAskNotificationPermission();
      UpdateService.checkForUpdate();
    });
  }

  Future<void> _maybeAskNotificationPermission() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final seenBefore = prefs.getBool('home_seen_before') ?? false;
      if (!seenBefore) {
        await prefs.setBool('home_seen_before', true);
        return; // first visit — do not prompt
      }
      final alreadyPrompted =
          prefs.getBool('notifications_prompt_shown') ?? false;
      if (alreadyPrompted) return;

      final settings = await FirebaseMessaging.instance
          .getNotificationSettings();
      if (settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional) {
        await prefs.setBool('notifications_prompt_shown', true);
        return; // already allowed
      }

      if (!mounted) return;
      final allow = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('सूचना अनुमति'),
          content: const Text(
            'हम महत्वपूर्ण सूचनाएं भेजने के लिए अनुमति चाहते हैं। क्या आप अनुमति देंगे?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('बाद में करें'),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('अनुमति दें'),
            ),
          ],
        ),
      );

      await prefs.setBool('notifications_prompt_shown', true);
      if (allow == true) {
        final perm = await FirebaseMessaging.instance.requestPermission(
          alert: true,
          badge: true,
          sound: true,
          provisional: false,
        );
        await FirebaseAnalytics.instance.logEvent(
          name: 'notification_permission',
          parameters: {'status': perm.authorizationStatus.toString()},
        );
        final token = await FirebaseMessaging.instance.getToken();
        if (kDebugMode) print('FCM token (after permission): $token');
      }
    } catch (_) {
      // ignore errors — don't block the UI
    }
  }

  void _onTemplateTap(_TemplateItem t) => _openEditor(t.id, t.title);

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
      _openCustomLayout(selected);
    }
  }

  void _openCustomLayout(String layoutId) {
    if (layoutId == 'classic') {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) =>
              CustomLayoutOneEditorScreen(onPdfSaved: widget.onPdfSaved),
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'यह layout editor अभी अगली update में आएगा।',
          style: TextStyle(fontFamily: 'NotoSansDevanagari'),
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _openCategory(_CategorySection category, List<_TemplateItem> items) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _CategoryTemplatesScreen(
          category: category,
          items: items,
          onItemTap: _onTemplateTap,
        ),
      ),
    );
  }

  void _openEditor(String templateId, String templateTitle) {
    final Widget screen;
    if (templateId == 'mobile_update') {
      screen = MobileUpdateEditorScreen(
        onPdfSaved: widget.onPdfSaved,
        editorTitle: templateTitle,
      );
    } else if (templateId == 'death_grameen') {
      screen = DeathGrameenEditorScreen(
        onPdfSaved: widget.onPdfSaved,
        editorTitle: templateTitle,
      );
    } else if (templateId == 'asha_janm') {
      screen = AshaEditorScreen(
        onPdfSaved: widget.onPdfSaved,
        editorTitle: templateTitle,
      );
    } else if (templateId == 'sabhashad_mrityu') {
      screen = SabhashadMrityuEditorScreen(
        onPdfSaved: widget.onPdfSaved,
        editorTitle: templateTitle,
      );
    } else if (templateId == 'asha_janm_cert') {
      screen = AshaJanmEditorScreen(
        onPdfSaved: widget.onPdfSaved,
        editorTitle: templateTitle,
      );
    } else if (templateId == 'parmaan_patr') {
      screen = ParmaanPatrEditorScreen(
        onPdfSaved: widget.onPdfSaved,
        editorTitle: templateTitle,
      );
    } else if (templateId == 'shahri_sabhashad') {
      screen = ShahriSabhashadEditorScreen(
        onPdfSaved: widget.onPdfSaved,
        editorTitle: templateTitle,
      );
    } else if (templateId == 'aadhar_seeding') {
      screen = AadharSeedingEditorScreen(
        onPdfSaved: widget.onPdfSaved,
        editorTitle: templateTitle,
      );
    } else {
      screen = ApplicationEditorScreen(
        onPdfSaved: widget.onPdfSaved,
        editorTitle: templateTitle,
      );
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
      body: CustomScrollView(
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
  // ID of item after which a शहरी/ग्रामीण divider is inserted
  final String? dividerAfterItemId;

  const _CategorySection({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.itemIds,
    this.dividerAfterItemId,
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
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(10),
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
                        horizontal: 9,
                        vertical: 5,
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
                const SizedBox(height: 10),
                const Text(
                  'कस्टम आवेदन लिखें',
                  style: TextStyle(
                    fontFamily: 'NotoSansDevanagari',
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    height: 1.2,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'यहाँ से खाली लेआउट चुनकर आगे मनमुताबिक आवेदन लिखा जा सकेगा।',
                  style: TextStyle(
                    fontFamily: 'NotoSansDevanagari',
                    fontSize: 12,
                    height: 1.35,
                    color: Color(0xFFEFF6FF),
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: const Text(
                    'अपना बेस लेआउट चुनें',
                    style: TextStyle(
                      fontFamily: 'NotoSansDevanagari',
                      fontSize: 14,
                      color: Color(0xFFEFF6FF),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'टैप करें और बेस लेआउट चुनें',
                        style: TextStyle(
                          fontFamily: 'NotoSansDevanagari',
                          fontSize: 12,
                          color: Color(0xFFE2E8F0),
                        ),
                      ),
                    ),
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.arrow_forward_rounded,
                        color: selectedLayout.accent,
                        size: 18,
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
      height: 54,
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
      ),
      child: Column(
        children: [
          Container(
            height: 5,
            decoration: BoxDecoration(
              color: lineColor,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          const SizedBox(height: 4),
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
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: background.withValues(alpha: 0.8),
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(6),
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
  final ValueChanged<_TemplateItem> onItemTap;

  const _CategoryTemplatesScreen({
    required this.category,
    required this.items,
    required this.onItemTap,
  });

  @override
  Widget build(BuildContext context) {
    final dividerIdx = category.dividerAfterItemId != null
        ? items.indexWhere((t) => t.id == category.dividerAfterItemId)
        : -1;

    final rows = <Widget>[];

    // Subtitle card
    rows.add(
      Container(
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
      ),
    );

    for (int i = 0; i < items.length; i++) {
      // Section label before first shahri item
      if (dividerIdx >= 0 && i == 0) {
        rows.add(const SizedBox(height: 16));
        rows.add(_buildSectionLabel('शहरी'));
        rows.add(const SizedBox(height: 6));
      } else {
        rows.add(const SizedBox(height: 12));
      }

      // Divider + grameen label before grameen group
      if (dividerIdx >= 0 && i == dividerIdx + 1) {
        rows.add(_buildDividerRow('ग्रामीण'));
        rows.add(const SizedBox(height: 6));
      }

      rows.add(
        _TemplateListTile(template: items[i], onTap: () => onItemTap(items[i])),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(category.title)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: rows,
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        label,
        style: const TextStyle(
          fontFamily: 'NotoSansDevanagari',
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Color(0xFF6B7280),
          letterSpacing: 0.4,
        ),
      ),
    );
  }

  Widget _buildDividerRow(String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          const Expanded(
            child: Divider(thickness: 1, color: Color(0xFFE5E7EB)),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Text(
              label,
              style: const TextStyle(
                fontFamily: 'NotoSansDevanagari',
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF6B7280),
              ),
            ),
          ),
          const Expanded(
            child: Divider(thickness: 1, color: Color(0xFFE5E7EB)),
          ),
        ],
      ),
    );
  }
}

class _TemplateListTile extends StatelessWidget {
  final _TemplateItem template;
  final VoidCallback onTap;

  const _TemplateListTile({required this.template, required this.onTap});

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
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: template.color.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(Icons.chevron_right_rounded, color: template.color),
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
