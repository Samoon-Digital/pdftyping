import 'package:flutter/material.dart';
import '../ads/shared_native_ad.dart';
import '../ads/interstitial_manager.dart';

class FingerFaceBiometricUpdateScreen extends StatefulWidget {
  const FingerFaceBiometricUpdateScreen({super.key});

  @override
  State<FingerFaceBiometricUpdateScreen> createState() =>
      _FingerFaceBiometricUpdateScreenState();
}

class _FingerFaceBiometricUpdateScreenState
    extends State<FingerFaceBiometricUpdateScreen> {
  @override
  void initState() {
    super.initState();
    InterstitialManager.instance.showIfAvailable();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('अंगूठा और फोटो संसोधन')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFBFDBFE)),
            ),
            child: const Text(
              'Important / महत्वपूर्ण',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE5E7EB)),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF111827).withValues(alpha: 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: const Text(
              'Finger Face Biometric Update - अंगूठा और फोटो संसोधन Aadhaar Centre par karaya ja sakta hai. Iske liye alag se koi document dene ki zarurat nahi hoti, sirf Aadhaar Card dena hota hai.\n\nफिंगर और फेस बायोमेट्रिक अपडेट आधार केंद्र पर कराया जा सकता है। इसके लिए अलग से कोई दस्तावेज देने की जरूरत नहीं होती, केवल आधार कार्ड देना होता है।',
              style: TextStyle(
                fontSize: 13.6,
                height: 1.5,
                color: Color(0xFF111827),
              ),
            ),
          ),
          const SizedBox(height: 12),
          const SharedNativeAd(placementId: 'finger_face_after_card'),
        ],
      ),
    );
  }
}
