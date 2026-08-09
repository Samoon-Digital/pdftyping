import 'package:flutter/material.dart';
import '../ads/native_ad_manager.dart';
import '../services/share_service.dart';
import 'aadhaar_18_years_screen.dart';
import 'aadhaar_biometric_screen.dart';
import 'bal_aadhaar_screen.dart';
import 'name_update_screen.dart';
import 'address_update_screen.dart';
import 'dob_update_screen.dart';
import 'relationship_update_screen.dart';
import 'finger_face_biometric_update_screen.dart';
import 'mobile_number_update_screen.dart';
import 'fees_update_screen.dart';
import 'settings_screen.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();
    NativeAdManager.instance.start();
  }

  static const _cards = <_GuideCardData>[
    _GuideCardData(
      title: 'Child Aadhaar - बाल आधार',
      subtitle: '5 साल के अंदर उम्र के बच्चों के लिए',
      icon: Icons.child_care_rounded,
      accent: Color(0xFF0F766E),
      screen: BalAadhaarScreen(),
    ),
    _GuideCardData(
      title: 'Aadhaar Biomteric - आधार कार्ड',
      subtitle: '5 साल से ऊपर 18 साल से कम उम्र के लिए',
      icon: Icons.fingerprint_rounded,
      accent: Color(0xFF1565C0),
      screen: AadhaarBiometricScreen(),
    ),
    _GuideCardData(
      title: 'Aadhaar Biomteric - आधार कार्ड',
      subtitle: '18 साल ऊपर के व्यक्ति के लिए केवल',
      icon: Icons.fingerprint_rounded,
      accent: Color(0xFF1565C0),
      screen: Aadhaar18YearsScreen(),
    ),
    _GuideCardData(
      title: 'Name Update - नाम संसोधन',
      subtitle: 'नाम संसोधन / नाम बदलाव के लिए',
      icon: Icons.badge_rounded,
      accent: Color(0xFF7C3AED),
      screen: NameUpdateScreen(),
    ),
    _GuideCardData(
      title: 'Date Of Birth Update - जन्मतिथि संसोधन',
      subtitle: 'जन्मतिथि बदलाव / संसोधन हेतु',
      icon: Icons.event_rounded,
      accent: Color(0xFFB91C1C),
      screen: DobUpdateScreen(),
    ),
    _GuideCardData(
      title: 'Address Update - पता संसोधन',
      subtitle: 'पिता / पति का नाम व पता संसोधन',
      icon: Icons.location_on_rounded,
      accent: Color(0xFFF59E0B),
      screen: AddressUpdateScreen(),
    ),
    _GuideCardData(
      title: 'Proof of Relationship - रिश्ते का प्रमाण',
      subtitle: 'रिलेशनशिप डॉक्यूमेंट अपडेट के लिए',
      icon: Icons.people_alt_rounded,
      accent: Color(0xFF0EA5A4),
      screen: RelationshipUpdateScreen(),
    ),
    _GuideCardData(
      title: 'Finger Face Biometric Update - अंगूठा और फोटो संसोधन',
      subtitle: '5 साल से ऊपर किसी भी उम्र तक',
      icon: Icons.fingerprint,
      accent: Color(0xFF7C2D12),
      screen: FingerFaceBiometricUpdateScreen(),
    ),
    _GuideCardData(
      title: 'Mobile Number Update - मोबाईल नंबर संसोधन',
      subtitle: 'नया नंबर या पुराना नंबर बदलने के लिए',
      icon: Icons.phone_android_rounded,
      accent: Color(0xFF1D4ED8),
      screen: MobileNumberUpdateScreen(),
    ),
    _GuideCardData(
      title: 'Aadhaar Fees - आधार शुल्क',
      subtitle: 'नामांकन और अपडेट शुल्क विवरण',
      icon: Icons.currency_rupee_rounded,
      accent: Color(0xFF166534),
      screen: FeesUpdateScreen(),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Aadhaar Update Guide'),
        actions: [
          IconButton(
            tooltip: 'Share',
            icon: const Icon(Icons.share_rounded),
            onPressed: ShareService.shareApp,
          ),
          IconButton(
            tooltip: 'Settings',
            icon: const Icon(Icons.settings_rounded),
            onPressed: () {
              Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const SettingsScreen()));
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
        children: [
          const Text(
            'Aadhaar Update Options',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          for (final entry in _cards.asMap().entries) ...[
            _GuideCard(data: entry.value),
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}

class _GuideCardData {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color accent;
  final Widget? screen;

  const _GuideCardData({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accent,
    this.screen,
  });
}

class _GuideCard extends StatelessWidget {
  final _GuideCardData data;

  const _GuideCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final onTap = data.screen != null
        ? () {
            Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => data.screen!));
          }
        : null;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: data.accent.withValues(alpha: 0.16)),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF111827).withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 10),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        data.accent,
                        data.accent.withValues(alpha: 0.72),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Icon(data.icon, color: Colors.white, size: 23),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data.title,
                        style: const TextStyle(
                          fontSize: 14.2,
                          fontWeight: FontWeight.w800,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        data.subtitle,
                        style: const TextStyle(
                          fontSize: 12,
                          height: 1.28,
                          color: Color(0xFF5B6472),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.chevron_right_rounded,
                  color: data.accent.withValues(alpha: 0.72),
                  size: 22,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
