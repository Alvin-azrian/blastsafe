// lib/screens/home_screen.dart
// REDESIGN: Tampilan modern, responsif, hidup dengan animasi
// Fitur tidak berubah — hanya tampilan yang diperbarui

import 'dart:math' as math;
import 'package:flutter/services.dart'; // Untuk menutup aplikasi
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/app_provider.dart';
import '../models/app_models.dart';
import '../theme.dart';
import 'admin_screen.dart';
import 'shelter_screen.dart';
import 'panduan_screen.dart';
import 'kontak_screen.dart';
import 'laporan_screen.dart';
import 'notifikasi_screen.dart';
import '../services/location_service.dart';
import '../services/bmkg_service.dart';

// ─── Constants ───────────────────────────────────────────────────────────────
const _kRadius = 20.0;
const _kRadiusSm = 14.0;
const _kPad = 16.0;

// ── Home Screen ──────────────────────────────────────────────────────────────
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();

  static Color _statusColor(FloodStatus s) {
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
}

class _HomeScreenState extends State<HomeScreen> {
  DateTime? _lastPressedAt;

  @override
  void initState() {
    super.initState();
    _loadWeatherByLocation();
  }

  Future<void> _loadWeatherByLocation() async {
    final pos = await LocationService.getCurrentPosition();

    final provider = context.read<AppProvider>();

    if (pos == null) {
      provider.fetchBmkgWeather();
      return;
    }

    final adm4 = _getAdm4(pos.latitude, pos.longitude);

    provider.fetchBmkgWeather(adm4);
  }

  String _getAdm4(double lat, double lng) {
    // Sukarame
    if (lat > -5.40 && lng > 105.28) {
      return '18.71.11.1001';
    }
    // Tanjungkarang Timur
    if (lat > -5.42 && lat < -5.40 && lng > 105.26) {
      return '18.71.04.1001';
    }
    // Rajabasa
    if (lat > -5.37 && lng > 105.24 && lng < 105.26) {
      return '18.71.10.1001';
    }
    // Way Halim
    if (lat > -5.39 && lng > 105.26 && lng < 105.28) {
      return '18.71.13.1001';
    }
    // Tanjungkarang Pusat
    if (lat > -5.41 && lng > 105.25 && lng < 105.26) {
      return '18.71.05.1001';
    }

    return '18.71.03.1001'; // Default Tanjungkarang Barat
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // Menahan agar tidak langsung close saat tekan back
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;

        final now = DateTime.now();
        // Cek jika jeda antar ketukan lebih dari 2 detik
        if (_lastPressedAt == null ||
            now.difference(_lastPressedAt!) > const Duration(seconds: 2)) {
          _lastPressedAt = now;

          // Munculkan peringatan
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Tekan sekali lagi untuk keluar'),
              backgroundColor: AppTheme.primaryDark,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 2),
              margin: const EdgeInsets.all(20),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
          );
        } else {
          // Jika ditekan 2x dalam < 2 detik, aplikasi tutup
          SystemNavigator.pop();
        }
      },
      child: Consumer<AppProvider>(
        builder: (context, provider, _) {
          final status = provider.state.status;
          final isAman = status == FloodStatus.aman;
          final statusColor = HomeScreen._statusColor(status);

          return Scaffold(
            backgroundColor: const Color(0xFFF0F4FF),
            body: NestedScrollView(
              headerSliverBuilder: (ctx, innerBoxIsScrolled) => [
                SliverAppBar(
                  expandedHeight: 260,
                  floating: false,
                  pinned: true,
                  elevation: 0,
                  backgroundColor: AppTheme.primaryDark,
                  title: innerBoxIsScrolled
                      ? _CollapsedTitle(provider: provider)
                      : null,
                  actions: [
                    _NotifBell(
                      count: provider.unreadNotifCount,
                      onTap: () => Navigator.push(
                        ctx,
                        MaterialPageRoute(
                          builder: (_) => const NotifikasiScreen(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  flexibleSpace: FlexibleSpaceBar(
                    collapseMode: CollapseMode.pin,
                    background: _HomeHeader(
                      provider: provider,
                      isAman: isAman,
                      statusColor: statusColor,
                      onAdminTap: () => Navigator.push(
                        ctx,
                        MaterialPageRoute(
                          builder: (_) => const AdminScreen(),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
              body: _HomeBody(
                provider: provider,
                isAman: isAman,
                statusColor: statusColor,
              ),
            ),
          );
        },
      ),
    );
  }
}

// ── Collapsed Title ──────────────────────────────────────────────────────────
class _CollapsedTitle extends StatelessWidget {
  final AppProvider provider;
  const _CollapsedTitle({required this.provider});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF60A5FA), Color(0xFF3B82F6)],
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Center(
            child: Text('🌊', style: TextStyle(fontSize: 14)),
          ),
        ),
        const SizedBox(width: 8),
        const Text(
          'BlastSafe',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: Colors.white,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.18),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '${provider.state.statusEmoji} ${provider.state.statusLabel}',
            style: const TextStyle(
              fontSize: 10,
              color: Colors.white,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ),
          ),
        ),
      ],
    );
  }
}

// ── Notif Bell ───────────────────────────────────────────────────────────────
class _NotifBell extends StatelessWidget {
  final int count;
  final VoidCallback onTap;
  const _NotifBell({required this.count, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          margin: const EdgeInsets.only(right: 4),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            icon: const Icon(
              Icons.notifications_outlined,
              color: Colors.white,
              size: 22,
            ),
            tooltip: 'Notifikasi',
            onPressed: onTap,
          ),
        ),
        if (count > 0)
          Positioned(
            right: 6,
            top: 6,
            child: Container(
              padding: const EdgeInsets.all(3),
              constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFF6B6B), Color(0xFFEF4444)],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.red.withOpacity(0.4),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  )
                ],
              ),
              child: Text(
                count > 9 ? '9+' : '$count',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.w800),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }
}

// ── Header ────────────────────────────────────────────────────────────────────
class _HomeHeader extends StatefulWidget {
  final AppProvider provider;
  final bool isAman;
  final Color statusColor;
  final VoidCallback onAdminTap;

  const _HomeHeader({
    required this.provider,
    required this.isAman,
    required this.statusColor,
    required this.onAdminTap,
  });

  @override
  State<_HomeHeader> createState() => _HomeHeaderState();
}

class _HomeHeaderState extends State<_HomeHeader>
    with TickerProviderStateMixin {
  late AnimationController _pulseCtrl;
  late AnimationController _waveCtrl;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _waveCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();

    _pulseAnim = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _waveCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isAman = widget.isAman;
    final statusColor = widget.statusColor;

    final List<Color> gradColors = isAman
        ? [
            const Color(0xFF0F2B5B),
            const Color(0xFF1A4A9F),
            const Color(0xFF2563EB),
          ]
        : statusColor == AppTheme.statusWaspada
            ? [
                const Color(0xFF7C2D12),
                const Color(0xFFB45309),
                const Color(0xFFD97706),
              ]
            : statusColor == AppTheme.statusSiaga
                ? [
                    const Color(0xFF7C2D12),
                    const Color(0xFFB91C1C),
                    const Color(0xFFDC2626),
                  ]
                : [
                    const Color(0xFF450A0A),
                    const Color(0xFF991B1B),
                    const Color(0xFFDC2626),
                  ];

    return AnimatedBuilder(
      animation: Listenable.merge([_pulseCtrl, _waveCtrl]),
      builder: (context, _) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: gradColors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Stack(
            children: [
              // Dekoratif lingkaran kanan atas
              Positioned(
                right: -50,
                top: -50,
                child: Opacity(
                  opacity: 0.07,
                  child: Container(
                    width: 220,
                    height: 220,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 45),
                    ),
                  ),
                ),
              ),
              // Dekoratif lingkaran kiri bawah
              Positioned(
                left: -30,
                bottom: -40,
                child: Opacity(
                  opacity: 0.05,
                  child: Container(
                    width: 160,
                    height: 160,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 35),
                    ),
                  ),
                ),
              ),
              // Wave animasi di bawah
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: CustomPaint(
                  painter: _WavePainter(_waveCtrl.value),
                  size: const Size(double.infinity, 32),
                ),
              ),
              // Konten utama
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 60, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeaderTop(),
                      const SizedBox(height: 14),
                      _buildStatusPill(statusColor),
                      const SizedBox(height: 12),
                      _buildWeather(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeaderTop() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        ScaleTransition(
          scale: _pulseAnim,
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withOpacity(0.3)),
            ),
            child: const Center(
              child: Text('🌊', style: TextStyle(fontSize: 22)),
            ),
          ),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'BlastSafe',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: -0.5,
                  height: 1.1,
                ),
              ),
              SizedBox(height: 2),
              Text(
                'Sistem Informasi Banjir · Bandar Lampung',
                style: TextStyle(
                  fontSize: 10.5,
                  color: Colors.white54,
                  letterSpacing: 0.1,
                ),
              ),
            ],
          ),
        ),
        _AdminButton(onTap: widget.onAdminTap),
      ],
    );
  }

  Widget _buildStatusPill(Color statusColor) {
    final dotColor = widget.isAman ? Colors.greenAccent : statusColor;

    return Row(
      children: [
        // Animasi pulse dot
        AnimatedBuilder(
          animation: _pulseCtrl,
          builder: (_, __) => SizedBox(
            width: 28,
            height: 28,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 28 * _pulseAnim.value,
                  height: 28 * _pulseAnim.value,
                  decoration: BoxDecoration(
                    color: dotColor.withOpacity(0.25),
                    shape: BoxShape.circle,
                  ),
                ),
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: dotColor,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: dotColor.withOpacity(0.6),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
            color: (widget.isAman ? Colors.greenAccent : statusColor)
                .withOpacity(0.18),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: (widget.isAman ? Colors.greenAccent : statusColor)
                  .withOpacity(0.45),
            ),
          ),
          child: Text(
            '${widget.provider.state.statusEmoji}  ${widget.provider.state.statusLabel}',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: widget.isAman ? Colors.greenAccent : Colors.white,
              letterSpacing: 0.3,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            widget.provider.state.showWarning
                ? widget.provider.state.warningMessage
                : 'Kondisi normal — tetap waspada',
            style: const TextStyle(
              fontSize: 11,
              color: Colors.white60,
              height: 1.35,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildWeather() => _BmkgWeatherWidget(provider: widget.provider);
}

// ── Wave Painter ──────────────────────────────────────────────────────────────
class _WavePainter extends CustomPainter {
  final double phase;
  _WavePainter(this.phase);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFF0F4FF)
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(0, size.height);

    for (double x = 0; x <= size.width; x++) {
      final y = size.height * 0.5 +
          math.sin((x / size.width * 2 * math.pi) + (phase * 2 * math.pi)) *
              size.height *
              0.3 +
          math.sin((x / size.width * 3 * math.pi) +
                  (phase * 2 * math.pi * 1.5)) *
              size.height *
              0.15;
      path.lineTo(x, y);
    }

    path.lineTo(size.width, size.height);
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_WavePainter old) => old.phase != phase;
}

// ── Admin Button ──────────────────────────────────────────────────────────────
class _AdminButton extends StatelessWidget {
  final VoidCallback onTap;
  const _AdminButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.25)),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('🛡️', style: TextStyle(fontSize: 13)),
            SizedBox(width: 5),
            Text(
              'Admin',
              style: TextStyle(
                fontSize: 12,
                color: Colors.white,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── BMKG Weather Widget ───────────────────────────────────────────────────────
class _BmkgWeatherWidget extends StatelessWidget {
  final AppProvider provider;
  const _BmkgWeatherWidget({required this.provider});

  void _showAllWeatherPopup(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.6,
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              const Text(
                'Cuaca Bandar Lampung (BMKG)',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E3A5F)),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: FutureBuilder<List<BmkgWeather>>(
                  // UBAH DI SINI: Tambahkan 'true' agar tidak pakai fallback
                  future: Future.wait(BmkgService.adm4List
                      .map((kode) => BmkgService().fetchWeather(kode, true))),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return const Center(
                          child: Text("Gagal memuat data cuaca."));
                    }

                    final weatherList = snapshot.data!;
                    return ListView.builder(
                      itemCount: weatherList.length,
                      itemBuilder: (context, index) {
                        final w = weatherList[index];
                        final kode = BmkgService.adm4List[index];

                        // UBAH DI SINI: Paksa gunakan nama asli kecamatan, jangan pakai bawaan API BMKG
                        final namaWilayah =
                            BmkgService.adm4Names[kode] ?? w.lokasi;

                        return ListTile(
                          leading: Text(w.weatherEmoji,
                              style: const TextStyle(fontSize: 24)),
                          title: Text(namaWilayah,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 14)),
                          subtitle: Text(
                              '${w.description} • ${w.temperature.toInt()}°C\n💧 ${w.humidity.toInt()}%  💨 ${w.windSpeed.toInt()} km/j'),
                          isThreeLine: true,
                          contentPadding:
                              const EdgeInsets.symmetric(vertical: 4),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (provider.bmkgLoading) return _buildLoading();
    final w = provider.bmkgWeather;
    if (w == null) return _buildError();
    final isOffline = _isOffline(w.description);

    return GestureDetector(
      // MEMANGGIL FUNGSI POPUP SAAT DIKLIK
      onTap: () => _showAllWeatherPopup(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isOffline
                ? Colors.orange.withOpacity(0.5)
                : Colors.white.withOpacity(0.2),
          ),
        ),
        child: Row(
          children: [
            Text(w.weatherEmoji, style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 10),
            Expanded(child: _buildWeatherInfo(w, isOffline)),
            if (w.isRaining && !isOffline) _buildRainWarning(),
            const SizedBox(width: 8),
            // TOMBOL DETAIL MENGGANTIKAN LABEL BMKG LAMA
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.blueAccent.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Text(
                    'Detail',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                  SizedBox(width: 2),
                  Icon(Icons.keyboard_arrow_down,
                      size: 14, color: Colors.white),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoading() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 12,
            height: 12,
            child: CircularProgressIndicator(
                strokeWidth: 1.5, color: Colors.white70),
          ),
          SizedBox(width: 10),
          Text(
            'Mengambil data BMKG Bandar Lampung...',
            style: TextStyle(fontSize: 15, color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Widget _buildError() {
    return GestureDetector(
      // Jika error, tetap biarkan fetch ulang cuaca utama (bukan popup)
      onTap: provider.fetchBmkgWeather,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.orange.withOpacity(0.3)),
        ),
        child: const Text(
          '⚡ Gagal memuat cuaca BMKG — tap untuk retry',
          style: TextStyle(fontSize: 11, color: Colors.white70),
        ),
      ),
    );
  }

  Widget _buildWeatherInfo(BmkgWeather w, bool isOffline) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isOffline
              ? 'Data BMKG tidak tersedia (offline)'
              : '${w.temperature.toInt()}°C  ·  ${w.description}',
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        Text(
          isOffline
              ? '📍 ${w.lokasi} — tap untuk retry'
              : '💧 ${w.humidity.toInt()}%  💨 ${w.windSpeed.toInt()} km/j  📍 ${w.lokasi}',
          style: const TextStyle(fontSize: 10, color: Colors.white60),
        ),
      ],
    );
  }

  Widget _buildRainWarning() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange.withOpacity(0.4)),
      ),
      child: const Text(
        'Waspada\nHujan',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 8,
          color: Colors.white,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  bool _isOffline(String desc) =>
      desc.contains('Offline') || desc.contains('offline');
}

// ── Home Body ─────────────────────────────────────────────────────────────────
class _HomeBody extends StatelessWidget {
  final AppProvider provider;
  final bool isAman;
  final Color statusColor;

  const _HomeBody({
    required this.provider,
    required this.isAman,
    required this.statusColor,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(_kPad, 18, _kPad, 40),
      children: [
        _buildTopBanners(context),
        const _SectionLabel(text: 'Menu Utama', icon: '⚡'),
        const SizedBox(height: 12),
        _MainMenuGrid(provider: provider),
        const SizedBox(height: 24),
        const _SectionLabel(text: 'Shelter Terdekat', icon: '🏘️'),
        const SizedBox(height: 12),
        _ShelterSummary(provider: provider),
        const SizedBox(height: 24),
        const _SectionLabel(text: 'Laporan Terkini', icon: '📋'),
        const SizedBox(height: 12),
        _RecentReports(provider: provider),
      ],
    );
  }

  Widget _buildTopBanners(BuildContext context) {
    final hasBanner =
        provider.showWarningBanner || provider.unreadNotifCount > 0;
    if (!hasBanner) return const SizedBox(height: 4);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        children: [
          if (provider.showWarningBanner)
            _WarningBanner(provider: provider, statusColor: statusColor),
          if (provider.unreadNotifCount > 0)
            _UnreadNotifBanner(
              count: provider.unreadNotifCount,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const NotifikasiScreen()),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Section Label ─────────────────────────────────────────────────────────────
class _SectionLabel extends StatelessWidget {
  final String text;
  final String icon;
  const _SectionLabel({required this.text, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(icon, style: const TextStyle(fontSize: 15)),
        const SizedBox(width: 8),
        Text(
          text,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: Color(0xFF1E3A5F),
            letterSpacing: 0.1,
          ),
        ),
      ],
    );
  }
}

// ── Warning Banner ─────────────────────────────────────────────────────────────
class _WarningBanner extends StatelessWidget {
  final AppProvider provider;
  final Color statusColor;

  const _WarningBanner({
    required this.provider,
    required this.statusColor,
  });

  @override
  Widget build(BuildContext context) {
    final state = provider.state;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            statusColor.withOpacity(0.12),
            statusColor.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(_kRadius),
        border: Border.all(color: statusColor.withOpacity(0.35)),
        boxShadow: [
          BoxShadow(
            color: statusColor.withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(state.statusEmoji,
                    style: const TextStyle(fontSize: 22)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Status: ${state.statusLabel}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: statusColor,
                    ),
                  ),
                  if (state.warningMessage.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        state.warningMessage,
                        style: const TextStyle(
                            fontSize: 12, color: AppTheme.textSecondary),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: provider.dismissWarning,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.close, size: 16, color: statusColor),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Unread Notif Banner ───────────────────────────────────────────────────────
class _UnreadNotifBanner extends StatelessWidget {
  final int count;
  final VoidCallback onTap;
  const _UnreadNotifBanner({required this.count, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1D4ED8), Color(0xFF3B82F6)],
        ),
        borderRadius: BorderRadius.circular(_kRadius),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF3B82F6).withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(_kRadius),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.notifications_active_outlined,
                    size: 18,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Ada $count pesan baru dari Admin',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
                const Icon(Icons.arrow_forward_ios,
                    size: 14, color: Colors.white70),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Main Menu Grid ────────────────────────────────────────────────────────────
// IMPROVEMENT: childAspectRatio 2.5 → 2.8 supaya card tidak terlalu gepeng,
// teks & icon lebih bernapas, crossAxisSpacing & mainAxisSpacing sedikit lebih lega.
class _MainMenuGrid extends StatelessWidget {
  final AppProvider provider;
  const _MainMenuGrid({required this.provider});

  @override
  Widget build(BuildContext context) {
    final items = _buildMenuItems(context);

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 2.8,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      children: items
          .asMap()
          .entries
          .map((e) => _AnimatedMenuCard(item: e.value, index: e.key))
          .toList(),
    );
  }

  List<_MenuItem> _buildMenuItems(BuildContext context) {
    return [
      _MenuItem(
        icon: '🏘️',
        label: 'Shelter',
        desc: 'Lokasi pengungsian',
        color: const Color(0xFF10B981),
        onTap: () => _go(context, const ShelterScreen()),
      ),
      _MenuItem(
        icon: '📖',
        label: 'Panduan',
        desc: 'Tips keselamatan',
        color: const Color(0xFF8B5CF6),
        onTap: () => _go(context, const PanduanScreen()),
      ),
      _MenuItem(
        icon: '📞',
        label: 'Kontak',
        desc: 'Nomor darurat',
        color: const Color(0xFFF59E0B),
        onTap: () => _go(context, const KontakScreen()),
      ),
      _MenuItem(
        icon: '📝',
        label: 'Laporan',
        desc: 'Laporkan kondisi',
        color: const Color(0xFFEF4444),
        onTap: () => _go(context, const LaporanScreen()),
      ),
    ];
  }

  void _go(BuildContext context, Widget page) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }
}

// ── Animated Menu Card ────────────────────────────────────────────────────────
// IMPROVEMENT: hapus _pressed state (redundant, sudah ada AnimationController).
// Shadow berubah hanya via AnimatedContainer, cukup.
class _AnimatedMenuCard extends StatefulWidget {
  final _MenuItem item;
  final int index;
  const _AnimatedMenuCard({required this.item, required this.index});

  @override
  State<_AnimatedMenuCard> createState() => _AnimatedMenuCardState();
}

class _AnimatedMenuCardState extends State<_AnimatedMenuCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scaleAnim;
  bool _isDown = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnim = Tween<double>(begin: 1.0, end: 0.95).animate(
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
    final m = widget.item;
    return ScaleTransition(
      scale: _scaleAnim,
      child: GestureDetector(
        onTapDown: (_) {
          setState(() => _isDown = true);
          _ctrl.forward();
        },
        onTapUp: (_) {
          setState(() => _isDown = false);
          _ctrl.reverse();
          m.onTap();
        },
        onTapCancel: () {
          setState(() => _isDown = false);
          _ctrl.reverse();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(_kRadius),
            boxShadow: [
              BoxShadow(
                color: m.color.withOpacity(_isDown ? 0.22 : 0.09),
                blurRadius: _isDown ? 18 : 10,
                offset: const Offset(0, 4),
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
            border: Border.all(
              color:
                  _isDown ? m.color.withOpacity(0.35) : const Color(0xFFE8EEF8),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: m.color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Center(
                  child: Text(m.icon, style: const TextStyle(fontSize: 18)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      m.label,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1E3A5F),
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      m.desc,
                      style: const TextStyle(
                        fontSize: 10,
                        color: Color(0xFF8FA3BF),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                size: 16,
                color: m.color.withOpacity(0.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MenuItem {
  final String icon;
  final String label;
  final String desc;
  final Color color;
  final VoidCallback onTap;

  const _MenuItem({
    required this.icon,
    required this.label,
    required this.desc,
    required this.color,
    required this.onTap,
  });
}

// ── Shelter Summary ───────────────────────────────────────────────────────────
// IMPROVEMENT: Stat kiri & donut kanan lebih proporsional.
// Progress bar sedikit lebih tebal (8px) biar lebih kelihatan.
class _ShelterSummary extends StatelessWidget {
  final AppProvider provider;
  const _ShelterSummary({required this.provider});

  @override
  Widget build(BuildContext context) {
    final shelters = provider.shelters;
    final available =
        shelters.where((s) => s.currentOccupancy < s.capacity).length;
    final total = shelters.length;
    final pct = total > 0 ? available / total : 0.0;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(_kRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Shelter Tersedia',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1E3A5F),
                ),
              ),
              _SeeAllButton(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ShelterScreen()),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Stat + donut row
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '$available',
                          style: const TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF10B981),
                            height: 1,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4, left: 2),
                          child: Text(
                            ' / $total',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF8FA3BF),
                              height: 1,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    const Text(
                      'shelter tersedia',
                      style: TextStyle(
                        fontSize: 11,
                        color: Color(0xFF8FA3BF),
                      ),
                    ),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: pct,
                        minHeight: 8,
                        backgroundColor: const Color(0xFFE8F4F0),
                        valueColor:
                            const AlwaysStoppedAnimation(Color(0xFF10B981)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              _ShelterDonut(percent: pct),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Shelter Donut ─────────────────────────────────────────────────────────────
class _ShelterDonut extends StatelessWidget {
  final double percent;
  const _ShelterDonut({required this.percent});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 60,
      height: 60,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            value: percent,
            strokeWidth: 7,
            backgroundColor: const Color(0xFFE8F4F0),
            valueColor: const AlwaysStoppedAnimation(Color(0xFF10B981)),
          ),
          Text(
            '${(percent * 100).toInt()}%',
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: Color(0xFF10B981),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Reusable "Lihat semua" button ─────────────────────────────────────────────
class _SeeAllButton extends StatelessWidget {
  final VoidCallback onTap;
  const _SeeAllButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: AppTheme.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Text(
          'Lihat semua →',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: AppTheme.primary,
          ),
        ),
      ),
    );
  }
}

// ── Recent Reports ────────────────────────────────────────────────────────────
class _RecentReports extends StatelessWidget {
  final AppProvider provider;
  const _RecentReports({required this.provider});

  @override
  Widget build(BuildContext context) {
    final recent = provider.reports.take(3).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // "Lihat semua" di kanan, sejajar dengan section label di atas
        Align(
          alignment: Alignment.centerRight,
          child: _SeeAllButton(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const LaporanScreen()),
            ),
          ),
        ),
        const SizedBox(height: 10),
        if (recent.isEmpty)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(_kRadius),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Center(
              child: Text(
                '📭  Belum ada laporan',
                style: TextStyle(fontSize: 13, color: Color(0xFF8FA3BF)),
              ),
            ),
          )
        else
          ...recent.map((r) => _SmallReportCard(r)),
      ],
    );
  }
}

// ── Small Report Card ─────────────────────────────────────────────────────────
// IMPROVEMENT: padding kiri lebih konsisten, IntrinsicHeight tetap dipertahankan.
class _SmallReportCard extends StatelessWidget {
  final WargaReport report;
  const _SmallReportCard(this.report);

  @override
  Widget build(BuildContext context) {
    final verified = report.isVerified;
    final accent = verified ? const Color(0xFF10B981) : const Color(0xFFF59E0B);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(_kRadiusSm),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            // Accent bar kiri
            Container(
              width: 4,
              decoration: BoxDecoration(
                color: accent,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(_kRadiusSm),
                  bottomLeft: Radius.circular(_kRadiusSm),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Ikon status
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
                decoration: BoxDecoration(
                  color: accent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  verified ? '✅' : '⏳',
                  style: const TextStyle(fontSize: 14),
                ),
              ),
            ),
            const SizedBox(width: 10),
            // Konten
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 13),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      report.description,
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1E3A5F),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Text('📍', style: TextStyle(fontSize: 10)),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(
                            report.location,
                            style: const TextStyle(
                              fontSize: 10.5,
                              color: Color(0xFF8FA3BF),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: accent.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            verified ? 'Terverifikasi' : 'Menunggu',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: accent,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
          ],
        ),
      ),
    );
  }
}
