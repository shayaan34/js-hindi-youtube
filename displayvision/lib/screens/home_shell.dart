import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme.dart';
import '../state/app_state.dart';
import 'admin_dashboard_screen.dart';
import 'clients_screen.dart';
import 'dashboard_screen.dart';
import 'gallery_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  static const _pages = [
    DashboardScreen(),
    ClientsScreen(),
    GalleryScreen(),
    AdminDashboardScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final syncing = context.select<AppState, bool>((s) => s.syncing);
    final pending = context.select<AppState, int>((s) => s.pendingSyncCount);

    return Scaffold(
      body: Stack(
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: KeyedSubtree(
                key: ValueKey(_index), child: _pages[_index]),
          ),
          if (syncing || pending > 0)
            Positioned(
              top: MediaQuery.of(context).padding.top + 6,
              right: 12,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: DVColors.surfaceRaised,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: DVColors.stroke),
                ),
                child: Row(children: [
                  const SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: DVColors.orange),
                  ),
                  const SizedBox(width: 6),
                  Text('Syncing to cloud',
                      style: Theme.of(context).textTheme.bodySmall),
                ]),
              ),
            ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.dashboard_outlined),
              selectedIcon: Icon(Icons.dashboard_rounded),
              label: 'Home'),
          NavigationDestination(
              icon: Icon(Icons.people_outline),
              selectedIcon: Icon(Icons.people_rounded),
              label: 'Clients'),
          NavigationDestination(
              icon: Icon(Icons.photo_library_outlined),
              selectedIcon: Icon(Icons.photo_library_rounded),
              label: 'Gallery'),
          NavigationDestination(
              icon: Icon(Icons.insights_outlined),
              selectedIcon: Icon(Icons.insights_rounded),
              label: 'Admin'),
        ],
      ),
    );
  }
}
