import 'package:flutter/material.dart';
import '../ads/app_open_ad_manager.dart';
import 'home_page.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AppOpenAdManager.instance.setHomeTabVisible(true);
    });
  }

  @override
  void dispose() {
    AppOpenAdManager.instance.setHomeTabVisible(false);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return const HomePage();
  }
}
