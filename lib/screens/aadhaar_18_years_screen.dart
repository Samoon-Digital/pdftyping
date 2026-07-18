import 'package:flutter/material.dart';
import '../ads/shared_native_ad.dart';
import '../ads/interstitial_manager.dart';

class Aadhaar18YearsScreen extends StatefulWidget {
  const Aadhaar18YearsScreen({super.key});

  @override
  State<Aadhaar18YearsScreen> createState() => _Aadhaar18YearsScreenState();
}

class _Aadhaar18YearsScreenState extends State<Aadhaar18YearsScreen> {
  bool _showStepTwo = false;
  bool _identityExpanded = false;
  bool _addressExpanded = false;
  bool _birthExpanded = false;

  void _showDocumentList() {
    setState(() => _showStepTwo = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _showStepTwo) {
        InterstitialManager.instance.showIfAvailable();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('18 Years Old')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const _HeaderCard(),
          const SizedBox(height: 16),
          if (_showStepTwo) ...[
            const Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: Text(
                'LIST OF ACCEPTABLE DOCUMENTS FOR AADHAAR ENROLMENT\nआधार बनवाने के लिए मान्य दस्तावेजों की सूची',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  height: 1.4,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFCD34D)),
              ),
              child: const Text(
                'यह सूची 18 साल से ऊपर उम्र के व्यक्तियों के लिए मान्य है।',
                style: TextStyle(
                  fontSize: 12.5,
                  height: 1.4,
                  color: Color(0xFF78350F),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const SharedNativeAd(
              placementId: 'aadhaar_18_before_proof_identity',
            ),
            const SizedBox(height: 12),
            _DocumentSection(
              title: 'Proof of Identity - पहचान का प्रमाण',
              accent: const Color(0xFFC7D2FE),
              borderAccent: const Color(0xFF1565C0),
              isExpanded: _identityExpanded,
              onToggle: () =>
                  setState(() => _identityExpanded = !_identityExpanded),
              documents: const [
                '1 - Valid Indian Passport - वैध भारतीय पासपोर्ट',
                '2 - Ration /PDS Photograph Card/e-Ration Card - राशन कार्ड या ई-राशन कार्ड, जिस पर आपकी फोटो लगी हो।',
                '3 - Voter Identity Card / e-Voter Identity Card whose details are displayed online on Election Commission website - वोटर आईडी कार्ड / ई-वोटर आईडी कार्ड, जिसकी जानकारी चुनाव आयोग की वेबसाइट पर ऑनलाइन दिखाई देती हो।',
                '4 - Driving licence - ड्राइविंग लाइसेंस (गाड़ी चलाने का लाइसेंस)।',
                '5 - Service Photo Identity Card issued by Central Government / State Government / PSU / regulatory body / statutory body - सरकारी/कंपनी वाला आईडी कार्ड (जिसमें आपकी फोटो हो)।',
                '6 - Pensioner Photo Identity Card / Freedom Fighter Photo Identity Card / Pension Payment Order issued by Central Government / State Government / PSU / regulatory body / statutory body - पेंशनर का फोटो वाला पहचान पत्र / स्वतंत्रता सेनानी का फोटो वाला पहचान पत्र / या पेंशन मिलने का सरकारी कागज (PPO नंबर वाला)।',
                '7 - CGHS / ECHS / ESIC / Medi-Claim Card issued by Central Government / State Government / PSU - सरकारी या कंपनी का हेल्थ कार्ड (CGHS / ECHS / ESIC / मेडिक्लेम कार्ड)।',
                '8 - UIDAI prescribed format certificate signed by Head of Shelter Home and DSWO / Authorized Officer for disability matters - शेल्टर होम का हेड और जिला समाज कल्याण अधिकारी द्वारा हस्ताक्षरित और स्टैम्प किया गया UIDAI प्रारूप प्रमाण पत्र।',
                '9 - MGNREGA / NREGS Job Card and Domicile Certificate issued by State Government - MGNREGA जॉब कार्ड और राज्य सरकार द्वारा जारी डोमिसाइल प्रमाण पत्र।',
                '10 - Scheduled Tribe (ST) / Scheduled Caste (SC) / Other Backward Caste (OBC) Certificate issued by Central Government / State Government - केंद्र सरकार / राज्य सरकार / तहसील स्तर द्वारा जारी ST / SC / OBC जाति प्रमाण पत्र।',
                '11 - Mark-sheet / Certificate issued by recognised Board of Education / university / deemed university / higher educational institution established by Central or State Act - मान्यता प्राप्त बोर्ड/विश्वविद्यालय या सरकार द्वारा मान्यता प्राप्त संस्थान से जारी अंकपत्र या प्रमाण पत्र।',
                '12 - Third gender / Transgender Identity Card / Certificate issued under Transgender Persons (Protection of Rights) Act, 2019 - ट्रांसजेंडर व्यक्ति का पहचान पत्र/प्रमाण पत्र (अधिनियम 2019 के तहत जारी)।',
                '13 - Certificate issued by Gazetted Officer at NACO / State Health Department / State AIDS Control Society (or nominee) as per Supreme Court order dated 19.05.2022 - NACO / राज्य स्वास्थ्य विभाग / State AIDS Control Society (या नामित अधिकारी) द्वारा जारी प्रमाण पत्र।',
                '14 - Prisoner Induction Document (PID) issued by Prison Officer with signature and seal - जेल अधिकारी द्वारा हस्ताक्षर और मुहर के साथ जारी PID दस्तावेज।',
              ],
            ),
            const SizedBox(height: 12),
            _DocumentSection(
              title: 'Proof of Address - पते का प्रमाण',
              accent: const Color(0xFFDCFCE7),
              borderAccent: const Color(0xFF0F766E),
              isExpanded: _addressExpanded,
              onToggle: () =>
                  setState(() => _addressExpanded = !_addressExpanded),
              documents: const [
                '1 - Valid Indian Passport - वैध भारतीय पासपोर्ट',
                '2 - Ration /PDS Photograph Card/e-Ration Card - राशन कार्ड या ई-राशन कार्ड, जिस पर आपकी फोटो लगी हो।',
                '3 - Voter Identity Card /e-Voter Identity Card whose details are displayed online on the website of the Election Commission of India or the Chief Electoral Officer concerned - वोटर आईडी कार्ड / ई-वोटर आईडी कार्ड, जिसकी जानकारी चुनाव आयोग की वेबसाइट पर ऑनलाइन दिखाई देती हो।',
                '4 - Service Photo Identity Card issued by Central Government/State Government/ PSU/ regulatory body / statutory body - सरकारी/कंपनी वाला आईडी कार्ड (जिसमें आपकी फोटो हो)।',
                '5 - Pensioner Photo Identity Card / Freedom Fighter Photo Identity Card / Pension Payment Order issued by Central Government/ State Government/ PSU / regulatory body / statutory body - पेंशनर का फोटो वाला पहचान पत्र / स्वतंत्रता सेनानी का फोटो वाला पहचान पत्र / या पेंशन मिलने का सरकारी कागज (PPO नंबर वाला), जो सरकार देती है।',
                '6 - Certificate as per the UIDAI prescribed format, jointly signed and stamped by the Head of Shelter Home registered under RPwD Act, 2016 and the District Social Welfare Officer (DSWO) / Authorized Officer of equivalent rank for disability related matters in the district - यह एक सरकारी प्रमाण पत्र है जो उन लोगों के लिए बनता है जो शेल्टर होम (सरकारी आश्रय गृह) में रहते हैं और जिनकी डिसएबिलिटी (विकलांगता) से जुड़ी पहचान और रिकॉर्ड सही करने के लिए दिया जाता है। यह कागज शेल्टर होम का हेड + जिला समाज कल्याण अधिकारी मिलकर साइन और स्टैम्प करके बनाते हैं।',
                '7 - MGNREGA/NREGS Job Card and Domicile Certificate issued by State Government - MGNREGA जॉब कार्ड और राज्य सरकार द्वारा जारी डोमिसाइल प्रमाण पत्र (निवास प्रमाण पत्र)।',
                '8 - Scheduled Tribe (ST) / Scheduled Caste (SC) / Other Backward Caste (OBC) Certificate issued by Central Government / State Government - केंद्र सरकार / राज्य सरकार / तहसील स्तर द्वारा जारी अनुसूचित जनजाति (ST) / अनुसूचित जाति (SC) / अन्य पिछड़ा वर्ग (OBC) जाति प्रमाण पत्र।',
                '9 - Third gender / Transgender Identity Card / Certificate issued under the Transgender Persons (Protection of Rights) Act, 2019 and rules made thereunder - ट्रांसजेंडर व्यक्ति का पहचान पत्र/प्रमाण पत्र (ट्रांसजेंडर व्यक्तियों के अधिकार संरक्षण अधिनियम, 2019 के तहत जारी)।',
                '10 - Certificate issued on UIDAI Standard Certificate format by (i) MP/ MLA/ MLC/ Municipal Councillor (ii) Gazetted Officer Group A/ EPFO Officer (iii) Tehsildar/ Gazetted Officer Group B - सांसद / विधायक / विधान परिषद सदस्य / नगर पार्षद या ग्रुप A/B गजेटेड अधिकारी, EPFO अधिकारी या तहसीलदार द्वारा UIDAI मानक प्रमाण पत्र प्रारूप में जारी प्रमाण पत्र।',
                '11 - Gazetted Officer at National AIDS Control Organisation (NACO) / State Health Department / Project Director of the State AIDS Control Society or nominee (pursuance of Supreme Court Judgment dated 19.5.2022) - NACO / State Health Department / State AIDS Control Society (or nominee) द्वारा जारी प्रमाण पत्र (माननीय सुप्रीम कोर्ट आदेश 19.05.2022 के अनुसार)।',
                '12 - Recognised educational institution (signed by the Head of Institute, only for the institute students concerned) - मान्यता प्राप्त शिक्षण संस्थान (जिस पर संस्था के प्रमुख द्वारा केवल संबंधित विद्यार्थियों के लिए हस्ताक्षर किया गया हो)।',
                '13 - Village Panchayat Head/ President or Mukhiya/ Gaon Bura/ equivalent authority (rural) / Village Panchayat Secretary/ Village Revenue Officer or equivalent - ग्राम पंचायत प्रमुख / मुखिया / गाँव बुड़ा / समकक्ष प्राधिकारी / ग्राम पंचायत सचिव / ग्राम राजस्व अधिकारी या समकक्ष।',
                '14 - Electricity bill (pre-paid/post-paid, not older than 3 months) - बिजली बिल (प्री-पेड/पोस्ट-पेड), जो 3 महीने से अधिक पुराना न हो।',
                '15 - Water bill (not older than 3 months) - पानी का बिल (जो 3 महीने से अधिक पुराना न हो)।',
                '16 - Telephone landline bill/ post-paid mobile bill/ broadband bill (not older than 3 months) - लैंडलाइन टेलीफोन बिल / पोस्ट-पेड मोबाइल बिल / ब्रॉडबैंड बिल (जो 3 महीने से अधिक पुराना न हो)।',
                '17 - Valid sale agreement/ gift deed registered with Registrar Office, or registered/unregistered rent, lease agreement or leave and licence agreement - बिक्री समझौता / उपहार विलेख / पंजीकृत या किराये का समझौता / लीज या रहने की अनुमति वाला समझौता (जो रजिस्ट्रार के पास दर्ज हो)।',
                '18 - Gas bill (not older than 3 months) - 3 महीने से अधिक पुराना न हो ऐसा गैस बिल (LPG/पाइप्ड गैस का बिल)।',
                '19 - Allotment letter of accommodation issued by Central Government/ State Government/ PSU / regulatory body / statutory body (not older than 1 year) - केंद्र सरकार / राज्य सरकार / PSU / नियामक प्राधिकरण / वैधानिक निकाय द्वारा जारी आवास आवंटन पत्र (जो 1 वर्ष से अधिक पुराना न हो)।',
                '20 - Life or Medical insurance policy (valid up to 1 year from date of issue) - जीवन या मेडिकल बीमा पॉलिसी (जो पॉलिसी जारी होने की तारीख से 1 वर्ष तक वैध हो)।',
                '21 - Prisoner Induction Document (PID) issued by Prison Officer with signature and seal - Prisoner Induction Document (PID) जो जेल अधिकारी द्वारा हस्ताक्षर और मुहर के साथ जारी किया जाता है।',
              ],
            ),
            const SizedBox(height: 12),
            _DocumentSection(
              title: 'Proof of Birth - जन्म तिथि का प्रमाण',
              accent: const Color(0xFFFFEDD5),
              borderAccent: const Color(0xFFF59E0B),
              isExpanded: _birthExpanded,
              onToggle: () => setState(() => _birthExpanded = !_birthExpanded),
              documents: const [
                '1 - Birth certificate issued under the Registration of Births and Deaths Act, 1969 and the rules made thereunder - जन्म और मृत्यु पंजीकरण अधिनियम, 1969 तथा उसके तहत बनाए गए नियमों के अनुसार जारी किया गया जन्म प्रमाण पत्र',
                '2 - Valid Indian Passport - वैध भारतीय पासपोर्ट',
                '3 - Service Photo Identity Card issued by Central Government/ State Government/ PSU/ regulatory body / statutory body - सरकारी/कंपनी वाला आईडी कार्ड (जिसमें आपकी फोटो हो)',
                '4 - Pensioner Photo Identity Card / Freedom Fighter Photo Identity Card / Pension Payment Order issued by Central Government/ State Government/ PSU / regulatory body / statutory body - पेंशनर का फोटो वाला पहचान पत्र / स्वतंत्रता सेनानी का फोटो वाला पहचान पत्र / या पेंशन मिलने का सरकारी कागज (PPO नंबर वाला), जो सरकार देती है।',
                '5 - Mark-sheet/Certificate issued by recognised Board of Education or university or deemed university or higher educational institution established by a Central or State Act - मान्यता प्राप्त बोर्ड/विश्वविद्यालय या सरकार द्वारा मान्यता प्राप्त संस्थान से जारी अंकपत्र या प्रमाण पत्र',
                '6 - Third gender / Transgender Identity Card / Certificate issued under the Transgender Persons (Protection of Rights) Act, 2019 and rules made thereunder - ट्रांसजेंडर व्यक्ति का पहचान पत्र/प्रमाण पत्र (ट्रांसजेंडर व्यक्तियों के अधिकार संरक्षण अधिनियम, 2019 के तहत जारी)',
              ],
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () => setState(() => _showStepTwo = false),
              icon: const Icon(Icons.arrow_back_rounded),
              label: const Text('Back - सूचना पर लौटें'),
            ),
          ] else ...[
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: const Color(0xFFB91C1C).withValues(alpha: 0.14),
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFB91C1C).withValues(alpha: 0.10),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.verified_rounded,
                          size: 18,
                          color: Color(0xFFB91C1C),
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'महत्वपूर्ण सूचना / Important Notice',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 10),
                    _Bullet(
                      'आधार नामांकन के लिए 3 आवश्यक दस्तावेज देने होते हैं। एक भी दस्तावेज कम होने पर या सूची के अनुसार ना होने पर आपका नामांकन रद्द कर दिया जाएगा। इसका ध्यान रखें।',
                    ),
                    SizedBox(height: 4),
                    _Bullet(
                      '1 - Proof of Identity - पहचान का प्रमाण - इस दस्तावेज से पता चलता है कि जिसका आधार बनना है उसका नाम क्या है।',
                    ),
                    _Bullet(
                      '2 - Proof of Address - पते का प्रमाण - इस दस्तावेज से पता चलता है कि जिसका आधार बनना है उसका वास्तविक पता क्या है।',
                    ),
                    _Bullet(
                      '3 - Proof of Birth - जन्म तिथि का प्रमाण - इस दस्तावेज से पता चलता है कि जिसका आधार बनना है उसकी जन्म तिथि क्या है।',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _showDocumentList,
                icon: const Icon(Icons.list_alt_rounded),
                label: const Text('See List - सूची देखें'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFB91C1C), Color(0xFFF59E0B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFF59E0B).withValues(alpha: 0.20),
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
              Icon(Icons.notifications_active_rounded, color: Colors.white),
              SizedBox(width: 8),
              Text(
                'Important Notice',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          SizedBox(height: 10),
          Text(
            'आधार नामांकन से पहले सभी महत्वपूर्ण सूचनाएं ध्यान से पढ़ें।',
            style: TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w700,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

class _DocumentSection extends StatelessWidget {
  final String title;
  final Color accent;
  final Color borderAccent;
  final bool isExpanded;
  final VoidCallback onToggle;
  final List<String> documents;

  const _DocumentSection({
    required this.title,
    required this.accent,
    required this.borderAccent,
    required this.isExpanded,
    required this.onToggle,
    required this.documents,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderAccent.withValues(alpha: 0.3)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onToggle,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.folder_outlined, size: 16, color: borderAccent),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: borderAccent,
                        ),
                      ),
                    ),
                    Icon(
                      isExpanded
                          ? Icons.expand_less_rounded
                          : Icons.expand_more_rounded,
                      color: borderAccent,
                      size: 20,
                    ),
                  ],
                ),
                AnimatedSize(
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOut,
                  child: isExpanded
                      ? Column(
                          children: [
                            const SizedBox(height: 10),
                            ...documents.map(
                              (doc) =>
                                  _DocumentItem(doc: doc, accent: borderAccent),
                            ),
                          ],
                        )
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DocumentItem extends StatelessWidget {
  final String doc;
  final Color accent;

  const _DocumentItem({required this.doc, required this.accent});

  @override
  Widget build(BuildContext context) {
    final parts = doc.split(' - ');
    final numbering = parts[0];
    final english = parts.length > 1 ? parts[1] : '';
    final hindi = parts.length > 2 ? parts.sublist(2).join(' - ') : '';

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '• ',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: accent,
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$numbering - $english',
                  style: const TextStyle(
                    fontSize: 12.5,
                    height: 1.35,
                    color: Color(0xFF374151),
                  ),
                ),
                if (hindi.isNotEmpty)
                  Text(
                    hindi,
                    style: const TextStyle(
                      fontSize: 12.5,
                      height: 1.35,
                      color: Color(0xFF374151),
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

class _Bullet extends StatelessWidget {
  final String text;

  const _Bullet(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(fontSize: 15, height: 1.4)),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 13.5, height: 1.45),
            ),
          ),
        ],
      ),
    );
  }
}
