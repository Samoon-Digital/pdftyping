import 'package:flutter/material.dart';

/// Web-only version of SavedPdfsScreen.
/// On web, PDFs are downloaded directly by the browser,
/// so there is no local file listing.
class SavedPdfsScreen extends StatefulWidget {
  const SavedPdfsScreen({super.key});

  @override
  State<SavedPdfsScreen> createState() => SavedPdfsScreenState();
}

class SavedPdfsScreenState extends State<SavedPdfsScreen> {
  /// No-op on web — keeps the same public API as the mobile version.
  void refresh() {}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Saved PDFs')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.cloud_download_rounded,
                size: 72,
                color: Colors.grey.shade300,
              ),
              const SizedBox(height: 16),
              Text(
                'वेब पर PDF सीधे डाउनलोड होती हैं',
                style: TextStyle(
                  fontFamily: 'NotoSansDevanagari',
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade500,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'PDF बनाने के बाद आपके ब्राउज़र में\nडाउनलोड हो जाएगी।',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'NotoSansDevanagari',
                  fontSize: 14,
                  color: Colors.grey.shade400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
