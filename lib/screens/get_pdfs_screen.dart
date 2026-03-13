import 'package:flutter/material.dart';

class GetPdfsScreen extends StatelessWidget {
  const GetPdfsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(title: const Text('Get PDFs')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: primary.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.rocket_launch_rounded,
                  size: 52,
                  color: primary,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Coming Soon',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF212121),
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'यहाँ आप जल्द ही\n'
                'रेडीमेड PDF डाउनलोड कर पाएंगे।',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'NotoSansDevanagari',
                  fontSize: 15,
                  height: 1.6,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 32),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.update_rounded, color: primary, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'अगले अपडेट में उपलब्ध',
                      style: TextStyle(
                        fontFamily: 'NotoSansDevanagari',
                        color: primary,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
