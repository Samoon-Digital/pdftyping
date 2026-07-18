import 'package:flutter/material.dart';
import '../ads/interstitial_manager.dart';

class NameUpdateScreen extends StatefulWidget {
  const NameUpdateScreen({super.key});

  @override
  State<NameUpdateScreen> createState() => _NameUpdateScreenState();
}

class _NameUpdateScreenState extends State<NameUpdateScreen> {
  @override
  void initState() {
    super.initState();
    InterstitialManager.instance.showIfAvailable();
  }

  static const _documents = <_PoiItem>[
    _PoiItem('1', 'Valid Indian Passport - वैध भारतीय पासपोर्ट'),
    _PoiItem(
      '2',
      'Ration / PDS Photograph Card / e-Ration Card - राशन कार्ड या ई-राशन कार्ड, जिस पर आपकी फोटो लगी हो।',
    ),
    _PoiItem(
      '3',
      'Voter Identity Card / e-Voter Identity Card whose details are displayed online on the website of the Election Commission of India or the Chief Electoral Officer concerned - वोटर आईडी कार्ड / ई-वोटर आईडी कार्ड, जिसकी जानकारी चुनाव आयोग की वेबसाइट पर ऑनलाइन दिखाई देती हो।',
    ),
    _PoiItem(
      '4',
      'Driving licence - ड्राइविंग लाइसेंस (गाड़ी चलाने का लाइसेंस)।',
    ),
    _PoiItem(
      '5',
      'Service Photo Identity Card issued by Central Government / State Government / PSU / regulatory body / statutory body - सरकारी/कंपनी वाला आईडी कार्ड (जिसमें आपकी फोटो हो)।',
    ),
    _PoiItem(
      '6',
      'Pensioner Photo Identity Card / Freedom Fighter Photo Identity Card / Pension Payment Order issued by Central Government / State Government / PSU / regulatory body / statutory body - पेंशनर का फोटो वाला पहचान पत्र / स्वतंत्रता सेनानी का फोटो वाला पहचान पत्र / या पेंशन मिलने का सरकारी कागज (PPO नंबर वाला), जो सरकार देती है।',
    ),
    _PoiItem(
      '7',
      'CGHS / ECHS / ESIC / Medi-Claim Card issued by Central Government / State Government / PSU - सरकारी या कंपनी का हेल्थ कार्ड (CGHS / ECHS / ESIC / मेडिक्लेम कार्ड), जिससे सरकारी अस्पताल या पैनल हॉस्पिटल में इलाज मिलता है।',
    ),
    _PoiItem(
      '8',
      'Certificate as per the UIDAI prescribed format, jointly signed and stamped by the Head of Shelter Home registered under RPwD Act, 2016 and the District Social Welfare Officer (DSWO) / Authorized Officer of equivalent rank for disability related matters in the district - यह एक सरकारी प्रमाण पत्र है जो उन लोगों के लिए बनता है जो शेल्टर होम (सरकारी आश्रय गृह) में रहते हैं और जिनकी डिसएबिलिटी (विकलांगता) से जुड़ी पहचान और रिकॉर्ड सही करने के लिए दिया जाता है। यह कागज शेल्टर होम का हेड + जिला समाज कल्याण अधिकारी मिलकर साइन और स्टैम्प करके बनाते हैं।',
    ),
    _PoiItem(
      '9',
      'MGNREGA / NREGS Job Card and Domicile Certificate issued by State Government - MGNREGA जॉब कार्ड और राज्य सरकार द्वारा जारी डोमिसाइल प्रमाण पत्र (निवास प्रमाण पत्र)।',
    ),
    _PoiItem(
      '10',
      'Marriage Certificate with or without photograph issued by Central Government / State Government (supporting PoI document of old name and photograph is required if the Marriage Certificate is without photograph) - केंद्र सरकार या राज्य सरकार द्वारा जारी विवाह प्रमाण पत्र (अगर विवाह प्रमाण पत्र में फोटो नहीं है, तो पुराने नाम और फोटो वाला पहचान प्रमाण देना जरूरी है)।',
    ),
    _PoiItem(
      '11',
      'Divorce Decree issued by family court - परिवार न्यायालय द्वारा जारी तलाक का आदेश (डिवोर्स डिक्री)।',
    ),
    _PoiItem(
      '12',
      'Scheduled Tribe (ST) / Scheduled Caste (SC) / Other Backward Caste (OBC) Certificate issued by Central Government / State Government - केंद्र सरकार / राज्य सरकार / तहसील स्तर द्वारा जारी अनुसूचित जनजाति (ST) / अनुसूचित जाति (SC) / अन्य पिछड़ा वर्ग (OBC) जाति प्रमाण पत्र।',
    ),
    _PoiItem(
      '13',
      'Mark-sheet / Certificate issued by recognised Board of Education or university or deemed university or higher educational institution established by a Central or State Act - मान्यता प्राप्त बोर्ड/विश्वविद्यालय या सरकार द्वारा मान्यता प्राप्त संस्थान से जारी अंकपत्र या प्रमाण पत्र।',
    ),
    _PoiItem(
      '14',
      'Third gender / Transgender Identity Card / Certificate issued under the Transgender Persons (Protection of Rights) Act, 2019 and rules made thereunder - ट्रांसजेंडर व्यक्ति का पहचान पत्र/प्रमाण पत्र (ट्रांसजेंडर व्यक्तियों के अधिकार संरक्षण अधिनियम, 2019 के तहत जारी)।',
    ),
    _PoiItem(
      '15',
      'Gazetted Officer at National AIDS Control Organisation (NACO) / State Health Department / Project Director of the State AIDS Control Society or his nominee (in pursuance of Hon’ble Supreme Court Judgment in Criminal Appeal No(s). 135/2010 dated 19.5.2022) - NACO / State Health Department / State AIDS Control Society (or nominee) द्वारा जारी प्रमाण पत्र (माननीय सुप्रीम कोर्ट आदेश 19.05.2022 के अनुसार)।',
    ),
    _PoiItem(
      '16',
      'Prisoner Induction Document (PID) issued by Prison Officer with signature and seal - Prisoner Induction Document (PID) जो जेल अधिकारी द्वारा हस्ताक्षर और मुहर के साथ जारी किया जाता है।',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('नाम संशोधन')),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _documents.length + 1,
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
                'पहचान का प्रमाण (Proof of Identity)',
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

class _PoiItem {
  final String number;
  final String text;

  const _PoiItem(this.number, this.text);
}
