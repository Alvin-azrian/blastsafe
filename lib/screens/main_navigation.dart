// lib/screens/main_navigation.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/app_provider.dart';
import '../models/app_models.dart';
import '../theme.dart';
import 'home_screen.dart';
import 'shelter_screen.dart';
import 'panduan_screen.dart';
import 'kontak_screen.dart';
import 'laporan_screen.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});
  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _idx = 0;
  FloodStatus? _lastStatus;

  late final List<Widget> _screens = [
    const HomeScreen(),
    const ShelterScreen(),
    const PanduanScreen(),
    const KontakScreen(),
    const LaporanScreen(),
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkWarningOnce();
    });
  }

  void _checkWarningOnce() {
    if (!mounted) return;
    final p = context.read<AppProvider>();
    final cur = p.state.status;
    if (cur != FloodStatus.aman && p.showWarningBanner && cur != _lastStatus) {
      _lastStatus = cur;
      _showPopup(p);
    } else if (cur == FloodStatus.aman) {
      _lastStatus = cur;
    }
  }

  void _showPopup(AppProvider provider) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        final color = _statusColor(provider.state.status);
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          contentPadding: EdgeInsets.zero,
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 20),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Column(
                  children: [
                    Text(provider.state.statusEmoji,
                        style: const TextStyle(fontSize: 36)),
                    const SizedBox(height: 6),
                    Text(
                      'PERINGATAN ${provider.state.statusLabel}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Text(
                      provider.state.warningMessage.isNotEmpty
                          ? provider.state.warningMessage
                          : 'Harap siaga dan waspada terhadap situasi banjir.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 14, height: 1.5),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              Navigator.pop(ctx);
                              provider.dismissWarning();
                            },
                            child: const Text('Tutup'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.pop(ctx);
                              setState(() => _idx = 1);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: color,
                            ),
                            child: const Text('Shelter'),
                          ),
                        ),
                      ],
                    )
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Color _statusColor(FloodStatus s) {
    switch (s) {
      case FloodStatus.aman:
        return AppTheme.statusAman;
      case FloodStatus.waspada:
        return AppTheme.statusWaspada;
      case FloodStatus.siaga:
        return AppTheme.statusSiaga;
      case FloodStatus.bahaya:
        return AppTheme.statusBahaya;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (ctx, provider, _) {
        return Scaffold(
          body: IndexedStack(
            index: _idx,
            children: _screens,
          ),
          bottomNavigationBar: _AppNavBar(
            currentIndex: _idx,
            onTap: (i) => setState(() => _idx = i),
          ),
        );
      },
    );
  }
}

/* ────────────────────────────────────────
   CUSTOM BOTTOM NAV BAR
──────────────────────────────────────── */

class _AppNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _AppNavBar({required this.currentIndex, required this.onTap});

  static const _items = [
    _NavItem(
        icon: Icons.home_outlined,
        activeIcon: Icons.home_rounded,
        label: 'Beranda'),
    _NavItem(
        icon: Icons.location_on_outlined,
        activeIcon: Icons.location_on_rounded,
        label: 'Shelter'),
    _NavItem(
        icon: Icons.menu_book_outlined,
        activeIcon: Icons.menu_book_rounded,
        label: 'Panduan'),
    _NavItem(
        icon: Icons.phone_outlined,
        activeIcon: Icons.phone_rounded,
        label: 'Darurat'),
    _NavItem(
        icon: Icons.report_outlined,
        activeIcon: Icons.report_rounded,
        label: 'Laporan'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          height: 64,
          child: Row(
            children: List.generate(_items.length, (i) {
              final item = _items[i];
              final isActive = currentIndex == i;
              return Expanded(
                child: _NavBarButton(
                  item: item,
                  isActive: isActive,
                  onTap: () => onTap(i),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  const _NavItem(
      {required this.icon, required this.activeIcon, required this.label});
}

class _NavBarButton extends StatefulWidget {
  final _NavItem item;
  final bool isActive;
  final VoidCallback onTap;

  const _NavBarButton({
    required this.item,
    required this.isActive,
    required this.onTap,
  });

  @override
  State<_NavBarButton> createState() => _NavBarButtonState();
}

class _NavBarButtonState extends State<_NavBarButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _scaleAnim = Tween<double>(begin: 1.0, end: 0.88).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) {
        _ctrl.reverse();
        widget.onTap();
      },
      onTapCancel: () => _ctrl.reverse(),
      behavior: HitTestBehavior.opaque,
      child: ScaleTransition(
        scale: _scaleAnim,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Pill indicator + icon
              AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOut,
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                decoration: BoxDecoration(
                  color: widget.isActive
                      ? AppTheme.primary.withOpacity(0.12)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(
                  widget.isActive ? widget.item.activeIcon : widget.item.icon,
                  size: 22,
                  color: widget.isActive
                      ? AppTheme.primary
                      : AppTheme.textSecondary.withOpacity(0.6),
                ),
              ),
              const SizedBox(height: 2),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 220),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight:
                      widget.isActive ? FontWeight.w700 : FontWeight.w400,
                  color: widget.isActive
                      ? AppTheme.primary
                      : AppTheme.textSecondary.withOpacity(0.6),
                ),
                child: Text(widget.item.label),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
