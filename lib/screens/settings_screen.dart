import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../widgets/banner_ad_scaffold.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  static final Uri _privacyPolicyUrl = Uri.parse(
    'https://sites.google.com/view/aadhaarupdateguide/home',
  );
  static final Uri _instagramUrl = Uri.parse(
    'https://www.instagram.com/samoon_digital/',
  );

  Future<void> _openExternalLink(Uri uri, String failMessage) async {
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(failMessage)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return BannerAdScaffold(
      appBar: AppBar(title: const Text('सेटिंग्स'), elevation: 0),
      protectBottomInset: false,
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          const SizedBox(height: 4),
          _LinkDetailCard(
            icon: Icons.privacy_tip_outlined,
            title: 'Privacy Policy',
            subtitle:
                'ऐप की डेटा नीति और उपयोग की शर्तें पढ़ने के लिए यहाँ टैप करें।',
            ctaText: 'Policy Open करें',
            accent: const Color(0xFF1D4ED8),
            onTap: () => _openExternalLink(
              _privacyPolicyUrl,
              'Privacy Policy link open नहीं हो पाया।',
            ),
          ),
          const SizedBox(height: 12),
          _LinkDetailCard(
            icon: Icons.camera_alt_outlined,
            title: 'Contact on Instagram',
            subtitle:
                'Questions, feedback ya support ke liye Instagram profile पर जुड़ें।',
            ctaText: 'Instagram Open करें',
            accent: const Color(0xFFBE185D),
            onTap: () => _openExternalLink(
              _instagramUrl,
              'Instagram link open नहीं हो पाया।',
            ),
          ),
          const SizedBox(height: 12),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('संस्करण'),
            subtitle: const Text('1.8.4'),
          ),
        ],
      ),
    );
  }
}

class _LinkDetailCard extends StatelessWidget {
  const _LinkDetailCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.ctaText,
    required this.accent,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String ctaText;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: LinearGradient(
              colors: [
                accent.withValues(alpha: 0.14),
                accent.withValues(alpha: 0.05),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(color: accent.withValues(alpha: 0.20)),
            boxShadow: [
              BoxShadow(
                color: accent.withValues(alpha: 0.10),
                blurRadius: 14,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: accent),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 12.5,
                          height: 1.35,
                          color: Color(0xFF3F4B59),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Text(
                            ctaText,
                            style: TextStyle(
                              color: accent,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Icon(
                            Icons.open_in_new_rounded,
                            size: 18,
                            color: accent,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
