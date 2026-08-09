import 'package:flutter/material.dart';
import '../ads/interstitial_manager.dart';
import '../widgets/shared_native_ad_slot.dart';

class DobUpdateScreen extends StatefulWidget {
  const DobUpdateScreen({super.key});

  @override
  State<DobUpdateScreen> createState() => _DobUpdateScreenState();
}

class _DobUpdateScreenState extends State<DobUpdateScreen> {
  static const int _nativeAdSlotIndex = 6;

  @override
  void initState() {
    super.initState();
    InterstitialManager.instance.showIfAvailable();
  }

  static const _documents = <_DobItem>[
    _DobItem('1', 'Valid Indian Passport - वैध भारतीय पासपोर्ट'),
    _DobItem(
      '4',
      'Service Photo Identity Card issued by Central Government/ State Government/ PSU/ regulatory body / statutory body - सरकारी/कंपनी वाला आईडी कार्ड (जिसमें आपकी फोटो हो)',
    ),
    _DobItem(
      '5',
      'Pensioner Photo Identity Card / Freedom Fighter Photo Identity Card / Pension Payment Order issued by Central Government/ State Government/ PSU / regulatory body / statutory body - पेंशनर का फोटो वाला पहचान पत्र / स्वतंत्रता सेनानी का फोटो वाला पहचान पत्र / या पेंशन मिलने का सरकारी कागज (PPO नंबर वाला), जो सरकार देती है।',
    ),
    _DobItem(
      '13',
      'Mark-sheet/Certificate issued by recognised Board of Education or university or deemed university or higher educational institution established by a Central or State Act - मान्यता प्राप्त बोर्ड/विश्वविद्यालय या सरकार द्वारा मान्यता प्राप्त संस्थान से जारी अंकपत्र या प्रमाण पत्र',
    ),
    _DobItem(
      '5',
      'Registration of Births and Deaths Act, 1969 aur uske tahat bane niyamon ke antargat jaari kiya gaya janm praman patra. / 1969 के जन्म और मृत्यु पंजीकरण कानून के अनुसार जारी किया गया जन्म प्रमाण पत्र।',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('जन्मतिथि संशोधन')),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _documents.length + 2,
        separatorBuilder: (BuildContext context, int index) =>
            const SizedBox(height: 12),
        itemBuilder: (context, index) {
          if (index == 0) {
            return Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFBFDBFE)),
              ),
              child: const Text(
                'जन्मतिथि अपडेट के लिए दस्तावेज',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
              ),
            );
          }
          if (index == _nativeAdSlotIndex) {
            return const SharedNativeAdSlot();
          }
          final documentIndex = index > _nativeAdSlotIndex
              ? index - 2
              : index - 1;
          final item = _documents[documentIndex];
          return Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: theme.colorScheme.primary.withValues(alpha: 0.16),
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF111827).withValues(alpha: 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 28,
                  height: 28,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    item.number,
                    style: TextStyle(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    item.text,
                    style: const TextStyle(
                      fontSize: 13.4,
                      height: 1.45,
                      color: Color(0xFF111827),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _DobItem {
  final String number;
  final String text;

  const _DobItem(this.number, this.text);
}
