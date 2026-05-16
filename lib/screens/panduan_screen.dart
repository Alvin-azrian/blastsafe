// lib/screens/panduan_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/app_provider.dart';
import '../theme.dart';
import 'shelter_screen.dart' show AppScreenHeader;

class PanduanScreen extends StatefulWidget {
  const PanduanScreen({super.key});

  @override
  State<PanduanScreen> createState() => _PanduanScreenState();
}

class _PanduanScreenState extends State<PanduanScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        return Scaffold(
          backgroundColor: AppTheme.surface,
          body: NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) => [
              SliverToBoxAdapter(
                child: Column(
                  children: [
                    // ── CONSISTENT HEADER ──────────────────
                    AppScreenHeader(
                      emoji: '🌊',
                      title: 'Panduan Keselamatan',
                      subtitle: 'Panduan lengkap perlindungan diri & keluarga',
                    ),
                    // ── TAB BAR ────────────────────────────
                    Container(
                      color: AppTheme.primary,
                      child: TabBar(
                        controller: _tabController,
                        indicator: BoxDecoration(
                          color: Colors.white.withOpacity(0.18),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        indicatorSize: TabBarIndicatorSize.tab,
                        indicatorPadding: const EdgeInsets.symmetric(
                            horizontal: 4, vertical: 5),
                        labelColor: Colors.white,
                        unselectedLabelColor: Colors.white60,
                        labelStyle: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                        unselectedLabelStyle: const TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 13,
                        ),
                        tabs: const [
                          Tab(text: 'Persiapan'),
                          Tab(text: 'Saat Banjir'),
                          Tab(text: 'Pasca Banjir'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
            body: TabBarView(
              controller: _tabController,
              children: [
                _TabPersiapan(tips: provider.safetyTips),
                const _TabSaatBanjir(),
                const _TabPascaBanjir(),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ─── TAB PERSIAPAN ───────────────────────────────────────────────────────────

class _TabPersiapan extends StatelessWidget {
  final List tips;
  const _TabPersiapan({required this.tips});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
      children: [
        const _SectionHeader(
          icon: '🎒',
          title: 'Persiapan Sebelum Banjir',
          subtitle: 'Lakukan ini saat kondisi masih aman',
          color: AppTheme.statusAman,
        ),
        const SizedBox(height: 16),
        ...List.generate(
          tips.length,
          (i) => _TipCard(
            number: i + 1,
            icon: tips[i].icon,
            title: tips[i].title,
            description: tips[i].description,
          ),
        ),
        const SizedBox(height: 8),
        const _InfoBox(
          icon: '💼',
          title: 'Isi Tas Darurat',
          items: [
            'KTP, KK, Akta kelahiran (dalam plastik waterproof)',
            'Obat-obatan pribadi dan P3K',
            'Makanan & air minum untuk 3 hari',
            'Pakaian ganti secukupnya',
            'Senter + baterai cadangan',
            'Uang tunai secukupnya',
            'Powerbank & charger HP',
            'Selimut / sleeping bag ringan',
          ],
          color: Color(0xFF1565C0),
        ),
      ],
    );
  }
}

// ─── TAB SAAT BANJIR ─────────────────────────────────────────────────────────

class _TabSaatBanjir extends StatelessWidget {
  const _TabSaatBanjir();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
      children: const [
        _SectionHeader(
          icon: '🌊',
          title: 'Tindakan Saat Banjir',
          subtitle: 'Langkah-langkah keselamatan yang harus dilakukan',
          color: AppTheme.statusWaspada,
        ),
        SizedBox(height: 16),
        _StepCard(
          step: 1,
          icon: '⚡',
          title: 'Matikan Listrik',
          description: 'Segera cabut semua peralatan listrik dan matikan MCB.',
          isUrgent: true,
        ),
        _StepCard(
          step: 2,
          icon: '📦',
          title: 'Pindahkan Barang Penting',
          description: 'Angkat barang penting ke tempat yang lebih tinggi.',
          isUrgent: true,
        ),
        _StepCard(
          step: 3,
          icon: '🚪',
          title: 'Evakuasi Tepat Waktu',
          description: 'Segera menuju shelter terdekat sebelum air naik.',
          isUrgent: true,
        ),
        _StepCard(
          step: 4,
          icon: '🚫',
          title: 'Hindari Arus Deras',
          description: 'Jangan menyeberangi banjir dengan arus deras.',
          isUrgent: true,
        ),
        _StepCard(
          step: 5,
          icon: '📱',
          title: 'Tetap Komunikasi',
          description: 'Simpan HP dan ikuti informasi resmi.',
          isUrgent: false,
        ),
        _StepCard(
          step: 6,
          icon: '🐾',
          title: 'Jaga Hewan Peliharaan',
          description: 'Bawa hewan peliharaan jika memungkinkan.',
          isUrgent: false,
        ),
        SizedBox(height: 8),
        _WarningBox(
          title: '⚠️ LARANGAN KERAS',
          items: [
            'Jangan melewati genangan air',
            'Jangan sentuh kabel listrik',
            'Jangan kembali sebelum aman',
            'Jangan minum air banjir',
          ],
        ),
      ],
    );
  }
}

// ─── TAB PASCA BANJIR ────────────────────────────────────────────────────────

class _TabPascaBanjir extends StatelessWidget {
  const _TabPascaBanjir();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
      children: const [
        _SectionHeader(
          icon: '🌱',
          title: 'Setelah Banjir Surut',
          subtitle: 'Langkah pemulihan yang aman',
          color: AppTheme.statusAman,
        ),
        SizedBox(height: 16),
        _StepCard(
          step: 1,
          icon: '🔍',
          title: 'Periksa Bangunan',
          description: 'Cek kerusakan sebelum masuk rumah.',
          isUrgent: true,
        ),
        _StepCard(
          step: 2,
          icon: '💡',
          title: 'Cek Listrik',
          description: 'Pastikan instalasi listrik aman.',
          isUrgent: true,
        ),
        _StepCard(
          step: 3,
          icon: '🧹',
          title: 'Bersihkan Rumah',
          description: 'Bersihkan lumpur dan kotoran.',
          isUrgent: false,
        ),
        _StepCard(
          step: 4,
          icon: '💧',
          title: 'Air Bersih',
          description: 'Gunakan air yang sudah direbus.',
          isUrgent: false,
        ),
        _StepCard(
          step: 5,
          icon: '🏥',
          title: 'Waspada Penyakit',
          description: 'Periksa gejala penyakit pasca banjir.',
          isUrgent: false,
        ),
        SizedBox(height: 8),
        _InfoBox(
          icon: '📋',
          title: 'Dokumen Penting',
          items: [
            'Foto kerusakan rumah',
            'Daftar barang rusak',
            'Data kontak darurat',
            'Laporan RT/RW',
          ],
          color: AppTheme.info,
        ),
      ],
    );
  }
}

// ─── SECTION HEADER ──────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String icon;
  final String title;
  final String subtitle;
  final Color color;

  const _SectionHeader({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withOpacity(0.12),
            color.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.25), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color.withOpacity(0.2)),
            ),
            child: Center(
              child: Text(icon, style: const TextStyle(fontSize: 24)),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                    color: color,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── TIP CARD ────────────────────────────────────────────────────────────────

class _TipCard extends StatelessWidget {
  final int number;
  final String icon;
  final String title;
  final String description;

  const _TipCard({
    required this.number,
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppTheme.primary.withOpacity(0.15),
                    AppTheme.primary.withOpacity(0.08),
                  ],
                ),
                borderRadius: BorderRadius.circular(9),
                border: Border.all(
                    color: AppTheme.primary.withOpacity(0.2), width: 1),
              ),
              child: Center(
                child: Text(
                  '$number',
                  style: const TextStyle(
                    color: AppTheme.primary,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.grey.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(icon, style: const TextStyle(fontSize: 14)),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── STEP CARD ───────────────────────────────────────────────────────────────

class _StepCard extends StatelessWidget {
  final int step;
  final String icon;
  final String title;
  final String description;
  final bool isUrgent;

  const _StepCard({
    required this.step,
    required this.icon,
    required this.title,
    required this.description,
    required this.isUrgent,
  });

  @override
  Widget build(BuildContext context) {
    final accentColor = isUrgent ? AppTheme.statusBahaya : AppTheme.primary;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isUrgent
              ? AppTheme.statusBahaya.withOpacity(0.25)
              : AppTheme.border,
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: isUrgent
                ? AppTheme.statusBahaya.withOpacity(0.06)
                : Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                width: 56,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      accentColor.withOpacity(0.12),
                      accentColor.withOpacity(0.06),
                    ],
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: accentColor,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: accentColor.withOpacity(0.35),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          '$step',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(icon, style: const TextStyle(fontSize: 16)),
                  ],
                ),
              ),
              Expanded(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                                color: AppTheme.textPrimary,
                                letterSpacing: -0.1,
                              ),
                            ),
                          ),
                          if (isUrgent) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 7, vertical: 3),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    AppTheme.statusBahaya,
                                    AppTheme.statusBahaya.withOpacity(0.8),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'PENTING',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 5),
                      Text(
                        description,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── INFO BOX ────────────────────────────────────────────────────────────────

class _InfoBox extends StatelessWidget {
  final String icon;
  final String title;
  final List<String> items;
  final Color color;

  const _InfoBox({
    required this.icon,
    required this.title,
    required this.items,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withOpacity(0.09),
            color.withOpacity(0.04),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.22), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(9),
                    border: Border.all(color: color.withOpacity(0.2)),
                  ),
                  child: Text(icon, style: const TextStyle(fontSize: 16)),
                ),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    color: color,
                    letterSpacing: -0.1,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...items.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 5),
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        item,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppTheme.textPrimary,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── WARNING BOX ─────────────────────────────────────────────────────────────

class _WarningBox extends StatelessWidget {
  final String title;
  final List<String> items;

  const _WarningBox({required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.statusBahaya.withOpacity(0.08),
            AppTheme.statusBahaya.withOpacity(0.03),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: AppTheme.statusBahaya.withOpacity(0.3), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: AppTheme.statusBahaya.withOpacity(0.07),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: AppTheme.statusBahaya.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: const Text('⚠️', style: TextStyle(fontSize: 16)),
                ),
                const SizedBox(width: 10),
                const Text(
                  'LARANGAN KERAS',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    color: AppTheme.statusBahaya,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...items.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: AppTheme.statusBahaya.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: const Text('🚫', style: TextStyle(fontSize: 10)),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        item,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppTheme.textPrimary,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
