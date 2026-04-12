import 'package:flutter/foundation.dart' show kDebugMode, kIsWeb;
import '../widgets/web_a4_layout.dart';
import 'package:flutter/material.dart';
import 'aadhar_seeding_editor_screen.dart';
import 'application_editor_screen.dart';
import 'asha_editor_screen.dart';
import 'asha_janm_editor_screen.dart';
import 'death_grameen_editor_screen.dart';
import 'mobile_update_editor_screen.dart';
import 'mayke_ki_jati_gram_pradhan_editor_screen.dart';
import 'parmaan_patr_editor_screen.dart';
import 'shahri_sabhashad_editor_screen.dart';
import 'sabhashad_mrityu_editor_screen.dart';
import 'profile_screen.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/update_service.dart';
import '../services/ad_service.dart';

class HomePage extends StatefulWidget {
  final VoidCallback? onPdfSaved;
  const HomePage({super.key, this.onPdfSaved});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static const _appShareUrl =
      'https://play.google.com/store/apps/details?id=com.samoondigital.pdftyping';

  static const _webFaqs = <_FaqItem>[
    _FaqItem(
      question: 'PDF Typing क्या है?',
      answer:
          'PDFTyping.in पर आप हिंदी सरकारी आवेदन पत्र और प्रमाण पत्र ऑनलाइन भरकर A4 PDF डाउनलोड कर सकते हैं।',
    ),
    _FaqItem(
      question: 'क्या यह सेवा मुफ्त है?',
      answer: 'हाँ, वेबसाइट पर फॉर्म भरना और PDF डाउनलोड करना मुफ्त है।',
    ),
    _FaqItem(
      question: 'कौन-कौन से फॉर्म उपलब्ध हैं?',
      answer:
          'जाति, आय, निवास, जन्म, मृत्यु, बैंक आवेदन और अन्य ग्रामीण/शहरी प्रमाणन फॉर्म उपलब्ध हैं।',
    ),
    _FaqItem(
      question: 'क्या PDF सीधे प्रिंट हो सकती है?',
      answer:
          'हाँ, डाउनलोड की गई PDF A4 फॉर्मेट में होती है और सीधे प्रिंट की जा सकती है।',
    ),
    _FaqItem(
      question: 'मोबाइल पर बेहतर अनुभव कैसे मिलेगा?',
      answer:
          'Android यूजर Play Store से PDF Typing ऐप डाउनलोड करके तेज और बेहतर अनुभव पा सकते हैं।',
    ),
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
      id: 'mayke_ki_jati_gram_pradhan',
      title: 'प्रधान द्वारा प्रमाणित मायके का जाति प्रमाण पत्र',
      subtitle: 'विवाहित महिला के मायके का जाति प्रमाण पत्र',
      icon: Icons.badge_rounded,
      color: Color(0xFFAD1457),
    ),
    _TemplateItem(
      id: 'mayke_ki_jati_adhyaksh',
      title: 'अध्यक्ष द्वारा प्रमाणित मायके का जाति प्रमाण पत्र',
      subtitle: 'विवाहित महिला के मायके का जाति प्रमाण पत्र',
      icon: Icons.badge_rounded,
      color: Color(0xFFAD1457),
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
      itemIds: [
        'shahri_sabhashad',
        'mayke_ki_jati_adhyaksh',
        'parmaan_patr',
        'mayke_ki_jati_gram_pradhan',
      ],
      dividerAfterItemId: 'mayke_ki_jati_adhyaksh',
    ),
    _CategorySection(
      id: 'birth_death',
      title: 'जन्म / मृत्यु प्रमाण पत्र',
      subtitle: 'ग्रामीण प्रमाणन से जुड़े आवेदन प्रारूप',
      icon: Icons.fact_check_rounded,
      itemIds: [
        'sabhashad_mrityu',
        'asha_janm',
        'asha_janm_cert',
        'death_grameen',
      ],
      dividerAfterItemId: 'sabhashad_mrityu',
    ),
    _CategorySection(
      id: 'banking',
      title: 'बैंकिंग',
      subtitle: 'खाते और सेवा अपडेट आवेदन',
      icon: Icons.account_balance_rounded,
      itemIds: ['bima_hatao', 'mobile_update', 'aadhar_seeding'],
    ),
  ];

  @override
  void initState() {
    super.initState();
    if (!kIsWeb) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _maybeAskNotificationPermission();
        UpdateService.checkForUpdate();
      });
    }
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

  Future<void> _shareApp() async {
    try {
      await SharePlus.instance.share(
        ShareParams(
          subject: 'PDF Typing',
          text: 'PDF Typing app download karein:\n$_appShareUrl',
        ),
      );
    } catch (_) {
      // Ignore share errors to keep home flow uninterrupted.
    }
  }

  void _onTemplateTap(_TemplateItem t) => _openEditor(t.id, t.title);

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
    AdService.instance.onNavigatedAway();
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
    } else if (templateId == 'mayke_ki_jati_gram_pradhan' ||
        templateId == 'mayke_ki_jati_adhyaksh') {
      screen = MaykeKiJatiGramPradhanEditorScreen(
        onPdfSaved: widget.onPdfSaved,
        editorTitle: templateTitle,
        certifierLabel: templateId == 'mayke_ki_jati_adhyaksh'
            ? 'अध्यक्ष'
            : 'प्रधान',
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
    final templateMap = {
      for (final template in _templates) template.id: template,
    };

    return Scaffold(
      appBar: AppBar(
        title: const Text('PDF Typing'),
        actions: [
          IconButton(
            tooltip: 'Share App',
            icon: const Icon(Icons.share_rounded),
            onPressed: _shareApp,
          ),
          IconButton(
            tooltip: 'प्रोफाइल',
            icon: const Icon(Icons.account_circle_rounded),
            onPressed: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const ProfileScreen())),
          ),
        ],
      ),
      body: WebA4Layout(
        child: CustomScrollView(
          physics: const ClampingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
                    if (kIsWeb) ...[
                      const SizedBox(height: 18),
                      _FaqSection(items: _webFaqs),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
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

class _FaqItem {
  final String question;
  final String answer;

  const _FaqItem({required this.question, required this.answer});
}

class _FaqSection extends StatelessWidget {
  final List<_FaqItem> items;

  const _FaqSection({required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(6, 2, 6, 10),
              child: Text(
                'FAQs',
                style: TextStyle(
                  fontFamily: 'NotoSansDevanagari',
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF111827),
                ),
              ),
            ),
            for (final faq in items)
              ExpansionTile(
                tilePadding: const EdgeInsets.symmetric(horizontal: 8),
                childrenPadding: const EdgeInsets.fromLTRB(8, 0, 8, 10),
                dense: true,
                iconColor: const Color(0xFF1565C0),
                collapsedIconColor: const Color(0xFF64748B),
                title: Text(
                  faq.question,
                  style: const TextStyle(
                    fontFamily: 'NotoSansDevanagari',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1F2937),
                  ),
                ),
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      faq.answer,
                      style: const TextStyle(
                        fontFamily: 'NotoSansDevanagari',
                        fontSize: 13,
                        height: 1.45,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
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

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
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
            ],
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
      body: WebA4Layout(
        child: ListView(
          physics: const ClampingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          children: rows,
        ),
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
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(20),
        ),
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
              const SizedBox(width: 12),
            ],
          ),
        ),
      ),
    );
  }
}
