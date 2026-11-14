import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/localization/app_localizations.dart';
import '../../core/supabase/app_release_service.dart';
import '../widgets/app_update_dialog.dart';
import 'family/family_profiles_screen.dart';
import 'history/medication_history_screen.dart';
import 'home/home_dashboard_screen.dart';
import 'medicines/medicines_list_screen.dart';

class MainLayout extends ConsumerStatefulWidget {
  final int initialTab;

  const MainLayout({super.key, this.initialTab = 0});

  @override
  ConsumerState<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends ConsumerState<MainLayout>
    with WidgetsBindingObserver {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialTab;
    WidgetsBinding.instance.addObserver(this);

    // Initial non-blocking update check shortly after UI renders
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkRemoteUpdates();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkRemoteUpdates();
    }
  }

  Future<void> _checkRemoteUpdates() async {
    final controller = ref.read(appReleaseProvider.notifier);
    await controller.checkForUpdates();

    if (!mounted) return;
    final releaseState = ref.read(appReleaseProvider);

    if (releaseState.isUpdateAvailable &&
        releaseState.latestRelease != null &&
        !releaseState.hasShownDialog) {
      showDialog(
        context: context,
        barrierDismissible: !releaseState.isMandatoryUpdate,
        builder: (dialogCtx) => AppUpdateDialog(
          release: releaseState.latestRelease!,
          isMandatory: releaseState.isMandatoryUpdate,
        ),
      );
    }
  }

  final List<Widget> _screens = const [
    HomeDashboardScreen(),
    MedicinesListScreen(),
    FamilyProfilesScreen(),
    MedicationHistoryScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);

    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.home_outlined),
            activeIcon: const Icon(Icons.home_rounded),
            label: loc?.translate('navHome') ?? 'Home',
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.medication_outlined),
            activeIcon: const Icon(Icons.medication_rounded),
            label: loc?.translate('navMedicines') ?? 'Medicines',
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.people_outline_rounded),
            activeIcon: const Icon(Icons.people_rounded),
            label: loc?.translate('navFamily') ?? 'Family',
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.history_outlined),
            activeIcon: const Icon(Icons.history_rounded),
            label: loc?.translate('navHistory') ?? 'History',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: loc?.translate('addMedicine') ?? 'Add Medicine',
        onPressed: () {
          context.push('/add-edit-medicine');
        },
        child: const Icon(Icons.add_rounded, size: 28),
      ),
    );
  }
}
