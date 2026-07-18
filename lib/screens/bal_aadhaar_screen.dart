import 'package:flutter/material.dart';
import '../ads/shared_native_ad.dart';
import '../ads/interstitial_manager.dart';

class BalAadhaarScreen extends StatefulWidget {
  const BalAadhaarScreen({super.key});

  @override
  State<BalAadhaarScreen> createState() => _BalAadhaarScreenState();
}

class _BalAadhaarScreenState extends State<BalAadhaarScreen> {
  bool _noticeVisible = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _noticeVisible) {
        showDialog<void>(
          context: context,
          barrierDismissible: false,
          builder: (dialogContext) => AlertDialog(
            insetPadding: const EdgeInsets.all(20),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(22),
            ),
            title: const Text('महत्वपूर्ण सूचना / Important Notice'),
            content: const SingleChildScrollView(
              child: Text(
                'बच्चे के आधार बनाते समय माता या पिता किसी एक का आधार कार्ड और फिंगरप्रिंट लगेगा और बच्चे के आधार कार्ड पर वही मोबाईल नंबर अपडेट होगा जो नंबर माता या पिता के आधार  में मोजूद होगा\n\nअगर आप बच्चे के आधार में अपना आधार लगा रहे हैं तो ध्यान दे आपके आधार में पहले से आधार में मोबाईल नंबर  रजिस्टर होना चाहिए  जिससे बच्चे का आधार कार्ड डाउनलोड कर पाएंगे \nअगर आपके आधार में नंबर नहीं लगा है तो पहले नंबर अपडेट कराएँ',
              ),
            ),
            actions: [
              FilledButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                  if (mounted) {
                    setState(() => _noticeVisible = false);
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted) {
                        InterstitialManager.instance.showIfAvailable();
                      }
                    });
                  }
                },
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('बाल आधार')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
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
                    Icon(
                      Icons.notifications_active_rounded,
                      color: Colors.white,
                    ),
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
                  'बाल आधार',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'जिनकी उम्र दस्तावेज के अनुसार 5 साल अभी पूरे नहीं हुए हैं सिर्फ उनका नया आधार बनता है 5 साल से 1 भी दिन ज्यादा होने पर बाल आधार नहीं बनेगा',
                  style: TextStyle(
                    color: Colors.white,
                    height: 1.45,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _SectionCard(
            title: 'परिवार के मुखिया के अनुसार दस्तावेज',
            accent: const Color(0xFF0F766E),
            children: const [
              _Bullet(
                '1 - जन्म प्रमाण पत्र - Birth certificate issued under the Registration of Births and Deaths Act, 1969 and the rules made thereunder',
              ),
              _Bullet(
                'यह सरकार द्वारा जारी आधिकारिक जन्म प्रमाण पत्र होता है।',
              ),
              _Bullet(
                'इसमें बच्चे का नाम, जन्म तिथि, जन्म स्थान, माता-पिता का नाम आदि दर्ज होता है।',
              ),
              _Bullet('यही सबसे मान्य (valid) जन्म प्रमाण पत्र माना जाता है।'),
            ],
          ),
          const SizedBox(height: 12),
          const SharedNativeAd(placementId: 'child_aadhaar_after_first_card'),
          const SizedBox(height: 12),
          _SectionCard(
            title:
                '2- भारतीय पासपोर्ट - Valid Indian Passport (only applicable for NRIs)',
            accent: const Color(0xFF1565C0),
            children: const [
              _Bullet('यह सुविधा खास तौर पर NRI लोगों के लिए है।'),
              _Bullet('पासपोर्ट एक्सपायर नहीं होना चाहिए।'),
              _Bullet('पासपोर्ट में भारतीय नागरिकता होनी चाहिए।'),
              _Bullet('छोटे NRI बच्चे के मामले में:'),
              _Bullet('बच्चे का अपना Indian Passport हो सकता है'),
              _Bullet(
                'या कई बार माता-पिता का Indian Passport + बच्चे का Birth Certificate मांगा जाता है',
              ),
            ],
          ),
          const SizedBox(height: 12),
          _SectionCard(
            title:
                '3- UIDAI मानक प्रारूप में जिला बाल संरक्षण अधिकारी (DCPO) द्वारा जारी प्रमाण पत्र',
            accent: const Color(0xFFB91C1C),
            children: const [
              _Bullet(
                'Certificate issued on UIDAI Standard Certificate format by District Child Protection Officer (DCPO) along with the order of placement of child in a Child Care Institution (CCI) in Form 18 of the Juvenile Justice Model Rules, 2016 (as amended in 2022)',
              ),
              _Bullet(
                'यह एक सरकारी प्रमाण पत्र होता है, जो उन बच्चों के लिए बनाया जाता है जो किसी Child Care Institution (CCI) यानी बाल देखभाल गृह/संस्था में रह रहे होते हैं।',
              ),
              _Bullet(
                'इसमें District Child Protection Unit के DCPO (District Child Protection Officer) बच्चे की पहचान और देखभाल की पुष्टि करते हैं। प्रमाण पत्र UIDAI के तय फॉर्मेट में जारी किया जाता है।',
              ),
              _Bullet(
                'इसके साथ “Form 18” लगाया जाता है, जो यह साबित करता है कि बच्चे को कानून के अनुसार Child Care Institution में रखा गया है। यह नियम Juvenile Justice Model Rules, 2016 (2022 संशोधन) के तहत लागू होता है।',
              ),
              _Bullet(
                'यह दस्तावेज़ मुख्य रूप से:अनाथ बच्चों, छोड़े गए (abandoned) बच्चों , या जिन बच्चों के पास सामान्य पहचान/पता प्रमाण नहीं होता',
              ),
            ],
          ),
          const SizedBox(height: 12),
          _SectionCard(
            title:
                '4- OCI/LTV/Nepal/Bhutan व अन्य विदेशी नागरिकों के लिए दस्तावेज (पहचान का प्रमाण / पते का प्रमाण / जन्म का प्रमाण)',
            accent: const Color(0xFF374151),
            children: const [
              _Bullet(
                'जो विदेशी लोग (OCI, LTV, नेपाल-भूटान नागरिक आदि) पिछले 12 महीनों में कम से कम 182 दिन भारत में रहे हैं, उन्हें आधार बनवाने के लिए ये दस्तावेज़ देने होंगे।',
              ),
              _Bullet(
                'Documents applicable for Overseas Citizen of India (OCI) cardholders, Long Term Visa (LTV) holders, nationals of Nepal and Bhutan and other foreign nationals who have stayed in India for 182 days or more in the immediately preceding 12 months.',
              ),
              SizedBox(height: 6),
              _PoiPoaPobTable(),
              SizedBox(height: 8),
              Text(
                '* पते का प्रमाण (Proof of Address) में ✖* का अर्थ है कि यह श्रेणी सामान्यतः भारतीय पता प्रमाण नहीं मानी जाती।',
                style: TextStyle(fontSize: 12.5, color: Color(0xFF4B5563)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PoiPoaPobTable extends StatelessWidget {
  const _PoiPoaPobTable();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildDocumentItem(
          slNo: '5',
          document:
              'Overseas Citizen of India (विदेश में रहने वाले भारतीय मूल के नागरिक) कार्ड रखने वाले व्यक्ति के लिए वैध विदेशी पासपोर्ट के साथ OCI कार्ड दिखाना जरूरी होगा।\nFor Overseas Citizen of India (OCI) cardholders - Valid foreign passport (along with OCI card)',
          poi: '☑',
          poa: '☒*',
          pob: '☑',
        ),
        _buildDocumentItem(
          slNo: '6',
          document:
              'नेपाल और भूटान के नागरिकों के लिए / For nationals of Nepal and Bhutan\n(a) नेपाल/भूटान का पासपोर्ट। Passport of Nepal/Bhutan\n(b) नेपाल और भूटान के नागरिकों के लिए नागरिकता प्रमाण पत्र या वैध पहचान दस्तावेज के साथ उनके दूतावास (भारत में) द्वारा जारी सीमित समय वाला फोटो पहचान पत्र भी देना जरूरी है।\n(b) Valid Nepalese/Bhutanese Citizenship Certificate (along with Limited validity Photo Identity Certificate issued by Nepalese Mission / Royal Bhutanese Mission in India)',
          poi: '☑',
          poa: '☒*',
          pob: '☑',
        ),
        _buildDocumentItem(
          slNo: '7',
          document:
              'लॉन्ग टर्म वीजा (Long Term Visa) रखने वाले व्यक्ति के लिए — जो अफगानिस्तान, बांग्लादेश और पाकिस्तान के अल्पसंख्यक समुदायों (हिंदू, सिख, बौद्ध, जैन, पारसी और ईसाई) से हैं और भारत में रहने के लिए भारत सरकार द्वारा वैध लंबी अवधि का वीजा प्राप्त किया है।\nFor Long Term Visa holders - Valid Long Term Visa (LTV), issued to minority communities of Afghanistan, Bangladesh and Pakistan (Hindus, Sikhs, Buddhists, Jains, Parsis and Christians)',
          poi: '☑',
          poa: '☑*',
          pob: '☑',
        ),
        _buildDocumentItem(
          slNo: '8',
          document:
              'अन्य विदेशी नागरिकों के लिए — वैध विदेशी पासपोर्ट के साथ वैध वीजा देना जरूरी होगा।\nFor other foreign nationals - Valid foreign passport (along with valid visa)',
          poi: '☑',
          poa: '☒*',
          pob: '☑',
        ),
      ],
    );
  }

  Widget _buildDocumentItem({
    required String slNo,
    required String document,
    required String poi,
    required String poa,
    required String pob,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFD1D5DB)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$slNo. $document',
              style: const TextStyle(fontSize: 12.5, height: 1.4),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildStatusCell(
                    'पहचान का प्रमाण - Proof of identity',
                    poi,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildStatusCell(
                    'पते का प्रमाण - Proof of Address',
                    poa,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildStatusCell(
                    'जन्म का प्रमाण - Proof of Birth',
                    pob,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCell(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        children: [
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: Color(0xFF374151),
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Color accent;
  final List<Widget> children;

  const _SectionCard({
    required this.title,
    required this.accent,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: accent.withValues(alpha: 0.14)),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.10),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.check_circle_rounded, size: 18, color: accent),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ...children,
          ],
        ),
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
