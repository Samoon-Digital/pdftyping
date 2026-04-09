import 'package:flutter/material.dart';
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
