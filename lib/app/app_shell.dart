import 'package:flutter/material.dart';

import '../features/dashboard/presentation/dashboard_screen.dart';
import '../features/education/presentation/education_screen.dart';
import '../features/finance/presentation/finance_screen.dart';
import '../features/inventory/presentation/inventory_screen.dart';
import '../features/logbook/presentation/logbook_screen.dart';
import '../features/profile/models/app_user.dart';
import '../features/profile/presentation/profile_screen.dart';
import '../features/schedule/presentation/schedule_screen.dart';

class AppShell extends StatefulWidget {
  const AppShell({required this.profile, super.key});

  final AppUser profile;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _selectedIndex = 0;

  List<_Destination> get _destinations {
    final items = <_Destination>[
      _Destination(
        label: 'Dashboard',
        icon: Icons.dashboard_outlined,
        selectedIcon: Icons.dashboard,
        builder: () => DashboardScreen(profile: widget.profile),
      ),
      if (widget.profile.canManageOperations)
        _Destination(
          label: 'Logbook',
          icon: Icons.menu_book_outlined,
          selectedIcon: Icons.menu_book,
          builder: () => LogbookScreen(profile: widget.profile),
        ),
      if (widget.profile.canManageOperations)
        _Destination(
          label: 'Inventaris',
          icon: Icons.inventory_2_outlined,
          selectedIcon: Icons.inventory_2,
          builder: () => InventoryScreen(profile: widget.profile),
        ),
      if (widget.profile.canManageOperations)
        _Destination(
          label: 'Jadwal',
          icon: Icons.event_note_outlined,
          selectedIcon: Icons.event_note,
          builder: () => ScheduleScreen(profile: widget.profile),
        ),
      _Destination(
        label: 'Edukasi',
        icon: Icons.school_outlined,
        selectedIcon: Icons.school,
        builder: () => EducationScreen(profile: widget.profile),
      ),
      if (widget.profile.isAdmin)
        _Destination(
          label: 'Keuangan',
          icon: Icons.account_balance_wallet_outlined,
          selectedIcon: Icons.account_balance_wallet,
          builder: () => FinanceScreen(profile: widget.profile),
        ),
      _Destination(
        label: 'Profil',
        icon: Icons.person_outline,
        selectedIcon: Icons.person,
        builder: () => ProfileScreen(profile: widget.profile),
      ),
    ];
    return items;
  }

  void _select(int index) {
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final destinations = _destinations;
    if (_selectedIndex >= destinations.length) _selectedIndex = 0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final desktop = constraints.maxWidth >= 900;
        final content = destinations[_selectedIndex].builder();

        if (desktop) {
          return Scaffold(
            body: Row(
              children: [
                SizedBox(
                  width: 250,
                  child: Material(
                    color: Theme.of(context).colorScheme.surface,
                    child: _NavigationPanel(
                      profile: widget.profile,
                      destinations: destinations,
                      selectedIndex: _selectedIndex,
                      onSelected: _select,
                    ),
                  ),
                ),
                const VerticalDivider(width: 1),
                Expanded(child: content),
              ],
            ),
          );
        }

        return Scaffold(
          appBar: AppBar(title: Text(destinations[_selectedIndex].label)),
          drawer: Drawer(
            child: _NavigationPanel(
              profile: widget.profile,
              destinations: destinations,
              selectedIndex: _selectedIndex,
              onSelected: (index) {
                Navigator.pop(context);
                _select(index);
              },
            ),
          ),
          body: content,
        );
      },
    );
  }
}

class _Destination {
  const _Destination({
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.builder,
  });

  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final Widget Function() builder;
}

class _NavigationPanel extends StatelessWidget {
  const _NavigationPanel({
    required this.profile,
    required this.destinations,
    required this.selectedIndex,
    required this.onSelected,
  });

  final AppUser profile;
  final List<_Destination> destinations;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            color: Theme.of(context).colorScheme.primary,
            child: Row(
              children: [
                Image.asset(
                  'lib/assets/logo.png',
                  width: 46,
                  height: 46,
                  errorBuilder: (_, _, _) =>
                      const Icon(Icons.eco, color: Colors.white, size: 42),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'SeiCycle',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 19,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Kebun Sei',
                        style: TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 12),
              itemCount: destinations.length,
              itemBuilder: (context, index) {
                final destination = destinations[index];
                final selected = index == selectedIndex;
                return ListTile(
                  selected: selected,
                  leading: Icon(
                    selected ? destination.selectedIcon : destination.icon,
                  ),
                  title: Text(destination.label),
                  onTap: () => onSelected(index),
                );
              },
            ),
          ),
          const Divider(height: 1),
          ListTile(
            leading: CircleAvatar(
              backgroundImage: profile.photoUrl.isEmpty
                  ? null
                  : NetworkImage(profile.photoUrl),
              child: profile.photoUrl.isEmpty ? const Icon(Icons.person) : null,
            ),
            title: Text(
              profile.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(profile.role),
          ),
        ],
      ),
    );
  }
}
