import 'package:flutter/material.dart';
import '../ads/interstitial_manager.dart';
import '../widgets/banner_ad_scaffold.dart';

class FeesUpdateScreen extends StatefulWidget {
  const FeesUpdateScreen({super.key});

  @override
  State<FeesUpdateScreen> createState() => _FeesUpdateScreenState();
}

class _FeesUpdateScreenState extends State<FeesUpdateScreen> {
  @override
  void initState() {
    super.initState();
    InterstitialManager.instance.showIfAvailable();
  }

  @override
  Widget build(BuildContext context) {
    return BannerAdScaffold(
      appBar: AppBar(title: const Text('फीस विवरण / Fees Details')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          _TopHeader(),
          SizedBox(height: 12),
          _FeeSectionCard(
            title: '(1) Biometric Update - बायोमेट्रिक अपडेट',
            description:
                'Update of enrolled biometrics (fingerprint, iris and photo)\nदर्ज बायोमेट्रिक (फिंगरप्रिंट, आईरिस और फोटो) का अपडेट',
            points: [
              'If done first time between age 5 to 7 years: Free\nयदि पहली बार उम्र 5 से 7 वर्ष के बीच किया जाता है: निःशुल्क',
              'If done first or second time between age 15 to 17 years: Free\nयदि पहली या दूसरी बार उम्र 15 से 17 वर्ष के बीच किया जाता है: निःशुल्क',
              'If done otherwise: Rs 125\nअन्य स्थिति में: Rs 125',
              'Special note: If done between age 7 to 15 years, free till 30.9.2026\nविशेष सूचना: उम्र 7 से 15 वर्ष के बीच कराने पर 30.9.2026 तक निःशुल्क',
            ],
          ),
          SizedBox(height: 12),
          _FeeSectionCard(
            title: '(2) Demographic Update - जनसांख्यिकीय अपडेट',
            description:
                'Update of enrolled name, gender, date of birth, address, mobile number or email address (single or combination)\nदर्ज नाम, लिंग, जन्मतिथि, पता, मोबाइल नंबर या ईमेल (एकल या संयोजन) का अपडेट',
            points: [
              'If done at the same time with biometric update: Free\nयदि बायोमेट्रिक अपडेट के साथ एक ही समय पर किया जाए: निःशुल्क',
              'If done separately: Rs 75\nयदि अलग से किया जाए: Rs 75',
            ],
          ),
          SizedBox(height: 12),
          _FeeSectionCard(
            title: '(3) Document Update - दस्तावेज अपडेट',
            description:
                'Submission of documents as proof of identity and address in support of enrolled details\nदर्ज विवरण के समर्थन में पहचान और पते के प्रमाण दस्तावेज जमा करना',
            points: [
              'Using myAadhaar portal (https://myaadhaar.uidai.gov.in/du): Free (till 14.06.2026)\nmyAadhaar पोर्टल से: निःशुल्क (14.06.2026 तक)',
              'At Aadhaar centre: Rs 75\nआधार केंद्र पर: Rs 75',
            ],
          ),
          SizedBox(height: 12),
          _FootNoteCard(),
        ],
      ),
    );
  }
}

class _TopHeader extends StatelessWidget {
  const _TopHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFBFDBFE)),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Aadhaar Enrollment: Free',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
          ),
          SizedBox(height: 4),
          Text(
            'आधार नामांकन: निःशुल्क',
            style: TextStyle(fontSize: 14.2, fontWeight: FontWeight.w600),
          ),
          SizedBox(height: 8),
          Text(
            'Aadhaar Update Charges',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
          SizedBox(height: 2),
          Text(
            'आधार अपडेट शुल्क',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _FeeSectionCard extends StatelessWidget {
  final String title;
  final String description;
  final List<String> points;

  const _FeeSectionCard({
    required this.title,
    required this.description,
    required this.points,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFD1D5DB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: const TextStyle(
              fontSize: 13.3,
              height: 1.45,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 8),
          for (int i = 0; i < points.length; i++) ...[
            Text(
              '(${i + 1}) ${points[i]}',
              style: const TextStyle(
                fontSize: 13.2,
                height: 1.45,
                color: Color(0xFF111827),
              ),
            ),
            if (i != points.length - 1) const SizedBox(height: 6),
          ],
        ],
      ),
    );
  }
}

class _FootNoteCard extends StatelessWidget {
  const _FootNoteCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFDE68A)),
      ),
      child: const Text(
        'Mandatory Biometric Update (MBU) shall be stand-alone transaction only; it may not be clubbed with any other transaction.\n\nअनिवार्य बायोमेट्रिक अपडेट (MBU) केवल अलग (स्टैंड-अलोन) लेनदेन के रूप में होगा; इसे किसी अन्य लेनदेन के साथ जोड़ा नहीं जा सकता।',
        style: TextStyle(
          fontSize: 12.9,
          height: 1.45,
          fontStyle: FontStyle.italic,
        ),
      ),
    );
  }
}
