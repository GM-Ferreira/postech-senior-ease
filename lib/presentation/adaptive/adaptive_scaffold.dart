import 'package:flutter/material.dart';

/// Breakpoints para layout adaptativo.
/// - compact: mobile (< 600)
/// - expanded: desktop/web (≥ 600)
enum LayoutBreakpoint { compact, expanded }

LayoutBreakpoint getBreakpoint(double width) {
  if (width < 600) return LayoutBreakpoint.compact;
  return LayoutBreakpoint.expanded;
}

/// Scaffold adaptativo que exibe:
/// - **compact** (< 600): BottomNavigationBar
/// - **expanded** (≥ 600): NavigationDrawer (fixa na lateral, linha toda selecionável)
///
/// Aceita [navKeys] opcionais para permitir que o tutorial (coach_mark)
/// aponte diretamente para os itens de navegação.
class AdaptiveScaffold extends StatelessWidget {
  const AdaptiveScaffold({
    super.key,
    required this.currentIndex,
    required this.onDestinationSelected,
    required this.body,
    this.navKeys,
  });

  final int currentIndex;
  final ValueChanged<int> onDestinationSelected;
  final Widget body;

  /// Mapa opcional de índice → GlobalKey para o tutorial.
  /// Ex: {1: settingsKey, 2: configKey}
  final Map<int, GlobalKey>? navKeys;

  static const _destinations = [
    _Destination(
      icon: Icons.home_outlined,
      selectedIcon: Icons.home,
      label: 'Início',
    ),
    _Destination(
      icon: Icons.checklist_outlined,
      selectedIcon: Icons.checklist,
      label: 'Concluídas',
    ),
    _Destination(
      icon: Icons.settings_outlined,
      selectedIcon: Icons.settings,
      label: 'Configurações',
    ),
    _Destination(
      icon: Icons.person_outlined,
      selectedIcon: Icons.person,
      label: 'Perfil',
    ),
  ];

  Widget _iconWithKey(int index, IconData iconData) {
    final key = navKeys?[index];
    return Icon(iconData, key: key);
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final breakpoint = getBreakpoint(width);

    if (breakpoint == LayoutBreakpoint.compact) {
      return Scaffold(
        body: body,
        bottomNavigationBar: NavigationBar(
          selectedIndex: currentIndex,
          onDestinationSelected: onDestinationSelected,
          destinations: List.generate(_destinations.length, (i) {
            final d = _destinations[i];
            return NavigationDestination(
              icon: _iconWithKey(i, d.icon),
              selectedIcon: _iconWithKey(i, d.selectedIcon),
              label: d.label,
            );
          }),
        ),
      );
    }

    // expanded: NavigationDrawer fixa (linha toda selecionável)
    return Scaffold(
      body: Row(
        children: [
          NavigationDrawer(
            selectedIndex: currentIndex,
            onDestinationSelected: onDestinationSelected,
            children: [
              const SizedBox(height: 16),
              ...List.generate(_destinations.length, (i) {
                final d = _destinations[i];
                return NavigationDrawerDestination(
                  icon: _iconWithKey(i, d.icon),
                  selectedIcon: _iconWithKey(i, d.selectedIcon),
                  label: Text(d.label),
                );
              }),
            ],
          ),
          Expanded(child: body),
        ],
      ),
    );
  }
}

class _Destination {
  const _Destination({
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
}
