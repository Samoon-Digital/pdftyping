import 'package:flutter/material.dart';
import '../ads/interstitial_manager.dart';
import '../widgets/banner_ad_scaffold.dart';

class MobileNumberUpdateScreen extends StatefulWidget {
  const MobileNumberUpdateScreen({super.key});

  @override
  State<MobileNumberUpdateScreen> createState() =>
      _MobileNumberUpdateScreenState();
}

class _MobileNumberUpdateScreenState extends State<MobileNumberUpdateScreen> {
  @override
  void initState() {
    super.initState();
    InterstitialManager.instance.showIfAvailable();
  }

  @override
  Widget build(BuildContext context) {
    return BannerAdScaffold(
      appBar: AppBar(title: const Text('मोबाईल नंबर संसोधन')),
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
              'Jis bhi vyakti ko apne Aadhaar Card me naya mobile number update karna hai ya purana number badalwana hai, usko swayam Aadhaar Centre par Aadhaar Card ke saath jana hoga. Number update process ke dauran aapka live photo ya fingerprint me se koi ek liya jayega. Aadhaar Centre jaaye bina mobile number update nahi hota. Mobile number update ke liye kisi extra document ki zarurat nahi hoti, kewal Aadhaar Card chahiye hota hai.\n\nजिस भी व्यक्ति को अपने आधार कार्ड में नया मोबाइल नंबर अपडेट करना है या पुराना नंबर बदलवाना है, उसे स्वयं आधार केंद्र पर आधार कार्ड के साथ जाना होगा। नंबर अपडेट प्रक्रिया के दौरान आपका लाइव फोटो या फिंगरप्रिंट में से कोई एक लिया जाएगा। आधार केंद्र जाए बिना मोबाइल नंबर अपडेट नहीं होता। मोबाइल नंबर अपडेट के लिए किसी अतिरिक्त दस्तावेज की जरूरत नहीं होती, केवल आधार कार्ड चाहिए होता है।',
              style: TextStyle(
                fontSize: 13.6,
                height: 1.5,
                color: Color(0xFF111827),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
