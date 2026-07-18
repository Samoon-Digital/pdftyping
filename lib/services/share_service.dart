import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class ShareService {
  const ShareService._();

  static const String playStoreUrl =
      'https://play.google.com/store/apps/details?id=com.samoondigital.pdftyping';

  static const String _shareText = 'Aadhaar Update Guide\n$playStoreUrl';

  static Future<void> shareApp() async {
    try {
      final iconFile = await _prepareLauncherIcon();
      await SharePlus.instance.share(
        ShareParams(
          text: _shareText,
          subject: 'Aadhaar Update Guide',
          title: 'Share Aadhaar Update Guide',
          files: [
            XFile(
              iconFile.path,
              mimeType: 'image/png',
              name: 'aadhaar_update_guide.png',
            ),
          ],
        ),
      );
    } catch (_) {
      await SharePlus.instance.share(
        ShareParams(
          text: _shareText,
          subject: 'Aadhaar Update Guide',
          title: 'Share Aadhaar Update Guide',
        ),
      );
    }
  }

  static Future<File> _prepareLauncherIcon() async {
    final data = await rootBundle.load('assets/launcher.png');
    final tempDirectory = await getTemporaryDirectory();
    final file = File('${tempDirectory.path}/aadhaar_update_guide.png');
    await file.writeAsBytes(data.buffer.asUint8List(), flush: true);
    return file;
  }
}
