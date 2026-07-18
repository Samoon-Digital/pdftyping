import 'package:flutter/material.dart';
import '../ads/shared_native_ad.dart';
import '../ads/interstitial_manager.dart';

class AddressUpdateScreen extends StatefulWidget {
  const AddressUpdateScreen({super.key});

  @override
  State<AddressUpdateScreen> createState() => _AddressUpdateScreenState();
}

class _AddressUpdateScreenState extends State<AddressUpdateScreen> {
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
      'Service Photo Identity Card issued by Central Government / State Government / PSU / regulatory body / statutory body - सरकारी/कंपनी वाला आईडी कार्ड (जिसमें आपकी फोटो हो)',
    ),
    _PoiItem(
      '5',
      'Pensioner Photo Identity Card / Freedom Fighter Photo Identity Card / Pension Payment Order issued by Central Government / State Government / PSU / regulatory body / statutory body - पेंशनर का फोटो वाला पहचान पत्र / स्वतंत्रता सेनानी का फोटो वाला पहचान पत्र / या पेंशन मिलने का सरकारी कागज (PPO नंबर वाला), जो सरकार देती है।',
    ),
    _PoiItem(
      '6',
      'Kisan Photo Passbook / किसान फोटो पासबुक जैसे किसान क्रेडिट कार्ड पासबुक',
    ),
    _PoiItem(
      '7',
      'Certificate as per the UIDAI prescribed format, jointly signed and stamped by the Head of Shelter Home registered under RPwD Act, 2016 and the District Social Welfare Officer (DSWO) / Authorized Officer of equivalent rank for disability related matters in the district - यह एक सरकारी प्रमाण पत्र है जो उन लोगों के लिए बनता है जो शेल्टर होम (सरकारी आश्रय गृह) में रहते हैं और जिनकी डिसएबिलिटी (विकलांगता) से जुड़ी पहचान और रिकॉर्ड सही करने के लिए दिया जाता है। यह कागज शेल्टर होम का हेड + जिला समाज कल्याण अधिकारी मिलकर साइन और स्टैम्प करके बनाते हैं।',
    ),
    _PoiItem(
      '8',
      'Marriage Certificate with or without photograph issued by Central Government / State Government (supporting PoI document of old name and photograph is required if the Marriage Certificate is without photograph) - केंद्र सरकार या राज्य सरकार द्वारा जारी विवाह प्रमाण पत्र (अगर विवाह प्रमाण पत्र में फोटो नहीं है, तो पुराने नाम और फोटो वाला पहचान प्रमाण देना जरूरी है)।',
    ),
    _PoiItem(
      '9',
      'Scheduled Tribe (ST) / Scheduled Caste (SC) / Other Backward Caste (OBC) Certificate issued by Central Government / State Government - केंद्र सरकार / राज्य सरकार / तहसील स्तर द्वारा जारी अनुसूचित जनजाति (ST) / अनुसूचित जाति (SC) / अन्य पिछड़ा वर्ग (OBC) जाति प्रमाण पत्र',
    ),
    _PoiItem(
      '10',
      'Passbook issued by a scheduled commercial bank or a State cooperative bank having Name and Photograph (cross stamped with Bank seal) and signed by bank official/ Post Office Savings Account Passbook (with stamp and signature of issuing official of post office) - अनुसूचित वाणिज्यिक बैंक या राज्य सहकारी बैंक द्वारा जारी पासबुक, जिसमें नाम और फोटो हो (बैंक की मुहर लगी हो और बैंक अधिकारी के हस्ताक्षर हों) / डाकघर बचत खाता पासबुक (डाकघर के जारी करने वाले अधिकारी की मुहर और हस्ताक्षर सहित)।',
    ),
    _PoiItem(
      '11',
      'Bank Account Statement/ Credit Card Statement (with Bank stamp & signature of issuing bank official)/ Post Office Savings Account Statement (with stamp and signature of issuing official of post office) (not older than 3 months) - बैंक खाता विवरण / क्रेडिट कार्ड स्टेटमेंट (बैंक की मुहर और जारी करने वाले बैंक अधिकारी के हस्ताक्षर सहित) / डाकघर बचत खाता विवरण (डाकघर के जारी करने वाले अधिकारी की मुहर और हस्ताक्षर सहित) — यह 3 महीने से पुराना नहीं होना चाहिए।',
    ),
    _PoiItem(
      '12',
      'Third gender / Transgender Identity Card / Certificate issued under the Transgender Persons (Protection of Rights) Act, 2019 and rules made thereunder - ट्रांसजेंडर व्यक्ति का पहचान पत्र/प्रमाण पत्र (ट्रांसजेंडर व्यक्तियों के अधिकार संरक्षण अधिनियम, 2019 के तहत जारी)',
    ),
    _PoiItem(
      '13',
      'Certificate issued on UIDAI Standard Certificate format by: i. MP / MLA / MLC / Municipal Councillor ii. Gazetted Officer Group ‘A’/ Employees Provident Fund Organisation (EPFO) Officer iii.Tehsildar/ Gazetted Officer Group ‘B’ iv. Gazetted Officer at National AIDS Control Organisation (NACO)/State Health Department / Project Director of the State AIDS Control Society or his nominee (in pursuance of Hon’ble Supreme Court Judgment in Criminal Appeal No(s). 135/2010 dated 19.5.2022) vi. Recognised educational institution (signed by the Head of Institute, only for the institute students concerned) vii. Village Panchayat Head/ President or Mukhiya/ Gaon Bura/ equivalent authority (for rural areas)/ Village Panchayat Secretary/ Village Revenue Officer or equivalent (for rural areas)',
    ),
    _PoiItem(
      '14',
      'Electricity bill (pre-paid/post-paid bill, not older than 3 months) - बिजली का बिल (प्री-पेड या पोस्ट-पेड बिल, जो 3 महीने से पुराना न हो)।',
    ),
    _PoiItem(
      '15',
      'Water bill (not older than 3 months) - पानी का बिल (जो 3 महीने से पुराना न हो)।',
    ),
    _PoiItem(
      '16',
      'Telephone landline bill/ post-paid mobile bill/ broadband bill (not older than 3 months) - टेलीफोन लैंडलाइन बिल / पोस्ट-पेड मोबाइल बिल / ब्रॉडबैंड बिल (जो 3 महीने से पुराना न हो)।',
    ),
    _PoiItem(
      '17',
      'Property Tax Receipt (not older than 1 year) - संपत्ति कर रसीद (जो 1 वर्ष से पुरानी न हो)।',
    ),
    _PoiItem(
      '18',
      'Valid sale agreement/ gift deed registered with the Registrar Office, or registered or unregistered rent, lease agreement or leave and licence agreement - रजिस्ट्री ऑफिस में दर्ज बिक्री का समझौता या उपहार का दस्तावेज, या किराये/लीज/लाइसेंस का समझौता (चाहे पंजीकृत हो या न हो)।',
    ),
    _PoiItem(
      '19',
      'Gas bill (not older than 3 months) - गैस का बिल (जो 3 महीने से पुराना न हो)।',
    ),
    _PoiItem(
      '20',
      'Allotment letter of accommodation issued by Central Government/ State Government/ PSU / regulatory body / statutory body (not older than 1 year) - केंद्र सरकार / राज्य सरकार / PSU / नियामक संस्था / वैधानिक संस्था द्वारा जारी आवास आवंटन पत्र (जो 1 वर्ष से पुराना न हो)।',
    ),
    _PoiItem(
      '21',
      'Life or medical insurance Policy (valid up to 1 year from the date of issue of the Policy) - जीवन या चिकित्सा बीमा पॉलिसी (पॉलिसी जारी होने की तिथि से 1 वर्ष तक मान्य)',
    ),
    _PoiItem(
      '22',
      'Prisoner Induction Document (PID) issued by Prison Officer with signature and seal - जेल अधिकारी द्वारा हस्ताक्षर और मुहर सहित जारी किया गया कैदी प्रवेश दस्तावेज (PID)।',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('पता संसोधन')),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _documents.length + 3,
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
                'पते का प्रमाण (Proof of Address)',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
              ),
            );
          }
          if (index == 3) {
            return const SharedNativeAd(
              placementId: 'address_after_ration_card',
            );
          }
          if (index == 22) {
            return const SharedNativeAd(
              placementId: 'address_after_allotment_letter',
            );
          }
          var adjustedIndex = index;
          if (index > 22) {
            adjustedIndex -= 2;
          } else if (index > 3) {
            adjustedIndex -= 1;
          }

          final item = _documents[adjustedIndex - 1];
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
