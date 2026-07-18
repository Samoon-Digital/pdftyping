import 'package:flutter/material.dart';
import '../ads/interstitial_manager.dart';

class RelationshipUpdateScreen extends StatefulWidget {
  const RelationshipUpdateScreen({super.key});

  @override
  State<RelationshipUpdateScreen> createState() =>
      _RelationshipUpdateScreenState();
}

class _RelationshipUpdateScreenState extends State<RelationshipUpdateScreen> {
  @override
  void initState() {
    super.initState();
    InterstitialManager.instance.showIfAvailable();
  }

  static const _documents = <_RelationItem>[
    _RelationItem('1', 'Valid Indian Passport - वैध भारतीय पासपोर्ट'),
    _RelationItem(
      '2',
      'Ration /PDS Photograph Card/e-Ration Card - राशन कार्ड या ई-राशन कार्ड, जिस पर आपकी फोटो लगी हो।',
    ),
    _RelationItem(
      '3',
      'Pensioner Photo Identity Card / Freedom Fighter Photo Identity Card / Pension Payment Order issued by Central Government/ State Government/ PSU / regulatory body / statutory body - पेंशनर का फोटो वाला पहचान पत्र / स्वतंत्रता सेनानी का फोटो वाला पहचान पत्र / या पेंशन मिलने का सरकारी कागज (PPO नंबर वाला), जो सरकार देती है।',
    ),
    _RelationItem(
      '4',
      'MGNREGA/NREGS Job Card and Domicile Certificate issued by State Government - MGNREGA जॉब कार्ड और राज्य सरकार द्वारा जारी डोमिसाइल प्रमाण पत्र (निवास प्रमाण पत्र)',
    ),
    _RelationItem(
      '5',
      'Marriage Certificate with or without photograph issued by Central Government/ State Government (supporting PoI document of old name and photograph is required if the Marriage Certificate is without photograph) - केंद्र सरकार या राज्य सरकार द्वारा जारी विवाह प्रमाण पत्र (अगर विवाह प्रमाण पत्र में फोटो नहीं है, तो पुराने नाम और फोटो वाला पहचान प्रमाण देना जरूरी है)।',
    ),
    _RelationItem(
      '6',
      'Marriage Certificate with or without photograph issued by Central Government/ State Government (supporting PoI document of old name and photograph is required if the Marriage Certificate is without photograph) - केंद्र सरकार या राज्य सरकार द्वारा जारी विवाह प्रमाण पत्र (अगर विवाह प्रमाण पत्र में फोटो नहीं है, तो पुराने नाम और फोटो वाला पहचान प्रमाण देना जरूरी है)।',
    ),
    _RelationItem(
      '7',
      'Scheduled Tribe (ST) / Scheduled Caste (SC) / Other Backward Caste (OBC) Certificate issued by Central Government / State Government - केंद्र सरकार / राज्य सरकार / तहसील स्तर द्वारा जारी अनुसूचित जनजाति (ST) / अनुसूचित जाति (SC) / अन्य पिछड़ा वर्ग (OBC) जाति प्रमाण पत्र',
    ),
    _RelationItem(
      '8',
      'Mark-sheet/Certificate issued by recognised Board of Education or university or deemed university or higher educational institution established by a Central or State Act - मान्यता प्राप्त बोर्ड/विश्वविद्यालय या सरकार द्वारा मान्यता प्राप्त संस्थान से जारी अंकपत्र या प्रमाण पत्र',
    ),
    _RelationItem(
      '9',
      'Third gender / Transgender Identity Card / Certificate issued under the Transgender Persons (Protection of Rights) Act, 2019 and rules made thereunder - ट्रांसजेंडर व्यक्ति का पहचान पत्र/प्रमाण पत्र (ट्रांसजेंडर व्यक्तियों के अधिकार संरक्षण अधिनियम, 2019 के तहत जारी)',
    ),
    _RelationItem(
      '10',
      'Birth certificate issued under the Registration of Births and Deaths Act, 1969 and the rules made thereunder',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('रिश्ते का प्रमाण')),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _documents.length + 1,
        separatorBuilder: (BuildContext context, int index) =>
            const SizedBox(height: 12),
        itemBuilder: (BuildContext context, int index) {
          if (index == 0) {
            return Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFBFDBFE)),
              ),
              child: const Text(
                'रिश्ते का प्रमाण (Proof of Relationship)',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
              ),
            );
          }

          final item = _documents[index - 1];
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

class _RelationItem {
  final String number;
  final String text;

  const _RelationItem(this.number, this.text);
}
