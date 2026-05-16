// lib/screens/admin_screen.dart

// ignore_for_file: unused_element_parameter, unused_element, unused_local_variable

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/app_provider.dart';
import '../models/app_models.dart';
import '../theme.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:io';
import 'package:url_launcher/url_launcher.dart';
import 'package:image_picker/image_picker.dart';
import '../widgets/video_player_widget.dart';
import 'package:cached_network_image/cached_network_image.dart';

// ── Helper Global ─────────────────────────────────────────────────────────────
void _showSnack(BuildContext ctx, String msg, Color color) {
  ScaffoldMessenger.of(ctx).showSnackBar(
    SnackBar(
      content: Text(msg,
          style: const TextStyle(
              fontWeight: FontWeight.w600, color: Colors.white)),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      duration: const Duration(seconds: 2),
      margin: const EdgeInsets.all(16),
    ),
  );
}

/// Mengembalikan icon yang sesuai berdasarkan tipe & nama shelter
IconData getShelterIcon(String type, String name) {
  final text = ('$type $name').toLowerCase();
  if (text.contains('masjid') ||
      text.contains('mushola') ||
      text.contains('musholla')) {
    return Icons.mosque;
  } else if (text.contains('gereja')) {
    return Icons.church;
  } else if (text.contains('sekolah') ||
      text.contains('sd') ||
      text.contains('smp') ||
      text.contains('sma') ||
      text.contains('smk') ||
      text.contains('universitas') ||
      text.contains('perguruan')) {
    return Icons.school;
  } else if (text.contains('balai')) {
    return Icons.account_balance;
  } else if (text.contains('puskesmas') ||
      text.contains('klinik') ||
      text.contains('rumah sakit') ||
      text.contains(' rs ') ||
      text.contains('rsud')) {
    return Icons.local_hospital;
  } else if (text.contains('gedung') ||
      text.contains('serbaguna') ||
      text.contains('aula')) {
    return Icons.apartment;
  } else if (text.contains('kantor')) {
    return Icons.business;
  }
  return Icons.home;
}

// ── Entry: Login atau Dashboard ───────────────────────────────────────────────
class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});
  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  // ignore: unused_field
  File? _selectedImage;
  DateTime? _lastPressedAt;

  Future<void> pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);

    if (picked != null) {
      setState(() {
        _selectedImage = File(picked.path);
      });
    }
  }

  Future<bool> _showConfirmDelete(BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Konfirmasi Hapus'),
            content: const Text(
                'Apakah Anda yakin ingin menghapus laporan ini? Tindakan ini tidak dapat dibatalkan.'),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            actions: [
              TextButton(
                onPressed: () =>
                    Navigator.pop(context, false), // Tidak jadi hapus
                child: const Text('Batal',
                    style: TextStyle(color: AppTheme.textSecondary)),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true), // Ya, hapus
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  elevation: 0,
                ),
                child: const Text('Hapus'),
              ),
            ],
          ),
        ) ??
        false; // Jika dialog ditutup paksa, kembalikan nilai false
  }

  final _userCtrl = TextEditingController(text: 'admin');
  final _passCtrl = TextEditingController();
  bool _obscure = true;
  String? _error;

  @override
  void dispose() {
    _userCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 2. Bungkus Consumer dengan PopScope agar seluruh halaman Admin terlindungi
    return PopScope(
      canPop: false, // Kunci tombol back agar tidak langsung keluar
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;

        final now = DateTime.now();
        final lastPressed = _lastPressedAt;

        // Logika double tap (2 detik)
        if (lastPressed == null ||
            now.difference(lastPressed) > const Duration(seconds: 2)) {
          _lastPressedAt = now;

          // Munculkan pesan ke Admin
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content:
                  const Text('Tekan sekali lagi untuk kembali ke Menu Home'),
              backgroundColor: AppTheme.primaryDark,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 2),
              margin: const EdgeInsets.all(20),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
          );
        } else {
          // Jika ditekan 2x dalam 2 detik, balik ke Home Screen
          if (context.mounted) {
            Navigator.of(context).pop();
          }
        }
      },
      child: Consumer<AppProvider>(
        builder: (ctx, provider, _) {
          // Jika sudah login, tampilkan Dashboard
          if (provider.state.isLoggedIn) {
            return _AdminDashboard(onLogout: provider.logout);
          }
          // Jika belum, tampilkan form login
          return _buildLogin();
        },
      ),
    );
  }

  Widget _buildLogin() {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Header Login ──────────────────────────────────────────
                  Center(
                    child: Column(
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppTheme.primary,
                                AppTheme.primary.withOpacity(0.7),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.primary.withOpacity(0.3),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: const Center(
                            child: Text('🛡️', style: TextStyle(fontSize: 36)),
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'BlastSafe Admin',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            color: AppTheme.textPrimary,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Portal Manajemen Sistem',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 40),

                  // ── Card Form ─────────────────────────────────────────────
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.06),
                          blurRadius: 24,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Masuk ke Dashboard',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Gunakan akun admin untuk melanjutkan',
                          style: TextStyle(
                              fontSize: 13, color: AppTheme.textSecondary),
                        ),
                        const SizedBox(height: 24),
                        TextField(
                          controller: _userCtrl,
                          decoration: InputDecoration(
                            labelText: 'Username',
                            prefixIcon: const Icon(Icons.person_outline),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            filled: true,
                            fillColor: AppTheme.surface,
                          ),
                        ),
                        const SizedBox(height: 14),
                        TextField(
                          controller: _passCtrl,
                          obscureText: _obscure,
                          onSubmitted: (_) => _login(),
                          decoration: InputDecoration(
                            labelText: 'Password',
                            prefixIcon: const Icon(Icons.lock_outline),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            filled: true,
                            fillColor: AppTheme.surface,
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscure
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                              ),
                              onPressed: () =>
                                  setState(() => _obscure = !_obscure),
                            ),
                          ),
                        ),
                        if (_error != null) ...[
                          const SizedBox(height: 14),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: AppTheme.statusBahaya.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                  color:
                                      AppTheme.statusBahaya.withOpacity(0.2)),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.error_outline,
                                    size: 16, color: AppTheme.statusBahaya),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _error!,
                                    style: const TextStyle(
                                      color: AppTheme.statusBahaya,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: _login,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                            child: const Text(
                              'Masuk',
                              style: TextStyle(
                                  fontSize: 15, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),
                  Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: AppTheme.statusAman.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.security,
                              size: 14, color: AppTheme.statusAman),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Koneksi aman & terenkripsi',
                          style: TextStyle(
                              fontSize: 12, color: AppTheme.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _login() async {
    // 1. Ambil input dan bersihkan dari spasi liar
    final usernameInput = _userCtrl.text.trim();
    final passwordInput =
        _passCtrl.text; // Password jangan di-trim jika memang ada spasi sengaja

    if (usernameInput.isEmpty || passwordInput.isEmpty) {
      setState(() => _error = 'Username dan Password tidak boleh kosong');
      return;
    }

    // 2. Panggil fungsi di provider
    final provider = context.read<AppProvider>();

    // Tambahkan loading indicator (opsional tapi bagus)
    setState(() => _error = null);

    final success =
        await provider.checkAdminLogin(usernameInput, passwordInput);

    if (success) {
      // Jika berhasil, biasanya Consumer di build() akan otomatis pindah halaman
      // karena provider.state.isLoggedIn jadi true
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selamat Datang, Admin!')),
      );
    } else {
      setState(() {
        _error = 'Username atau password salah. Coba cek lagi di Supabase.';
      });
    }
  }
}

// ── Dashboard Responsif ───────────────────────────────────────────────────────
class _AdminDashboard extends StatefulWidget {
  final VoidCallback onLogout;
  const _AdminDashboard({required this.onLogout});

  @override
  State<_AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<_AdminDashboard> {
  // Index 0 = Home/Overview (baru), 1 = Status, 2 = Shelter, 3 = Laporan, 4 = Notifikasi
  int _selectedIndex = 0;

  static const _navItems = [
    (Icons.dashboard_outlined, Icons.dashboard, 'Home'),
    (Icons.bar_chart_outlined, Icons.bar_chart, 'Status'),
    (Icons.house_outlined, Icons.house, 'Shelter'),
    (Icons.list_alt_outlined, Icons.list_alt, 'Laporan'),
    (Icons.notifications_outlined, Icons.notifications, 'Notif'),
  ];

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (ctx, provider, _) {
        final screenWidth = MediaQuery.of(context).size.width;
        final bool isWideScreen = screenWidth >= 800;

        final pages = [
          _TabHome(
            provider: provider,
            onNavigate: (i) => setState(() => _selectedIndex = i),
          ),
          _TabStatus(provider: provider),
          _TabShelter(provider: provider),
          _TabLaporan(provider: provider),
          _TabNotifikasi(provider: provider),
        ];

        final titles = [
          'Ringkasan',
          'Status Banjir',
          'Manajemen Shelter',
          'Laporan Warga',
          'Kirim Notifikasi',
        ];

        final mainContent = Scaffold(
          backgroundColor: AppTheme.surface,
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            scrolledUnderElevation: 2,
            shadowColor: Colors.black.withOpacity(0.15),
            iconTheme: const IconThemeData(color: AppTheme.primary),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _navItems[_selectedIndex].$2,
                    size: 18,
                    color: AppTheme.primary,
                  ),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      titles[_selectedIndex],
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    Text(
                      'Admin: ${provider.state.adminUser}',
                      style: const TextStyle(
                          fontSize: 10, color: AppTheme.textSecondary),
                    ),
                  ],
                ),
              ],
            ),
            actions: [
              Container(
                margin: const EdgeInsets.only(right: 12),
                child: IconButton(
                  icon: const Icon(Icons.logout_outlined,
                      color: AppTheme.statusBahaya),
                  tooltip: 'Logout',
                  onPressed: () => _showLogoutDialog(context),
                ),
              ),
            ],
          ),
          body: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: KeyedSubtree(
              key: ValueKey(_selectedIndex),
              child: pages[_selectedIndex],
            ),
          ),
        );

        if (isWideScreen) {
          return Scaffold(
            backgroundColor: AppTheme.surface,
            body: Row(
              children: [
                NavigationRail(
                  selectedIndex: _selectedIndex,
                  onDestinationSelected: (i) =>
                      setState(() => _selectedIndex = i),
                  labelType: NavigationRailLabelType.all,
                  backgroundColor: Colors.white,
                  selectedIconTheme:
                      const IconThemeData(color: AppTheme.primary, size: 22),
                  unselectedIconTheme: const IconThemeData(
                      color: AppTheme.textSecondary, size: 22),
                  selectedLabelTextStyle: const TextStyle(
                      color: AppTheme.primary,
                      fontWeight: FontWeight.w700,
                      fontSize: 11),
                  unselectedLabelTextStyle: const TextStyle(
                      color: AppTheme.textSecondary, fontSize: 11),
                  leading: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppTheme.primary,
                            AppTheme.primary.withOpacity(0.75),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primary.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Text('🛡️', style: TextStyle(fontSize: 22)),
                    ),
                  ),
                  destinations: [
                    for (final item in _navItems)
                      NavigationRailDestination(
                        icon: Icon(item.$1),
                        selectedIcon: Icon(item.$2),
                        label: Text(item.$3),
                      ),
                  ],
                ),
                const VerticalDivider(
                    thickness: 1, width: 1, color: AppTheme.border),
                Expanded(child: mainContent),
              ],
            ),
          );
        }

        return Scaffold(
          body: mainContent,
          bottomNavigationBar: NavigationBar(
            selectedIndex: _selectedIndex,
            onDestinationSelected: (i) => setState(() => _selectedIndex = i),
            backgroundColor: Colors.white,
            indicatorColor: AppTheme.primary.withOpacity(0.12),
            labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
            destinations: [
              for (final item in _navItems)
                NavigationDestination(
                  icon: Icon(item.$1),
                  selectedIcon: Icon(item.$2, color: AppTheme.primary),
                  label: item.$3,
                ),
            ],
          ),
        );
      },
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (d) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Logout?',
            style: TextStyle(fontWeight: FontWeight.w700)),
        content: const Text('Anda akan keluar dari portal admin.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(d),
            style:
                TextButton.styleFrom(foregroundColor: AppTheme.textSecondary),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(d);
              widget.onLogout();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.statusBahaya,
              foregroundColor: Colors.white,
              elevation: 0,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
// TAB 0 — HOME / OVERVIEW DASHBOARD
// ══════════════════════════════════════════════════════════════════
class _TabHome extends StatelessWidget {
  final AppProvider provider;
  final Function(int) onNavigate;

  const _TabHome({required this.provider, required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    final status = provider.state.status;
    final shelters = provider.shelters;
    final reports = provider.reports;
    final notifications = provider.notifications;

    final totalKapasitas = shelters.fold<int>(0, (sum, s) => sum + s.capacity);
    final totalTerisi =
        shelters.fold<int>(0, (sum, s) => sum + s.currentOccupancy);
    final laporanMenunggu = reports.where((r) => !r.isVerified).length;
    final occupancyPct =
        totalKapasitas > 0 ? totalTerisi / totalKapasitas : 0.0;

    final Color statusColor;
    final String statusLabel;
    final String statusEmoji;
    switch (status) {
      case FloodStatus.aman:
        statusColor = AppTheme.statusAman;
        statusLabel = 'AMAN';
        statusEmoji = '✅';
        break;
      case FloodStatus.waspada:
        statusColor = AppTheme.statusWaspada;
        statusLabel = 'WASPADA';
        statusEmoji = '⚠️';
        break;
      case FloodStatus.siaga:
        statusColor = AppTheme.statusSiaga;
        statusLabel = 'SIAGA';
        statusEmoji = '🔶';
        break;
      case FloodStatus.bahaya:
        statusColor = AppTheme.statusBahaya;
        statusLabel = 'BAHAYA';
        statusEmoji = '🚨';
        break;
    }

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 900),
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // ── Banner Status Aktif ────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    statusColor,
                    statusColor.withOpacity(0.75),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: statusColor.withOpacity(0.35),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Text(statusEmoji, style: const TextStyle(fontSize: 44)),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Status Banjir Saat Ini',
                          style: TextStyle(
                              fontSize: 12,
                              color: Colors.white70,
                              fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          statusLabel,
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: 1,
                          ),
                        ),
                        if (provider.state.warningMessage.isNotEmpty)
                          Text(
                            provider.state.warningMessage,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 12,
                                color: Colors.white70,
                                height: 1.4),
                          ),
                      ],
                    ),
                  ),
                  InkWell(
                    onTap: () => onNavigate(1),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.22),
                        borderRadius: BorderRadius.circular(12),
                        border:
                            Border.all(color: Colors.white.withOpacity(0.3)),
                      ),
                      child: const Column(
                        children: [
                          Icon(Icons.edit_outlined,
                              color: Colors.white, size: 18),
                          SizedBox(height: 4),
                          Text('Ubah',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

// ── Grid Statistik ─────────────────────────────────────────────
            const _SectionTitle(title: 'Ringkasan Statistik'),
            const SizedBox(height: 12),
            LayoutBuilder(builder: (context, constraints) {
              final isWide = constraints.maxWidth > 550;
              return GridView.count(
                crossAxisCount: isWide ? 4 : 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: isWide ? 1.6 : 1.4,
                children: [
                  _StatCard(
                    emoji: '🏘️',
                    label: 'Total Shelter',
                    value: '${shelters.length}',
                    color: AppTheme.primary,
                    onTap: () => onNavigate(2),
                  ),
                  _StatCard(
                    emoji: '👥',
                    label: 'Total Pengungsi',
                    value: '$totalTerisi',
                    sublabel: 'Kapasitas: $totalKapasitas',
                    color: occupancyPct >= 0.8
                        ? AppTheme.statusBahaya
                        : AppTheme.statusAman,
                    onTap: () => onNavigate(2),
                  ),
                  _StatCard(
                    emoji: '📋',
                    label: 'Laporan Masuk',
                    value: '${reports.length}',
                    sublabel: '$laporanMenunggu baru',
                    color: laporanMenunggu > 0
                        ? AppTheme.statusWaspada
                        : AppTheme.statusAman,
                    onTap: () => onNavigate(3),
                  ),
                  _StatCard(
                    emoji: '🔔',
                    label: 'Notifikasi',
                    value: '${notifications.length}',
                    color: AppTheme.primary,
                    onTap: () => onNavigate(4),
                  ),
                ],
              );
            }),

            const SizedBox(height: 24),

            // ── Kapasitas Shelter ──────────────────────────────────────────
            if (shelters.isNotEmpty) ...[
              Row(
                children: [
                  const _SectionTitle(title: 'Kapasitas Shelter'),
                  const Spacer(),
                  InkWell(
                    onTap: () => onNavigate(2),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text('Lihat Semua',
                          style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.primary,
                              fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ...shelters.take(3).map((s) => _ShelterOverviewRow(shelter: s)),
            ],

            const SizedBox(height: 24),

            // ── Menu Cepat ─────────────────────────────────────────────────
            const _SectionTitle(title: 'Aksi Cepat'),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _QuickAction(
                    icon: Icons.bar_chart,
                    label: 'Update\nStatus',
                    color: AppTheme.primary,
                    onTap: () => onNavigate(1),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _QuickAction(
                    icon: Icons.add_home,
                    label: 'Tambah\nShelter',
                    color: AppTheme.statusAman,
                    onTap: () => onNavigate(2),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _QuickAction(
                    icon: Icons.fact_check_outlined,
                    label: 'Verifikasi\nLaporan',
                    color: AppTheme.statusWaspada,
                    onTap: () => onNavigate(3),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _QuickAction(
                    icon: Icons.send,
                    label: 'Kirim\nNotif',
                    color: AppTheme.statusBahaya,
                    onTap: () => onNavigate(4),
                  ),
                ),
              ],
            ),

            // ── Laporan Terbaru ────────────────────────────────────────────
            if (reports.isNotEmpty) ...[
              const SizedBox(height: 24),
              Row(
                children: [
                  const _SectionTitle(title: 'Laporan Terbaru'),
                  const Spacer(),
                  if (laporanMenunggu > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.statusWaspada.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '$laporanMenunggu menunggu',
                        style: const TextStyle(
                            fontSize: 11,
                            color: AppTheme.statusWaspada,
                            fontWeight: FontWeight.w700),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              ...reports.take(3).map((r) => _LaporanPreviewCard(report: r)),
              if (reports.length > 3)
                Center(
                  child: TextButton(
                    onPressed: () => onNavigate(3),
                    child: Text(
                      'Lihat ${reports.length - 3} laporan lainnya →',
                      style: const TextStyle(
                          color: AppTheme.primary, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
            ],

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

// ── Sub-widgets Home ──────────────────────────────────────────────────────────
class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w800,
        color: AppTheme.textPrimary,
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String emoji;
  final String label;
  final String value;
  final String? sublabel;
  final Color color;
  final VoidCallback onTap;

  const _StatCard({
    required this.emoji,
    required this.label,
    required this.value,
    required this.color,
    required this.onTap,
    this.sublabel,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: color.withOpacity(0.18),
              width: 1.5,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.14),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: Text(
                          emoji,
                          style: const TextStyle(fontSize: 18),
                        ),
                      ),
                    ),
                    Icon(
                      Icons.arrow_outward_rounded,
                      size: 14,
                      color: color.withOpacity(0.5),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: color,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.black54,
                    letterSpacing: 0.2,
                  ),
                ),
                if (sublabel != null) ...[
                  const SizedBox(height: 2),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      sublabel!,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: color,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withOpacity(0.08),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withOpacity(0.2)),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: color,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ShelterOverviewRow extends StatelessWidget {
  final Shelter shelter;

  const _ShelterOverviewRow({super.key, required this.shelter});

  @override
  Widget build(BuildContext context) {
    // URL dasar dari Supabase Storage kamu
    // Ganti 'PROJECT_ID' dengan ID project Supabase kamu
    const String bucketUrl =
        "https://PROJECT_ID.supabase.co/storage/v1/object/public/shelters/";

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          // --- BAGIAN GAMBAR ---
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: shelter.imageUrl != null && shelter.imageUrl!.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: shelter.imageUrl!.startsWith('http')
                        ? shelter.imageUrl!
                        : bucketUrl + shelter.imageUrl!,
                    width: 45,
                    height: 45,
                    fit: BoxFit.cover,
                    placeholder: (context, url) {
                      return Container(
                        width: 45,
                        height: 45,
                        color: Colors.grey[200],
                        child: const Center(
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        ),
                      );
                    },
                    errorWidget: (context, url, error) =>
                        _buildPlaceholderIcon(),
                  )
                : _buildPlaceholderIcon(),
          ),
          const SizedBox(width: 12),
          // --- INFORMASI SHELTER ---
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  shelter.name,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 14),
                ),
                Text(
                  'Kapasitas: ${shelter.capacity} Orang',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
          ),
          // Indikator Kapasitas (Persentase)
          _buildCapacityIndicator(shelter),
        ],
      ),
    );
  }

  // Widget cadangan jika gambar tidak ada
  Widget _buildPlaceholderIcon() {
    return Container(
      width: 45,
      height: 45,
      color: AppTheme.primary.withOpacity(0.1),
      child: const Icon(Icons.home_work_rounded,
          color: AppTheme.primary, size: 24),
    );
  }

  // Widget indikator sisa tempat
  Widget _buildCapacityIndicator(Shelter s) {
    // Logika perhitungan sisa kapasitas bisa ditaruh di sini
    return const Icon(Icons.chevron_right, color: Colors.grey);
  }
}

class _LaporanPreviewCard extends StatelessWidget {
  final WargaReport report;
  const _LaporanPreviewCard({required this.report});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: report.isVerified
              ? AppTheme.statusAman.withOpacity(0.3)
              : AppTheme.border,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: report.isVerified
                  ? AppTheme.statusAman.withOpacity(0.1)
                  : AppTheme.statusWaspada.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              report.isVerified
                  ? Icons.check_circle_outline
                  : Icons.hourglass_bottom_outlined,
              size: 18,
              color: report.isVerified
                  ? AppTheme.statusAman
                  : AppTheme.statusWaspada,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  report.description,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary),
                ),
                const SizedBox(height: 2),
                Text(
                  '${report.location} • ${report.reporterName}',
                  style: const TextStyle(
                      fontSize: 11, color: AppTheme.textSecondary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: report.isVerified
                  ? AppTheme.statusAman.withOpacity(0.1)
                  : AppTheme.statusWaspada.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              report.isVerified ? 'Verified' : 'Pending',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: report.isVerified
                    ? AppTheme.statusAman
                    : AppTheme.statusWaspada,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
// TAB 1 — Status Banjir
// ══════════════════════════════════════════════════════════════════
class _TabStatus extends StatefulWidget {
  final AppProvider provider;
  const _TabStatus({required this.provider});

  @override
  State<_TabStatus> createState() => _TabStatusState();
}

class _TabStatusState extends State<_TabStatus> {
  late FloodStatus _selected;
  late TextEditingController _msgCtrl;

  static const _statuses = [
    (
      FloodStatus.aman,
      '✅',
      'AMAN',
      'Kondisi normal, tidak ada ancaman banjir',
      AppTheme.statusAman
    ),
    (
      FloodStatus.waspada,
      '⚠️',
      'WASPADA',
      'Masyarakat diminta meningkatkan kewaspadaan',
      AppTheme.statusWaspada
    ),
    (
      FloodStatus.siaga,
      '🔶',
      'SIAGA',
      'Bersiap untuk evakuasi jika diperlukan',
      AppTheme.statusSiaga
    ),
    (
      FloodStatus.bahaya,
      '🚨',
      'BAHAYA',
      'Evakuasi segera ke shelter terdekat',
      AppTheme.statusBahaya
    ),
  ];

  @override
  void initState() {
    super.initState();
    _selected = widget.provider.state.status;
    _msgCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _msgCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620),
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            // Header info
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.06),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.primary.withOpacity(0.15)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, size: 18, color: AppTheme.primary),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Perubahan status akan langsung terlihat oleh semua pengguna aplikasi.',
                      style: TextStyle(
                          fontSize: 12, color: AppTheme.primary, height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Pilih Status Banjir',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 14),
            ..._statuses.map((s) {
              final (status, emoji, label, desc, color) = s;
              final selected = _selected == status;

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                child: Material(
                  color: selected ? color.withOpacity(0.06) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  child: InkWell(
                    onTap: () => setState(() => _selected = status),
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: selected ? color : AppTheme.border,
                          width: selected ? 2 : 1,
                        ),
                        boxShadow: selected
                            ? [
                                BoxShadow(
                                  color: color.withOpacity(0.12),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ]
                            : [],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                              child: Text(emoji,
                                  style: const TextStyle(fontSize: 22)),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  label,
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                    color:
                                        selected ? color : AppTheme.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  desc,
                                  style: const TextStyle(
                                      fontSize: 12,
                                      color: AppTheme.textSecondary,
                                      height: 1.3),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: selected ? color : Colors.transparent,
                              border: Border.all(
                                color: selected ? color : AppTheme.border,
                                width: 2,
                              ),
                            ),
                            child: selected
                                ? const Icon(Icons.check,
                                    color: Colors.white, size: 14)
                                : null,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),
            const SizedBox(height: 20),
            TextField(
              controller: _msgCtrl,
              maxLines: 4,
              decoration: InputDecoration(
                labelText: 'Pesan Peringatan (opsional)',
                hintText:
                    'Contoh: Debit Sungai Cimanggu meningkat, warga RW 03 diminta bersiap...',
                alignLabelWithHint: true,
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: () {
                  widget.provider.updateStatus(_selected, _msgCtrl.text.trim());
                  _showSnack(context, '✅ Status berhasil diperbarui',
                      AppTheme.statusAman);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                icon: const Icon(Icons.save_outlined, size: 20),
                label: const Text('Simpan & Publikasikan Status',
                    style:
                        TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
// TAB 2 — Shelter
// ══════════════════════════════════════════════════════════════════
class _TabShelter extends StatelessWidget {
  final AppProvider provider;
  const _TabShelter({required this.provider});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 800),
        child: Stack(
          children: [
            provider.shelters.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.home_work_outlined,
                            size: 56, color: AppTheme.textSecondary),
                        SizedBox(height: 12),
                        Text('Belum ada data shelter',
                            style: TextStyle(
                                fontSize: 15,
                                color: AppTheme.textSecondary,
                                fontWeight: FontWeight.w600)),
                        SizedBox(height: 6),
                        Text('Tekan tombol + untuk menambah shelter baru',
                            style: TextStyle(
                                fontSize: 12, color: AppTheme.textSecondary)),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
                    itemCount: provider.shelters.length,
                    itemBuilder: (ctx, i) {
                      final shelter = provider.shelters[i];
                      return _ShelterAdminCard(
                        key: ValueKey(shelter.id),
                        shelter: shelter,
                        onEdit: () => _showShelterForm(context, provider,
                            shelter: shelter),
                        onDelete: () =>
                            _confirmDelete(context, provider, shelter),
                        onUpdateOccupancy: (value) =>
                            provider.updateShelterOccupancy(shelter.id, value),
                      );
                    },
                  ),
            Positioned(
              bottom: 24,
              right: 24,
              child: FloatingActionButton.extended(
                onPressed: () => _showShelterForm(context, provider),
                elevation: 4,
                icon: const Icon(Icons.add, color: Colors.white),
                label: const Text('Tambah Shelter',
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold)),
                backgroundColor: AppTheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showShelterForm(BuildContext context, AppProvider provider,
      {Shelter? shelter}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
        ),
        child: _ShelterForm(
          shelter: shelter,
          onSave: (shelterData, imageFile) async {
            if (shelter == null) {
              // Jika baru, gunakan fungsi tambah
              await provider.addShelterWithImage(shelterData, imageFile);
            } else {
              // Jika edit, gunakan fungsi update yang sudah kita amankan gambarnya
              await provider.updateShelterWithImage(shelterData, imageFile);
            }
          },
        ),
      ),
    );
  }

  void _confirmDelete(
      BuildContext context, AppProvider provider, Shelter shelter) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Hapus Shelter?',
            style: TextStyle(fontWeight: FontWeight.w700)),
        content: Text('Anda yakin ingin menghapus "${shelter.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            style:
                TextButton.styleFrom(foregroundColor: AppTheme.textSecondary),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogCtx);
              provider.deleteShelter(shelter.id);
              _showSnack(context, 'Shelter dihapus.', AppTheme.statusBahaya);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.statusBahaya,
              foregroundColor: Colors.white,
              elevation: 0,
            ),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
// TAB 3 — Laporan Warga
// ══════════════════════════════════════════════════════════════════
// Di dalam admin_screen.dart, pada bagian tab laporan Anda:

class _TabLaporan extends StatefulWidget {
  final AppProvider provider;

  const _TabLaporan({required this.provider});

  @override
  State<_TabLaporan> createState() => _TabLaporanState();
}

class _TabLaporanState extends State<_TabLaporan> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();

    _scrollController.addListener(_onScroll);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppProvider>().fetchReports();
    });
  }

  void _onScroll() {
    final provider = context.read<AppProvider>();

    if (_scrollController.position.pixels <
        _scrollController.position.maxScrollExtent - 200) {
      return;
    }

    if (!provider.hasMoreReports) return;
    if (provider.isLoadingMoreReports) return;

    provider.fetchReports(loadMore: true);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final reports = provider.reports;

    if (reports.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.list_alt, size: 56, color: AppTheme.textSecondary),
            SizedBox(height: 12),
            Text('Belum ada laporan warga',
                style: TextStyle(
                    fontSize: 15,
                    color: AppTheme.textSecondary,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: reports.length + (provider.hasMoreReports ? 1 : 0),
      itemBuilder: (ctx, i) {
        // Loading item paling bawah
        if (i >= reports.length) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        final report = reports[i];

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: report.isVerified
                  ? AppTheme.statusAman.withOpacity(0.3)
                  : AppTheme.border,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: report.isVerified
                    ? AppTheme.statusAman.withOpacity(0.1)
                    : AppTheme.statusWaspada.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                report.isVerified
                    ? Icons.check_circle
                    : Icons.hourglass_empty_outlined,
                color: report.isVerified
                    ? AppTheme.statusAman
                    : AppTheme.statusWaspada,
              ),
            ),
            title: Text(
              report.reporterName,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 14,
                color: AppTheme.textPrimary,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(
                  report.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      Icons.location_on,
                      size: 12,
                      color: AppTheme.primary,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        report.location,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 10,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showAdminReportDetail(
              context,
              report,
            ),
          ),
        );
      },
    );
  }

  //Pop up ini yah
  void _showAdminReportDetail(BuildContext context, WargaReport report) {
    // Fungsi untuk membuka Google Maps
    void openMap(String locationText) async {
      final regExp = RegExp(
          r'(?:Lat|Lac|Location):\s*(-?\d+\.\d+),\s*Lng:\s*(-?\d+\.\d+)');
      final match = regExp.firstMatch(locationText);

      Uri mapUri;

      if (match != null) {
        final lat = match.group(1);
        final lng = match.group(2);
        mapUri = Uri.parse('geo:$lat,$lng?q=$lat,$lng');
      } else {
        // Tambahkan tanda '$' sebelum kurung kurawal agar tidak error
        mapUri = Uri.parse(
            'http://maps.google.com/?q=${Uri.encodeComponent(locationText)}');
      }

      try {
        if (await canLaunchUrl(mapUri)) {
          await launchUrl(mapUri, mode: LaunchMode.externalApplication);
        } else {
          throw 'Tidak dapat membuka URL';
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal membuka Maps: $e')),
        );
      }
    }

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color:
                              Theme.of(context).primaryColor.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            report.reporterName.isNotEmpty
                                ? report.reporterName[0].toUpperCase()
                                : 'A',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              report.reporterName,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const Text(
                              'Pelapor',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, size: 20),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const Divider(height: 24),

                  // 1. Lokasi Kejadian
                  const Text(
                    'Lokasi Kejadian',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Teks lokasi utama pelapor (dibersihkan dari koordinat atau tanda kurung)
                  Builder(
                    builder: (context) {
                      String cleanedLocation = report.location;

                      // Regex untuk menghapus format "(Lat... , Lng...)" atau koordinat di samping lokasi
                      final regExp = RegExp(
                          r'\s*\(?(?:Lat|Lac|Location|Koordinat):\s*-?\d+\.\d+,\s*Lng:\s*-?\d+\.\d+\)?|\s*\([^)]*\)');

                      if (regExp.hasMatch(cleanedLocation)) {
                        cleanedLocation =
                            cleanedLocation.replaceAll(regExp, '').trim();
                        if (cleanedLocation.endsWith(',')) {
                          cleanedLocation = cleanedLocation
                              .substring(0, cleanedLocation.length - 1)
                              .trim();
                        }
                      }

                      return Text(
                        cleanedLocation.isNotEmpty
                            ? cleanedLocation
                            : report.location,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 6),

                  // Menampilkan Koordinat di bawahnya
                  Builder(
                    builder: (context) {
                      final regExp = RegExp(
                          r'(?:Lat|Lac|Location):\s*(-?\d+\.\d+),\s*Lng:\s*(-?\d+\.\d+)');
                      final match = regExp.firstMatch(report.location);

                      if (match != null) {
                        final latVal = match.group(1);
                        final lngVal = match.group(2);
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: Text(
                            'Koordinat Lokasi : Lac: $latVal, Lng: $lngVal',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppTheme.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),

                  // Tombol Buka di Google Maps
                  OutlinedButton.icon(
                    onPressed: () => openMap(report.location),
                    icon: const Icon(
                      Icons.location_on,
                      size: 18,
                      color: AppTheme.primary,
                    ),
                    label: const Text(
                      'Lihat di Google Maps',
                      style: TextStyle(fontSize: 12, color: AppTheme.primary),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppTheme.primary),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // INI PENJELASAN KEJADIAN
                  const Text(
                    'Penjelasan Kejadian',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.border),
                    ),
                    child: Text(
                      report.description,
                      style: const TextStyle(
                        fontSize: 13,
                        height: 1.4,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // DOKUMENTASI YAH KIDS AWAS LUPA
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 3. DOKUMENTASI (Update untuk mendukung Video)
                      const Text(
                        'Dokumentasi',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: AppTheme.surface,
                            border: Border.all(color: AppTheme.border),
                          ),
                          // Menghilangkan height kaku agar video player bisa menyesuaikan rasio asli
                          child: report.imagePath != null &&
                                  report.imagePath!.isNotEmpty &&
                                  report.imagePath != 'null'
                              ? Builder(
                                  builder: (context) {
                                    final url = report.imagePath!.toLowerCase();
                                    // Deteksi apakah file ini video
                                    final isVideo = url.endsWith('.mp4') ||
                                        url.endsWith('.mov') ||
                                        url.endsWith('.avi');

                                    if (isVideo) {
                                      // Tampilkan Video Player jika format video
                                      return AppVideoPlayer(
                                          url: report.imagePath);
                                    } else {
                                      // Tampilkan Image jika format gambar
                                      return CachedNetworkImage(
                                        imageUrl: report.imagePath!,
                                        fit: BoxFit.contain,
                                        placeholder: (context, url) =>
                                            const Center(
                                          child: Padding(
                                            padding: EdgeInsets.all(20),
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                            ),
                                          ),
                                        ),
                                        errorWidget: (context, url, error) {
                                          return const SizedBox(
                                            height: 150,
                                            child: Center(
                                              child: Icon(Icons.broken_image),
                                            ),
                                          );
                                        },
                                      );
                                    }
                                  },
                                )
                              : const SizedBox(
                                  height: 100,
                                  child:
                                      Center(child: Icon(Icons.image_outlined)),
                                ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  //Tombol aksi (verifikasi, tolak, hapus laporan)
                  Builder(
                    builder: (context) {
                      final provider = context.read<AppProvider>();

                      // --- Fungsi Helper untuk Pop-up Konfirmasi ---
                      Future<void> confirmAction(String title, String content,
                          VoidCallback onConfirm) async {
                        final bool? yakin = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: Text(title),
                            content: Text(content),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16)),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx, false),
                                child: const Text('Batal',
                                    style: TextStyle(
                                        color: AppTheme.textSecondary)),
                              ),
                              ElevatedButton(
                                onPressed: () => Navigator.pop(ctx, true),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: title.contains('Hapus') ||
                                          title.contains('Tolak')
                                      ? Colors.red
                                      : Colors.green,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                ),
                                child: const Text('Ya, Lanjutkan'),
                              ),
                            ],
                          ),
                        );

                        if (yakin == true) {
                          onConfirm();
                        }
                      }

                      return report.isVerified
                          ? SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  // Tambahkan konfirmasi sebelum hapus
                                  confirmAction(
                                    'Hapus Laporan',
                                    'Apakah Anda yakin ingin menghapus laporan ini secara permanen?',
                                    () {
                                      provider.deleteReport(report.id);
                                      Navigator.pop(context);
                                      _showSnack(
                                          context,
                                          'Laporan berhasil dihapus',
                                          AppTheme.statusAman);
                                    },
                                  );
                                },
                                icon: const Icon(Icons.delete,
                                    color: Colors.white),
                                label: const Text(
                                  'Hapus Laporan',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                  elevation: 0,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 13),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12)),
                                ),
                              ),
                            )
                          : Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: () {
                                      // Tambahkan konfirmasi sebelum tolak
                                      confirmAction(
                                        'Tolak Laporan',
                                        'Laporan ini akan ditolak dan dihapus dari daftar verifikasi. Lanjutkan?',
                                        () {
                                          provider.rejectReport(report.id);
                                          Navigator.pop(context);
                                          _showSnack(context, 'Laporan ditolak',
                                              AppTheme.statusWaspada);
                                        },
                                      );
                                    },
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 12),
                                      side: const BorderSide(color: Colors.red),
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(8)),
                                    ),
                                    child: const Text('Tolak',
                                        style: TextStyle(color: Colors.red)),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: () {
                                      // Untuk verifikasi biasanya boleh langsung,
                                      // tapi jika ingin konfirmasi juga bisa ditambahkan di sini
                                      provider.verifyReport(report.id);
                                      Navigator.pop(context);
                                      _showSnack(
                                          context,
                                          'Laporan berhasil diverifikasi',
                                          AppTheme.statusAman);
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green,
                                      foregroundColor: Colors.white,
                                      elevation: 0,
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 12),
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(8)),
                                    ),
                                    child: const Text('Verifikasi'),
                                  ),
                                ),
                              ],
                            );
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

String _ago(DateTime t) {
  final d = DateTime.now().difference(t);
  if (d.inMinutes < 60) return '${d.inMinutes} mnt lalu';
  if (d.inHours < 24) return '${d.inHours} jam lalu';
  return '${d.inDays} hari lalu';
}

// ══════════════════════════════════════════════════════════════════
// TAB 4 — Kirim Notifikasi
// ══════════════════════════════════════════════════════════════════
class _TabNotifikasi extends StatefulWidget {
  final AppProvider provider;
  const _TabNotifikasi({required this.provider});

  @override
  State<_TabNotifikasi> createState() => _TabNotifikasiState();
}

class _TabNotifikasiState extends State<_TabNotifikasi> {
  final _titleCtrl = TextEditingController();
  final _msgCtrl = TextEditingController();
  String _priority = 'normal';
  bool _sending = false;

  static const _priorities = [
    ('normal', 'ℹ️ Info', AppTheme.primary),
    ('penting', '⚠️ Penting', AppTheme.statusWaspada),
    ('darurat', '🚨 Darurat', AppTheme.statusBahaya),
  ];

  @override
  void dispose() {
    _titleCtrl.dispose();
    _msgCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1000),
        child: LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth > 750) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                      flex: 5,
                      child: SingleChildScrollView(
                          padding: const EdgeInsets.all(24),
                          child: _buildForm())),
                  const VerticalDivider(width: 1, color: AppTheme.border),
                  Expanded(flex: 4, child: _buildHistory(isWide: true)),
                ],
              );
            }
            return ListView(
              padding: const EdgeInsets.all(20),
              children: [
                _buildForm(),
                const SizedBox(height: 32),
                _buildHistory(isWide: false),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildForm() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 10,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Text('🔔', style: TextStyle(fontSize: 24)),
              SizedBox(width: 12),
              Text(
                'Kirim Notifikasi',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textPrimary),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Kirim peringatan instan ke semua perangkat pengguna.',
            style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 20),
          const Text('Pilih Prioritas',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textSecondary)),
          const SizedBox(height: 10),
          Row(
            children: _priorities.map((p) {
              final (val, label, color) = p;
              final selected = _priority == val;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Material(
                    color:
                        selected ? color.withOpacity(0.12) : AppTheme.surface,
                    borderRadius: BorderRadius.circular(10),
                    child: InkWell(
                      onTap: () => setState(() => _priority = val),
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: selected ? color : AppTheme.border,
                              width: selected ? 2 : 1),
                        ),
                        child: Text(
                          label,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: selected ? color : AppTheme.textSecondary),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _titleCtrl,
            decoration: InputDecoration(
              labelText: 'Judul Notifikasi *',
              prefixIcon: const Icon(Icons.title_outlined),
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
              fillColor: AppTheme.surface,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _msgCtrl,
            maxLines: 4,
            decoration: InputDecoration(
              labelText: 'Isi Pesan *',
              alignLabelWithHint: true,
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
              fillColor: AppTheme.surface,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: _sending ? null : _send,
              style: ElevatedButton.styleFrom(
                backgroundColor: _priority == 'darurat'
                    ? AppTheme.statusBahaya
                    : _priority == 'penting'
                        ? AppTheme.statusWaspada
                        : AppTheme.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              icon: _sending
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.send, size: 18),
              label: Text(_sending ? 'Mengirim...' : 'Kirim Sekarang',
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistory({required bool isWide}) {
    // Ambil data dari widget.provider
    final notifications = widget.provider.notifications;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Histori Notifikasi',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),

        // Cek jika kosong, panggil fungsi pembantu
        if (notifications.isEmpty)
          _buildEmptyHistory()
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final notif = notifications[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.border),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(notif.title,
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold)),
                          Text(notif.message,
                              style: const TextStyle(
                                  fontSize: 12, color: Colors.grey)),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Hapus Histori?'),
                            content: const Text(
                                'Data akan dihapus permanen dari cloud.'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx),
                                child: const Text('Batal'),
                              ),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.statusBahaya),
                                onPressed: () {
                                  // DISINI PERBAIKANNYA: Pakai widget.provider
                                  widget.provider.deleteNotification(notif.id);

                                  Navigator.pop(ctx);
                                  _showSnack(context, 'Berhasil dihapus',
                                      AppTheme.statusBahaya);
                                },
                                child: const Text('Hapus',
                                    style: TextStyle(color: Colors.white)),
                              ),
                            ],
                          ),
                        );
                      },
                      icon: const Icon(Icons.delete_outline,
                          size: 20, color: AppTheme.statusBahaya),
                    ),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }

  // TAMBAHKAN INI juga supaya _buildEmptyHistory tidak merah
  Widget _buildEmptyHistory() {
    return Container(
      padding: const EdgeInsets.all(20),
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppTheme.border.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Center(
        child: Text('Belum ada riwayat notifikasi',
            style: TextStyle(color: Colors.grey)),
      ),
    );
  }

  Future<void> _send() async {
    final title = _titleCtrl.text.trim();
    final msg = _msgCtrl.text.trim();

    if (title.isEmpty || msg.isEmpty) {
      _showSnack(
          context, 'Judul dan isi tidak boleh kosong', AppTheme.statusWaspada);
      return;
    }

    setState(() => _sending = true);

    try {
      // Panggil fungsi provider
      await widget.provider.sendAdminNotification(
          title: title, message: msg, priority: _priority);

      // Jika berhasil, bersihkan form
      _titleCtrl.clear();
      _msgCtrl.clear();
      _showSnack(context, 'Notifikasi berhasil dikirim!', AppTheme.statusAman);
    } catch (e) {
      // Jika error (misal koneksi mati atau Supabase error), beri tahu admin
      debugPrint("Gagal kirim notif: $e");
      _showSnack(context, 'Gagal mengirim notifikasi. Coba lagi.',
          AppTheme.statusBahaya);
    } finally {
      // PENTING: Bagian ini akan dijalankan APAPUN yang terjadi (Sukses atau Gagal).
      // Jadi tombol tidak akan loading terus-menerus.
      if (mounted) {
        setState(() {
          _sending = false;
          _priority = 'normal';
        });
      }
    }
  }
}

// ══════════════════════════════════════════════════════════════════
// CARD NOTIFIKASI TERKIRIM
// ══════════════════════════════════════════════════════════════════
class _SentNotifCard extends StatelessWidget {
  final AdminNotification notif;
  final VoidCallback onDelete;

  const _SentNotifCard({required this.notif, required this.onDelete});

  Color get _color {
    switch (notif.priority) {
      case 'darurat':
        return AppTheme.statusBahaya;
      case 'penting':
        return AppTheme.statusWaspada;
      default:
        return AppTheme.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
                color: _color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10)),
            child: Text(
                notif.priority == 'darurat'
                    ? '🚨'
                    : notif.priority == 'penting'
                        ? '⚠️'
                        : 'ℹ️',
                style: const TextStyle(fontSize: 18)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(notif.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: AppTheme.textPrimary)),
                const SizedBox(height: 2),
                Text(notif.message,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                        height: 1.3)),
              ],
            ),
          ),
          IconButton(
            onPressed: () {
              showDialog(
                context: context,
                builder: (dialogContext) => AlertDialog(
                  title: const Text('Hapus Notifikasi?'),
                  content: const Text('Data akan dihapus permanen dari cloud.'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(dialogContext),
                      child: const Text('Batal'),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.statusBahaya,
                      ),
                      onPressed: () {
                        // PERBAIKAN DI SINI:
                        // Kita panggil langsung AppProvider menggunakan context
                        Provider.of<AppProvider>(context, listen: false)
                            .deleteNotification(notif.id);

                        Navigator.pop(dialogContext); // Tutup dialog
                        _showSnack(context, 'Notifikasi berhasil dihapus',
                            AppTheme.statusBahaya);
                      },
                      child: const Text(
                        'Hapus',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              );
            },
            icon: const Icon(
              Icons.delete_outline,
              size: 20,
              color: AppTheme.statusBahaya,
            ),
            tooltip: 'Hapus Histori',
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
// Form Shelter (modal bottom sheet)
// ══════════════════════════════════════════════════════════════════

class _ShelterForm extends StatefulWidget {
  final Shelter? shelter;
  final Function(Shelter, File?) onSave;

  const _ShelterForm({this.shelter, required this.onSave});

  @override
  State<_ShelterForm> createState() => _ShelterFormState();
}

class _ShelterFormState extends State<_ShelterForm> {
  File? _selectedImage;
  bool _isSaving = false;

  Future<void> pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);

    if (picked != null) {
      setState(() {
        _selectedImage = File(picked.path);
      });
    }
  }

  final _form = GlobalKey<FormState>();
  late TextEditingController _name, _address, _cap, _occ, _lat, _lng;
  late String _type;
  bool _loadingGps = false;
  String? _gpsError;
  late TextEditingController _phoneController;

  static const _types = [
    'Balai Desa',
    'Sekolah',
    'Masjid / Tempat Ibadah',
    'Gedung Serbaguna',
    'Puskesmas',
    'Lainnya'
  ];

  @override
  void initState() {
    super.initState();

    final s = widget.shelter;
    _phoneController = TextEditingController(text: widget.shelter?.phone ?? '');
    _name = TextEditingController(text: s?.name ?? '');
    _address = TextEditingController(text: s?.address ?? '');
    _cap = TextEditingController(text: s?.capacity.toString() ?? '');
    _occ = TextEditingController(text: s?.currentOccupancy.toString() ?? '0');

    _lat = TextEditingController(
      text: (s?.lat != null && s!.lat != -6.9175) ? s.lat.toString() : '',
    );

    _lng = TextEditingController(
      text: (s?.lng != null && s!.lng != 107.6191) ? s.lng.toString() : '',
    );

    _type = s?.type ?? _types.first;
  }

  @override
  void dispose() {
    _name.dispose();
    _address.dispose();
    _cap.dispose();
    _occ.dispose();
    _lat.dispose();
    _lng.dispose();
    super.dispose();
    _phoneController.dispose();
  }

  // ── Ambil lokasi GPS ────────────────────────────────────────────
  Future<void> _getGpsLocation() async {
    setState(() {
      _loadingGps = true;
      _gpsError = null;
    });

    try {
      // Cek apakah location service aktif
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _gpsError = 'GPS tidak aktif. Nyalakan lokasi di pengaturan.';
          _loadingGps = false;
        });
        return;
      }

      // Cek & minta permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _gpsError = 'Izin lokasi ditolak.';
            _loadingGps = false;
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _gpsError =
              'Izin lokasi ditolak permanen. Aktifkan manual di pengaturan app.';
          _loadingGps = false;
        });
        return;
      }

      // Ambil posisi dengan akurasi tinggi
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 15),
      );

      setState(() {
        _lat.text = position.latitude.toStringAsFixed(6);
        _lng.text = position.longitude.toStringAsFixed(6);
        _loadingGps = false;
        _gpsError = null;
      });
    } catch (e) {
      setState(() {
        _gpsError = 'Gagal mendapatkan lokasi. Coba lagi.';
        _loadingGps = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.shelter != null;
    final hasCoords = _lat.text.isNotEmpty && _lng.text.isNotEmpty;

    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _form,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Drag handle ────────────────────────────────────────
              Center(
                child: Container(
                  width: 40,
                  height: 5,
                  decoration: BoxDecoration(
                    color: AppTheme.border,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // ── Header form ────────────────────────────────────────
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      getShelterIcon(_type, _name.text),
                      color: AppTheme.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    isEdit ? '✏️ Edit Shelter' : '➕ Tambah Shelter Baru',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // ── Field-field dasar ──────────────────────────────────
              _field(_name, 'Nama Shelter *', Icons.home_outlined,
                  required: true),
              const SizedBox(height: 12),
              _field(_address, 'Alamat *', Icons.location_on_outlined,
                  required: true),
              const SizedBox(height: 12),
              TextField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: 'Nomor Telepon Pengelola',
                  prefixIcon: Icon(Icons.phone),
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _type,
                decoration: InputDecoration(
                  labelText: 'Jenis Shelter',
                  prefixIcon: Icon(getShelterIcon(_type, _name.text)),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                items: _types
                    .map((t) => DropdownMenuItem(
                          value: t,
                          child: Row(
                            children: [
                              Icon(getShelterIcon(t, ''),
                                  size: 18, color: AppTheme.textSecondary),
                              const SizedBox(width: 8),
                              Text(t),
                            ],
                          ),
                        ))
                    .toList(),
                onChanged: (v) => setState(() => _type = v ?? _type),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _field(_cap, 'Kapasitas *', Icons.people_outline,
                        required: true, isNum: true),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _field(_occ, 'Terisi', Icons.person_outline,
                        isNum: true),
                  ),
                ],
              ),

              // INI FORM  GPS YAH KIDSS
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: hasCoords
                      ? AppTheme.statusAman.withOpacity(0.05)
                      : AppTheme.primary.withOpacity(0.04),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: hasCoords
                        ? AppTheme.statusAman.withOpacity(0.3)
                        : AppTheme.border,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header seksi
                    Row(
                      children: [
                        Icon(
                          Icons.my_location_rounded,
                          size: 18,
                          color: hasCoords
                              ? AppTheme.statusAman
                              : AppTheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Titik Koordinat Shelter',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: hasCoords
                                ? AppTheme.statusAman
                                : AppTheme.textPrimary,
                          ),
                        ),
                        const Spacer(),
                        if (hasCoords)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppTheme.statusAman.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              '✓ Tersimpan',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.statusAman,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Dipakai untuk fitur navigasi di aplikasi warga.',
                      style: TextStyle(
                          fontSize: 12, color: AppTheme.textSecondary),
                    ),
                    const SizedBox(height: 14),

                    // Tombol ambil GPS
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _loadingGps ? null : _getGpsLocation,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: _loadingGps
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(Icons.gps_fixed_rounded, size: 18),
                        label: Text(
                          _loadingGps
                              ? 'Mendapatkan lokasi...'
                              : hasCoords
                                  ? 'Perbarui Lokasi GPS'
                                  : 'Ambil Lokasi Saat Ini (GPS)',
                          style: const TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),

                    // Error GPS
                    if (_gpsError != null) ...[
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppTheme.statusBahaya.withOpacity(0.07),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color: AppTheme.statusBahaya.withOpacity(0.2)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline,
                                size: 14, color: AppTheme.statusBahaya),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _gpsError!,
                                style: const TextStyle(
                                    fontSize: 12, color: AppTheme.statusBahaya),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 14),

                    // Field lat/lng (bisa juga diisi manual)
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _lat,
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true, signed: true),
                            decoration: InputDecoration(
                              labelText: 'Latitude *',
                              prefixIcon:
                                  const Icon(Icons.swap_vert_rounded, size: 18),
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10)),
                              filled: true,
                              fillColor: Colors.white,
                              hintText: '-6.123456',
                            ),
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) {
                                return 'Wajib diisi';
                              }
                              final val = double.tryParse(v.trim());
                              if (val == null || val < -90 || val > 90) {
                                return 'Tidak valid';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextFormField(
                            controller: _lng,
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true, signed: true),
                            decoration: InputDecoration(
                              labelText: 'Longitude *',
                              prefixIcon: const Icon(Icons.swap_horiz_rounded,
                                  size: 18),
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10)),
                              filled: true,
                              fillColor: Colors.white,
                              hintText: '107.123456',
                            ),
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) {
                                return 'Wajib diisi';
                              }
                              final val = double.tryParse(v.trim());
                              if (val == null || val < -180 || val > 180) {
                                return 'Tidak valid';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.info_outline,
                            size: 12, color: AppTheme.textSecondary),
                        const SizedBox(width: 4),
                        const Expanded(
                          child: Text(
                            'Atau isi manual dari Google Maps → tahan titik → salin koordinat.',
                            style: TextStyle(
                                fontSize: 11, color: AppTheme.textSecondary),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),
              // Form ini untuk upload gambar yah kids
              Builder(builder: (context) {
                final hasImage = _selectedImage != null;
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: hasImage
                        ? AppTheme.statusAman.withOpacity(0.05)
                        : AppTheme.primary.withOpacity(0.04),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: hasImage
                          ? AppTheme.statusAman.withOpacity(0.3)
                          : AppTheme.border,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Header ──
                      Row(
                        children: [
                          Icon(
                            Icons.image_rounded,
                            size: 18,
                            color: hasImage
                                ? AppTheme.statusAman
                                : AppTheme.primary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Foto Shelter',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: hasImage
                                  ? AppTheme.statusAman
                                  : AppTheme.textPrimary,
                            ),
                          ),
                          const Spacer(),
                          if (hasImage)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppTheme.statusAman.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                '✓ Terpilih',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.statusAman,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Foto shelter ditampilkan di aplikasi warga sebagai referensi.',
                        style: TextStyle(
                            fontSize: 12, color: AppTheme.textSecondary),
                      ),
                      const SizedBox(height: 14),

                      // ── Preview Gambar ──
                      if (hasImage) ...[
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.file(
                            _selectedImage!,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            // tinggi menyesuaikan aspek foto, dibatasi max
                            height: (() {
                              final decoded = decodeImageFromList(
                                  _selectedImage!.readAsBytesSync());
                              return null; // Flutter otomatis wrap height
                            })(),
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],

                      // ── Tombol Upload ──
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: pickImage,
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                hasImage ? Colors.white : AppTheme.primary,
                            foregroundColor:
                                hasImage ? AppTheme.primary : Colors.white,
                            elevation: 0,
                            side: hasImage
                                ? BorderSide(
                                    color: AppTheme.primary.withOpacity(0.4))
                                : null,
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                          icon: Icon(
                            hasImage
                                ? Icons.swap_horiz_rounded
                                : Icons.add_photo_alternate_rounded,
                            size: 18,
                          ),
                          label: Text(
                            hasImage ? 'Ganti Foto' : 'Pilih Foto Shelter',
                            style: const TextStyle(
                                fontSize: 14, fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),

                      const SizedBox(height: 8),
                      Row(
                        children: const [
                          Icon(Icons.info_outline,
                              size: 12, color: AppTheme.textSecondary),
                          SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              'Format JPG / PNG. Foto landscape lebih baik untuk tampilan aplikasi.',
                              style: TextStyle(
                                  fontSize: 11, color: AppTheme.textSecondary),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }),

              const SizedBox(height: 24),
              // ── Tombol simpan ──────────────────────────────────────
              // Di dalam Widget build, bagian tombol paling bawah:
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  // Matikan tombol (onPressed: null) kalau lagi loading agar tidak terpencet 2x
                  onPressed: _isSaving ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  // Ganti icon jadi loading jika _isSaving true
                  icon: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : Icon(isEdit ? Icons.save : Icons.add, size: 20),
                  // Ganti teks juga jika perlu
                  label: Text(
                    _isSaving
                        ? 'Sedang Menyimpan...'
                        : (isEdit ? 'Simpan Perubahan' : 'Tambah Shelter'),
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController ctrl,
    String label,
    IconData icon, {
    bool required = false,
    bool isNum = false,
  }) {
    return TextFormField(
      controller: ctrl,
      keyboardType: isNum
          ? const TextInputType.numberWithOptions(decimal: true)
          : TextInputType.text,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: AppTheme.surface,
      ),
      validator: required
          ? (v) => (v == null || v.trim().isEmpty) ? 'Wajib diisi' : null
          : null,
    );
  }

  void _submit() async {
    // 1. Validasi form
    if (!_form.currentState!.validate()) return;

    // 2. Aktifkan loading
    setState(() => _isSaving = true);

    try {
      final String phoneInput = _phoneController.text;

      // 3. Bungkus data ke dalam objek Shelter
      final shelter = Shelter(
        id: widget.shelter?.id ??
            DateTime.now().millisecondsSinceEpoch.toString(),
        name: _name.text.trim(),
        address: _address.text.trim(),
        type: _type,
        capacity: int.tryParse(_cap.text) ?? 0,
        currentOccupancy: int.tryParse(_occ.text) ?? 0,
        lat: double.tryParse(_lat.text.trim()) ?? 0.0,
        lng: double.tryParse(_lng.text.trim()) ?? 0.0,
        distance: widget.shelter?.distance ?? 0.0,
        imageUrl: widget.shelter?.imageUrl,
        phone: phoneInput,
      );

      // 4. Proses simpan ke Database (Tambah baru atau Edit)
      if (widget.shelter == null) {
        // Jika Tambah Baru
        await context
            .read<AppProvider>()
            .addShelterWithImage(shelter, _selectedImage);
      } else {
        // Jika Edit
        await context
            .read<AppProvider>()
            .updateShelterWithImage(shelter, _selectedImage);
      }

      // 5. Jika berhasil, tutup form dan jalankan callback
      if (mounted) {
        Navigator.pop(context);
        widget.onSave(shelter, _selectedImage);
      }
    } catch (e) {
      // 6. Tangani jika terjadi error
      debugPrint("Error simpan shelter: $e");
      if (mounted) {
        setState(
            () => _isSaving = false); // Matikan loading agar tombol aktif lagi
        _showSnack(context, "Gagal menyimpan: $e", Colors.red);
      }
    }
  }
}

// ══════════════════════════════════════════════════════════════════
// Card Shelter Admin (dengan icon dinamis & dukungan gambar)
// ══════════════════════════════════════════════════════════════════
class _ShelterAdminCard extends StatefulWidget {
  final Shelter shelter;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final Function(int) onUpdateOccupancy;

  const _ShelterAdminCard({
    super.key, // Tambahkan super.key agar widget tidak tertukar saat di-scroll
    required this.shelter,
    required this.onEdit,
    required this.onDelete,
    required this.onUpdateOccupancy,
  });

  @override
  State<_ShelterAdminCard> createState() => _ShelterAdminCardState();
}

class _ShelterAdminCardState extends State<_ShelterAdminCard> {
  // Hanya gunakan SATU controller agar data konsisten
  late TextEditingController _occupancyController;

  @override
  void initState() {
    super.initState();
    _occupancyController = TextEditingController(
      text: widget.shelter.currentOccupancy.toString(),
    );
  }

  @override
  void didUpdateWidget(covariant _ShelterAdminCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Jika data shelter berubah dari luar (misal setelah refresh), update isi textfield
    if (oldWidget.shelter.currentOccupancy != widget.shelter.currentOccupancy) {
      _occupancyController.text = widget.shelter.currentOccupancy.toString();
    }
  }

  @override
  void dispose() {
    _occupancyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.shelter;
    final pct = (s.currentOccupancy / s.capacity).clamp(0.0, 1.0);
    final Color statusColor = pct >= 1.0
        ? AppTheme.statusBahaya
        : pct >= 0.8
            ? AppTheme.statusWaspada
            : AppTheme.statusAman;

    final IconData shelterIcon = getShelterIcon(s.type, s.name);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Gambar & Nama
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: (s.imageUrl != null &&
                        s.imageUrl!.isNotEmpty &&
                        s.imageUrl != 'null')
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: s.imageUrl!.startsWith('http')
                            ? CachedNetworkImage(
                                imageUrl: s.imageUrl!,
                                fit: BoxFit.cover,
                                errorWidget: (context, url, error) {
                                  return Icon(
                                    shelterIcon,
                                    size: 22,
                                    color: AppTheme.primary,
                                  );
                                },
                              )
                            : Image.file(
                                File(s.imageUrl!),
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    Icon(shelterIcon,
                                        size: 22, color: AppTheme.primary),
                              ),
                      )
                    : Icon(shelterIcon, size: 22, color: AppTheme.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(s.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                            color: AppTheme.textPrimary)),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(shelterIcon,
                            size: 12, color: AppTheme.textSecondary),
                        const SizedBox(width: 4),
                        Text(s.type,
                            style: const TextStyle(
                                fontSize: 12, color: AppTheme.textSecondary)),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                  onPressed: widget.onEdit,
                  icon:
                      const Icon(Icons.edit_outlined, color: AppTheme.primary)),
              IconButton(
                  onPressed: widget.onDelete,
                  icon: const Icon(Icons.delete_outline,
                      color: AppTheme.statusBahaya)),
            ],
          ),
          const SizedBox(height: 12),
          // Alamat
          Row(
            children: [
              const Icon(Icons.location_on_outlined,
                  size: 14, color: AppTheme.textSecondary),
              const SizedBox(width: 6),
              Expanded(
                child: Text(s.address,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 12, color: AppTheme.textSecondary)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
                value: pct,
                minHeight: 8,
                backgroundColor: AppTheme.borderLight,
                color: statusColor),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text('Kapasitas: ${s.capacity}',
                  style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                      fontWeight: FontWeight.w600)),
              const Spacer(),
              Text('${(pct * 100).toInt()}% Penuh',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: statusColor)),
            ],
          ),
          const Divider(height: 24, color: AppTheme.borderLight),
          // Update Occupancy Row
          Row(
            children: [
              const Text('Update Jumlah Pengungsi:',
                  style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                      fontWeight: FontWeight.w600)),
              const Spacer(),
              SizedBox(
                width: 70,
                height: 36,
                child: TextField(
                  controller:
                      _occupancyController, // PAKAI CONTROLLER YANG BENAR
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.bold),
                  decoration: InputDecoration(
                    contentPadding: EdgeInsets.zero,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8)),
                    filled: true,
                    fillColor: AppTheme.surface,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary.withOpacity(0.1),
                  foregroundColor: AppTheme.primary,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () async {
                  // Ambil angka terbaru dari TextField
                  final int? newVal = int.tryParse(_occupancyController.text);

                  if (newVal != null) {
                    debugPrint("Mencoba simpan angka baru: $newVal");
                    try {
                      // Panggil fungsi Provider
                      await context
                          .read<AppProvider>()
                          .updateShelterOccupancy(widget.shelter.id, newVal);

                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Kapasitas berhasil diperbarui!'),
                              backgroundColor: Colors.green),
                        );
                      }
                    } catch (e) {
                      debugPrint("Gagal: $e");
                    }
                  }
                },
                child: const Text("Simpan", style: TextStyle(fontSize: 12)),
              )
            ],
          ),
        ],
      ),
    );
  }
}
