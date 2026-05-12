import 'package:flutter/material.dart';

class AadhaarBiometricScreen extends StatefulWidget {
  const AadhaarBiometricScreen({super.key});

  @override
  State<AadhaarBiometricScreen> createState() => _AadhaarBiometricScreenState();
}

class _AadhaarBiometricScreenState extends State<AadhaarBiometricScreen> {
  bool _showStepTwo = false;
  final _expandedSections = {'poi': false, 'poa': false, 'pob': false};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('आधार बायोमेट्रिक')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _HeaderCard(stepText: _showStepTwo ? 'Step 2 of 2' : 'Step 1 of 2'),
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
                'यह सूची केवल 5 साल से 18 साल उम्र के लिए मान्य है। 5 साल से कम उम्र वालों के लिए होमपेज से बाल आधार स्क्रीन में जाएं।',
                style: TextStyle(
                  fontSize: 12.5,
                  height: 1.4,
                  color: Color(0xFF78350F),
                ),
              ),
            ),
            const SizedBox(height: 16),
            _DocumentSection(
              title: 'Proof of Identity - पहचान का प्रमाण',
              accent: const Color(0xFFC7D2FE),
              borderAccent: const Color(0xFF1565C0),
              isExpanded: _expandedSections['poi']!,
              onToggle: () => setState(
                () => _expandedSections['poi'] = !_expandedSections['poi']!,
              ),
              documents: const [
                '1 - Valid Indian Passport - वैध भारतीय पासपोर्ट',
                '2 - Domicile Certificate issued by State Government - निवास प्रमाण पत्र तहसील स्तर / राज्य सरकार द्वारा निर्गत',
                '3 - Scheduled Tribe (ST) / Scheduled Caste (SC) / Other Backward Caste (OBC) Certificate issued by Central Government / State Government - केंद्र सरकार / राज्य सरकार / तहसील स्तर द्वारा जारी अनुसूचित जनजाति (ST) / अनुसूचित जाति (SC) / अन्य पिछड़ा वर्ग (OBC) जाति प्रमाण पत्र',
                '4 - Certificate issued on UIDAI Standard Certificate format by District Child Protection Officer (DCPO) with Form 18 of Juvenile Justice Model Rules, 2016 - UIDAI मानक प्रमाणपत्र प्रारूप पर जिला बाल संरक्षण अधिकारी (DCPO) द्वारा जारी प्रमाणपत्र, साथ में किशोर न्याय मॉडल नियम, 2016 (2022 में संशोधित) के प्रपत्र 18',
                '5 - Third gender / Transgender Identity Card / Certificate issued under Transgender Persons (Protection of Rights) Act, 2019 - ट्रांसजेंडर व्यक्ति (अधिकारों का संरक्षण) अधिनियम, 2019 तथा उसके अंतर्गत बनाए गए नियमों के तहत जारी तृतीय लिंग / ट्रांसजेंडर पहचान पत्र / प्रमाणपत्र',
              ],
            ),
            const SizedBox(height: 12),
            _DocumentSection(
              title: 'Proof of Address - पते का प्रमाण',
              accent: const Color(0xFFDCFCE7),
              borderAccent: const Color(0xFF0F766E),
              isExpanded: _expandedSections['poa']!,
              onToggle: () => setState(
                () => _expandedSections['poa'] = !_expandedSections['poa']!,
              ),
              documents: const ['Documents will be populated here'],
            ),
            const SizedBox(height: 12),
            _DocumentSection(
              title: 'Proof of Birth - जन्म तिथि का प्रमाण',
              accent: const Color(0xFFFFEDD5),
              borderAccent: const Color(0xFFF59E0B),
              isExpanded: _expandedSections['pob']!,
              onToggle: () => setState(
                () => _expandedSections['pob'] = !_expandedSections['pob']!,
              ),
              documents: const ['Documents will be populated here'],
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
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.verified_rounded,
                          size: 18,
                          color: Color(0xFFB91C1C),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: const Text(
                            'महत्वपूर्ण सूचना / Important Notice',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _Bullet(
                          'आधार नामांकन के लिए 4 आवश्यक दस्तावेज देने होते हैं। एक भी दस्तावेज कम होने पर या सूची के अनुसार ना होने पर आपका नामांकन रद्द कर दिया जाएगा। इसका ध्यान रखें।',
                        ),
                        SizedBox(height: 4),
                        _Bullet(
                          '1 - Proof of Identity - पहचान का प्रमाण - इस दस्तावेज से पता चलता है कि जिसका आधार बनना है उसका नाम क्या है।',
                        ),
                        _Bullet(
                          '2 - Proof of Address - पते का प्रमाण - इस दस्तावेज से पता चलता है कि जिसका आधार बनना है उसका वास्तविक पता क्या है।',
                        ),
                        _Bullet(
                          '3 - Proof of Relationship - रिश्ते का प्रमाण - इस दस्तावेज से पता चलता है कि जिसका आधार बनना है वह किसका पुत्र/पुत्री/पत्नी है।',
                        ),
                        _Bullet(
                          '4 - Proof of Birth - जन्म तिथि का प्रमाण - इस दस्तावेज से पता चलता है कि जिसका आधार बनना है उसकी जन्म तिथि क्या है।',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => setState(() => _showStepTwo = true),
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
  final String stepText;

  const _HeaderCard({required this.stepText});

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
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
          const SizedBox(height: 10),
          Text(
            stepText,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w700,
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
                if (isExpanded) ...[
                  const SizedBox(height: 10),
                  ...documents
                      .map(
                        (doc) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '• ',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: borderAccent,
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  doc,
                                  style: const TextStyle(
                                    fontSize: 12.5,
                                    height: 1.4,
                                    color: Color(0xFF374151),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                      .toList(),
                ],
              ],
            ),
          ),
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
