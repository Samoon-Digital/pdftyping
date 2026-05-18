import 'package:flutter/material.dart';
import 'aadhaar_18_years_screen.dart';
import 'aadhaar_biometric_screen.dart';
import 'bal_aadhaar_screen.dart';
import 'name_update_screen.dart';
import 'address_update_screen.dart';
import 'dob_update_screen.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
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
  ];

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Aadhaar Guide Title'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Icon(
              Icons.ads_click_rounded,
              color: theme.colorScheme.primary,
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFB91C1C), Color(0xFFF59E0B)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFF59E0B).withValues(alpha: 0.22),
                  blurRadius: 18,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.notifications_active_rounded,
                      color: Colors.white,
                    ),
                    SizedBox(width: 10),
                    Text(
                      'Important Notice',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Text(
                  'Aadhaar update guide ke liye neeche diye gaye cards ko follow karein.',
                  style: TextStyle(
                    color: Colors.white,
                    height: 1.35,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Aadhaar Update Options',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          for (final card in _cards) ...[
            _GuideCard(data: card),
            const SizedBox(height: 12),
          ],
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFBFDBFE)),
            ),
            child: const Text(
              'AdMob area ready',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
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
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: data.accent.withValues(alpha: 0.14)),
            boxShadow: [
              BoxShadow(
                color: data.accent.withValues(alpha: 0.10),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        data.accent,
                        data.accent.withValues(alpha: 0.72),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(data.icon, color: Colors.white),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data.title,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        data.subtitle,
                        style: const TextStyle(
                          fontSize: 12.5,
                          height: 1.35,
                          color: Color(0xFF5B6472),
                        ),
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
