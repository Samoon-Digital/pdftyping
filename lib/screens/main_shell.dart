import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/ad_service.dart';
import 'home_page.dart';
import 'saved_pdfs_screen.dart'
    if (dart.library.html) 'saved_pdfs_screen_web.dart';
import 'get_pdfs_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;
  final _savedKey = GlobalKey<SavedPdfsScreenState>();

  void _onPdfSaved() {
    final shouldShowInterstitial = _currentIndex != 1;
    _savedKey.currentState?.refresh();
    setState(() => _currentIndex = 1);
    if (shouldShowInterstitial) {
      AdService.instance.showInterstitialForSaved(priority: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) return const _WebHome();

    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          HomePage(onPdfSaved: _onPdfSaved),
          SavedPdfsScreen(key: _savedKey),
          const GetPdfsScreen(),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 16,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: NavigationBar(
            selectedIndex: _currentIndex,
            onDestinationSelected: (i) {
              if (i == _currentIndex) return;
              setState(() => _currentIndex = i);
              if (i == 1) AdService.instance.showInterstitialForSaved();
            },
            backgroundColor: Colors.white,
            indicatorColor: primary.withValues(alpha: 0.12),
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home_rounded),
                label: 'होम',
              ),
              NavigationDestination(
                icon: Icon(Icons.bookmark_outline_rounded),
                selectedIcon: Icon(Icons.bookmark_rounded),
                label: 'Saved',
              ),
              NavigationDestination(
                icon: Icon(Icons.picture_as_pdf_outlined),
                selectedIcon: Icon(Icons.picture_as_pdf_rounded),
                label: 'Get PDFs',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Web entry: shows mobile app-download popup on narrow screens ──────────
class _WebHome extends StatefulWidget {
  const _WebHome();
  @override
  State<_WebHome> createState() => _WebHomeState();
}

class _WebHomeState extends State<_WebHome> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && MediaQuery.sizeOf(context).width < 768) {
        showDialog(
          context: context,
          barrierDismissible: false,
          barrierColor: Colors.black87,
          builder: (_) => const _MobileAppDialog(),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) => const HomePage();
}

class _MobileAppDialog extends StatelessWidget {
  const _MobileAppDialog();

  static const _playUrl =
      'https://play.google.com/store/apps/details?id=com.samoondigital.pdftyping&hl=en_IN';

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(20),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 360),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 32)],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Header ──
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 22),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF1565C0), Color(0xFF0D47A1)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: const Column(
                  children: [
                    Icon(
                      Icons.picture_as_pdf_rounded,
                      size: 60,
                      color: Colors.white,
                    ),
                    SizedBox(height: 12),
                    Text(
                      'PDF Typing',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'बेहतर अनुभव के लिए ऐप डाउनलोड करें',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                        fontFamily: 'NotoSansDevanagari',
                      ),
                    ),
                  ],
                ),
              ),
              // ── Body ──
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                child: Column(
                  children: [
                    _feat(Icons.offline_bolt_rounded, 'ऑफलाइन भी काम करता है'),
                    const SizedBox(height: 8),
                    _feat(Icons.save_alt_rounded, 'PDF सेव और शेयर करें'),
                    const SizedBox(height: 8),
                    _feat(
                      Icons.flash_on_rounded,
                      'तेज़, आसान और बिल्कुल मुफ्त',
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => launchUrl(
                          Uri.parse(_playUrl),
                          mode: LaunchMode.externalApplication,
                        ),
                        icon: const Icon(Icons.android_rounded, size: 22),
                        label: const Text(
                          'Google Play से डाउनलोड करें',
                          style: TextStyle(
                            fontFamily: 'NotoSansDevanagari',
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00875A),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text(
                        'वेबसाइट पर जारी रखें',
                        style: TextStyle(
                          color: Color(0xFF9E9E9E),
                          fontSize: 13,
                          fontFamily: 'NotoSansDevanagari',
                        ),
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

  Widget _feat(IconData icon, String label) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 2),
    child: Row(
      children: [
        Icon(icon, color: const Color(0xFF1565C0), size: 18),
        const SizedBox(width: 10),
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'NotoSansDevanagari',
            fontSize: 14,
            color: Color(0xFF374151),
          ),
        ),
      ],
    ),
  );
}
