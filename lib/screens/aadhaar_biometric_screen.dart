import 'package:flutter/material.dart';

class AadhaarBiometricScreen extends StatefulWidget {
  const AadhaarBiometricScreen({super.key});

  @override
  State<AadhaarBiometricScreen> createState() => _AadhaarBiometricScreenState();
}

class _AadhaarBiometricScreenState extends State<AadhaarBiometricScreen> {
  bool _showStepTwo = false;

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
            _StepCard(
              title: 'Final Step - Documents List',
              accent: const Color(0xFF1565C0),
              child: const Text(
                'यहां आगे documents list बनाई जाएगी।\n\nअभी आपने important notification step पूरा कर लिया है।',
                style: TextStyle(fontSize: 13.5, height: 1.45),
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => setState(() => _showStepTwo = false),
              icon: const Icon(Icons.arrow_back_rounded),
              label: const Text('Back - सूचना पर लौटें'),
            ),
          ] else ...[
            _StepCard(
              title: 'महत्वपूर्ण सूचना / Important Notice',
              accent: const Color(0xFFB91C1C),
              child: const Column(
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

class _StepCard extends StatelessWidget {
  final String title;
  final Color accent;
  final Widget child;

  const _StepCard({
    required this.title,
    required this.accent,
    required this.child,
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
                Icon(Icons.verified_rounded, size: 18, color: accent),
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
            child,
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
