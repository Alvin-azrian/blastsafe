// lib/screens/shelter_screen.dart
// lib/screens/shelter_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/app_provider.dart';
import '../models/app_models.dart';
import '../theme.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io'; // 🔥 TAMBAHKAN BARIS INI
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:cached_network_image/cached_network_image.dart';

// ─── SHARED HEADER WIDGET ────────────────────────────────────────────────────
// Widget ini dipakai di semua screen agar tampilannya konsisten

class AppScreenHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final String emoji;
  final List<AppHeaderStat>? stats;

  const AppScreenHeader({
    super.key,
    required this.title,
    required this.subtitle,
    required this.emoji,
    this.stats,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primary,
            AppTheme.primary.withOpacity(0.82),
          ],
        ),
      ),
      child: Stack(
        children: [
          // Decorative circles
          Positioned(
            right: -30,
            top: -20,
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.05),
              ),
            ),
          ),
          Positioned(
            right: 50,
            top: 15,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.07),
              ),
            ),
          ),
          // Content
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Emoji badge + title row
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child:
                            Text(emoji, style: const TextStyle(fontSize: 22)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.3,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              subtitle,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.75),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  // Stats row (optional)
                  if (stats != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 12, horizontal: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(16),
                        border:
                            Border.all(color: Colors.white.withOpacity(0.12)),
                      ),
                      child: Row(
                        children: [
                          for (int i = 0; i < stats!.length; i++) ...[
                            Expanded(child: _StatCell(stat: stats![i])),
                            if (i < stats!.length - 1)
                              Container(
                                  width: 1,
                                  height: 36,
                                  color: Colors.white.withOpacity(0.18)),
                          ]
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class AppHeaderStat {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const AppHeaderStat({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });
}

class _StatCell extends StatelessWidget {
  final AppHeaderStat stat;
  const _StatCell({required this.stat});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(stat.icon, color: Colors.white60, size: 14),
        const SizedBox(height: 3),
        Text(
          stat.value,
          style: TextStyle(
            color: stat.valueColor ?? Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
        Text(
          stat.label,
          style: const TextStyle(color: Colors.white54, fontSize: 10),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

// ─── SHELTER SCREEN ──────────────────────────────────────────────────────────

class ShelterScreen extends StatefulWidget {
  const ShelterScreen({super.key});

  @override
  State<ShelterScreen> createState() => _ShelterScreenState();
}

class _ShelterScreenState extends State<ShelterScreen>
    with SingleTickerProviderStateMixin {
  String _filter = 'Semua';
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    )..forward();

    // KITA TAMBAHKAN KODE INI UNTUK ERROR HANDLING TAHAP 2
    Future.microtask(() {
      // Pastikan layar masih aktif (mounted) sebelum memunculkan pop-up
      if (mounted) {
        Provider.of<AppProvider>(context, listen: false)
            .refreshAllData(context: context);
      }
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  List<Shelter> _getFiltered(List<Shelter> shelters) {
    List<Shelter> list = List.from(shelters);
    if (_filter == 'Tersedia') {
      list = list.where((s) => s.isAvailable).toList();
    }
    if (_filter == 'Terdekat') {
      list.sort((a, b) => a.distance.compareTo(b.distance));
    }
    return list;
  }

  Future<void> _callShelter(String phone) async {
    final uri = Uri.parse('tel:$phone');
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _openMaps(Shelter shelter) async {
    final url =
        'https://www.google.com/maps/search/?api=1&query=${shelter.lat},${shelter.lng}';
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        final shelters = provider.shelters;
        final filtered = _getFiltered(shelters);
        final total = shelters.length;
        final available = shelters.where((s) => s.isAvailable).length;
        final capacity = shelters.fold(0, (a, b) => a + b.capacity);

        return Scaffold(
          backgroundColor: AppTheme.surface,
          body: CustomScrollView(
            slivers: [
              // ── CONSISTENT HEADER ──────────────────
              SliverToBoxAdapter(
                child: AppScreenHeader(
                  emoji: '🏠',
                  title: 'Shelter & Evakuasi',
                  subtitle: 'Titik evakuasi aman untuk warga',
                  stats: [
                    AppHeaderStat(
                      icon: Icons.home_work_outlined,
                      label: 'Total Shelter',
                      value: '$total',
                    ),
                    AppHeaderStat(
                      icon: Icons.check_circle_outline,
                      label: 'Tersedia',
                      value: '$available',
                      valueColor: const Color(0xFF6EE7B7),
                    ),
                    AppHeaderStat(
                      icon: Icons.people_outline,
                      label: 'Kapasitas',
                      value: '$capacity',
                    ),
                  ],
                ),
              ),
              SliverToBoxAdapter(child: _buildFilterBar()),
              filtered.isEmpty
                  ? SliverFillRemaining(child: _buildEmptyState())
                  : SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (ctx, i) {
                            final shelter = filtered[i];
                            return _AnimatedShelterCard(
                              shelter: shelter,
                              index: i,
                              onTap: () => _showShelterDetail(context, shelter),
                            );
                          },
                          childCount: filtered.length,
                        ),
                      ),
                    ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFilterBar() {
    final filters = ['Semua', 'Tersedia', 'Terdekat'];
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'FILTER SHELTER',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppTheme.textSecondary,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: filters
                .map(
                  (f) => Padding(
                    padding: EdgeInsets.only(right: f != filters.last ? 8 : 0),
                    child: _FilterPill(
                      label: f,
                      selected: _filter == f,
                      onTap: () => setState(() => _filter = f),
                      icon: f == 'Semua'
                          ? Icons.grid_view_rounded
                          : f == 'Tersedia'
                              ? Icons.check_circle_outline
                              : Icons.near_me_outlined,
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppTheme.primary.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.home_work_outlined,
              size: 40,
              color: AppTheme.primary,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Tidak ada shelter tersedia',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Coba ubah filter pencarian',
            style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }

  void _showShelterDetail(BuildContext context, Shelter shelter) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _ShelterDetailSheet(
        shelter: shelter,
        onCall: () => _callShelter(shelter.phone),
        onMaps: () => _openMaps(shelter),
      ),
    );
  }
}

/* ────────────────────────────────────────
   FILTER PILL
──────────────────────────────────────── */

class _FilterPill extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData icon;

  const _FilterPill({
    required this.label,
    required this.selected,
    required this.onTap,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppTheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: selected ? AppTheme.primary : AppTheme.border,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 13,
              color: selected ? Colors.white : AppTheme.textSecondary,
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: selected ? Colors.white : AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/* ────────────────────────────────────────
   ANIMATED SHELTER CARD
──────────────────────────────────────── */

class _AnimatedShelterCard extends StatefulWidget {
  final Shelter shelter;
  final int index;
  final VoidCallback onTap;

  const _AnimatedShelterCard({
    required this.shelter,
    required this.index,
    required this.onTap,
  });

  @override
  State<_AnimatedShelterCard> createState() => _AnimatedShelterCardState();
}

class _AnimatedShelterCardState extends State<_AnimatedShelterCard>
    with SingleTickerProviderStateMixin {
  bool _pressed = false;
  late AnimationController _entryController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  IconData _getShelterIcon(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('masjid')) return Icons.mosque;
    if (lower.contains('sd') ||
        lower.contains('smp') ||
        lower.contains('sma') ||
        lower.contains('sekolah')) return Icons.school;
    if (lower.contains('balai') ||
        lower.contains('desa') ||
        lower.contains('kantor')) return Icons.account_balance;
    if (lower.contains('rs') ||
        lower.contains('rumah sakit') ||
        lower.contains('puskesmas')) return Icons.local_hospital;
    return Icons.home_work_rounded;
  }

  @override
  void initState() {
    super.initState();
    _entryController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 350 + widget.index * 60),
    );
    _fadeAnim = CurvedAnimation(
      parent: _entryController,
      curve: Curves.easeOut,
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.12),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _entryController, curve: Curves.easeOut));
    Future.delayed(Duration(milliseconds: widget.index * 80), () {
      if (mounted) _entryController.forward();
    });
  }

  @override
  void dispose() {
    _entryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final shelter = widget.shelter;
    Color statusColor = shelter.statusLabel == 'Penuh'
        ? AppTheme.statusBahaya
        : shelter.statusLabel == 'Hampir Penuh'
            ? AppTheme.statusWaspada
            : AppTheme.statusAman;

    return FadeTransition(
      opacity: _fadeAnim,
      child: SlideTransition(
        position: _slideAnim,
        child: GestureDetector(
          onTapDown: (_) => setState(() => _pressed = true),
          onTapUp: (_) {
            setState(() => _pressed = false);
            widget.onTap();
          },
          onTapCancel: () => setState(() => _pressed = false),
          child: AnimatedScale(
            scale: _pressed ? 0.97 : 1.0,
            duration: const Duration(milliseconds: 120),
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppTheme.border),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 12,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                    child: Row(
                      children: [
                        // ── BUKAN LAGI HANYA ICON, SEKARANG BISA BACA GAMBAR ──
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withOpacity(0.09),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: (shelter.imageUrl != null &&
                                  shelter.imageUrl!.isNotEmpty &&
                                  shelter.imageUrl != 'null')
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(14),
                                  child: shelter.imageUrl!.startsWith('http')
                                      ? CachedNetworkImage(
                                          imageUrl: shelter.imageUrl!,
                                          fit: BoxFit.cover,
                                          errorWidget: (context, url, error) {
                                            return Center(
                                              child: Icon(
                                                _getShelterIcon(shelter.name),
                                                size: 26,
                                                color: AppTheme.primary,
                                              ),
                                            );
                                          },
                                        )
                                      : Image.file(
                                          File(shelter.imageUrl!),
                                          fit: BoxFit.cover,
                                          errorBuilder: (ctx, err, stack) =>
                                              Center(
                                                  child: Icon(
                                                      _getShelterIcon(
                                                          shelter.name),
                                                      size: 26,
                                                      color: AppTheme.primary)),
                                        ),
                                )
                              : Center(
                                  child: Icon(
                                    _getShelterIcon(shelter.name),
                                    color: AppTheme.primary,
                                    size: 26,
                                  ),
                                ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                shelter.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Row(
                                children: [
                                  _MetaChip(
                                    icon: Icons.location_on_outlined,
                                    label: shelter.type,
                                  ),
                                  const SizedBox(width: 6),
                                  _MetaChip(
                                    icon: Icons.people_outline,
                                    label:
                                        '${shelter.currentOccupancy}/${shelter.capacity}',
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        _StatusBadge(status: shelter.statusLabel),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Tingkat hunian',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppTheme.textSecondary.withOpacity(0.7),
                              ),
                            ),
                            Text(
                              '${(shelter.occupancyPercent * 100).toStringAsFixed(0)}%',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: statusColor,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 5),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: shelter.occupancyPercent,
                            backgroundColor: AppTheme.borderLight,
                            color: statusColor,
                            minHeight: 7,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
                    child: Row(
                      children: [
                        Icon(
                          Icons.location_city_outlined,
                          size: 12,
                          color: AppTheme.textSecondary.withOpacity(0.6),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            shelter.address,
                            style: TextStyle(
                              fontSize: 11,
                              color: AppTheme.textSecondary.withOpacity(0.7),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          'Lihat detail →',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.primary.withOpacity(0.8),
                          ),
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
}

/* ────────────────────────────────────────
   META CHIP
──────────────────────────────────────── */

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _MetaChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: AppTheme.textSecondary),
          const SizedBox(width: 3),
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }
}

/* ────────────────────────────────────────
   STATUS BADGE
──────────────────────────────────────── */

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color = status == 'Penuh'
        ? AppTheme.statusBahaya
        : status == 'Hampir Penuh'
            ? AppTheme.statusWaspada
            : AppTheme.statusAman;

    IconData icon = status == 'Penuh'
        ? Icons.block_outlined
        : status == 'Hampir Penuh'
            ? Icons.warning_amber_outlined
            : Icons.check_circle_outline;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 4),
          Text(
            status,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

/* ────────────────────────────────────────
   SHELTER DETAIL BOTTOM SHEET
──────────────────────────────────────── */

/* ────────────────────────────────────────
   SHELTER DETAIL BOTTOM SHEET
──────────────────────────────────────── */

/* ────────────────────────────────────────
   SHELTER DETAIL BOTTOM SHEET (DENGAN PETA)
──────────────────────────────────────── */

class _ShelterDetailSheet extends StatelessWidget {
  final Shelter shelter;
  final VoidCallback onCall;
  final VoidCallback onMaps;

  const _ShelterDetailSheet({
    required this.shelter,
    required this.onCall,
    required this.onMaps,
  });

  Widget _buildPlaceholder() {
    return const Center(
      child: Icon(
        Icons.home_work_rounded,
        color: AppTheme.primary,
        size: 28,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Color statusColor = shelter.statusLabel == 'Penuh'
        ? AppTheme.statusBahaya
        : shelter.statusLabel == 'Hampir Penuh'
            ? AppTheme.statusWaspada
            : AppTheme.statusAman;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppTheme.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 54,
                      height: 54,
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withOpacity(0.09),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: (shelter.imageUrl != null &&
                              shelter.imageUrl!.isNotEmpty &&
                              shelter.imageUrl != 'null')
                          ? GestureDetector(
                              onTap: () {
                                if (shelter.imageUrl != null &&
                                    shelter.imageUrl!.isNotEmpty) {
                                  // Kita panggil fungsi global showGlobalImagePopup
                                  showGlobalImagePopup(
                                      context, shelter.imageUrl!, shelter.name);
                                }
                              },
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: (shelter.imageUrl != null &&
                                        shelter.imageUrl!.isNotEmpty)
                                    ? (shelter.imageUrl!.startsWith('http')
                                        ? CachedNetworkImage(
                                            imageUrl: shelter.imageUrl!,
                                            fit: BoxFit.cover,
                                            errorWidget:
                                                (context, url, error) =>
                                                    _buildPlaceholder(),
                                          )
                                        : Image.file(
                                            File(shelter.imageUrl!),
                                            fit: BoxFit.cover,
                                            errorBuilder: (ctx, err, stack) =>
                                                _buildPlaceholder(),
                                          ))
                                    : _buildPlaceholder(),
                              ),
                            )
                          : const Center(
                              child: Icon(
                                Icons.home_work_rounded,
                                color: AppTheme.primary,
                                size: 28,
                              ),
                            ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            shelter.name,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            shelter.address,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppTheme.textSecondary,
                            ),
                            maxLines: 2,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const Divider(height: 1),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _InfoTile(
                      icon: Icons.near_me_outlined,
                      label: 'Jarak',
                      value: '${shelter.distance.toStringAsFixed(1)} km',
                    ),
                    const SizedBox(width: 10),
                    _InfoTile(
                      icon: Icons.people_outline,
                      label: 'Kapasitas',
                      value: '${shelter.currentOccupancy}/${shelter.capacity}',
                    ),
                    const SizedBox(width: 10),
                    _InfoTile(
                      icon: Icons.show_chart,
                      label: 'Status',
                      value: shelter.statusLabel,
                      valueColor: statusColor,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: shelter.occupancyPercent,
                    backgroundColor: AppTheme.borderLight,
                    color: statusColor,
                    minHeight: 10,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${(shelter.occupancyPercent * 100).toStringAsFixed(0)}% kapasitas terisi',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppTheme.textSecondary,
                  ),
                ),

                // ─── KOTAK PETA MINI DITAMBAHKAN DI SINI ───
                const SizedBox(height: 20),
                Container(
                  height: 160,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(
                        15), // Sedikit lebih kecil dari border luar
                    child: FlutterMap(
                      options: MapOptions(
                        initialCenter: LatLng(shelter.lat, shelter.lng),
                        initialZoom:
                            14.5, // Ubah sedikit dari 15.0 ke 14.5 untuk memicu refresh
                        interactionOptions: const InteractionOptions(
                          // Matikan rotasi agar pengguna tidak pusing saat scroll
                          flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                        ),
                      ),
                      children: [
                        TileLayer(
                          urlTemplate:
                              'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          // Masukkan ID yang baru kamu temukan tadi di sini
                          userAgentPackageName: 'com.group.blastsafe',
                        ),
                        MarkerLayer(
                          markers: [
                            Marker(
                              point: LatLng(shelter.lat, shelter.lng),
                              width: 40,
                              height: 40,
                              child: const Icon(
                                Icons.location_on,
                                color: AppTheme.primary,
                                size: 36,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                // ──────────────────────────────────────────

                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onCall,
                        icon: const Icon(Icons.phone_outlined, size: 16),
                        label: const Text('Hubungi'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.primary,
                          side: const BorderSide(color: AppTheme.primary),
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: onMaps,
                        icon: const Icon(Icons.directions_outlined, size: 16),
                        label: const Text('Navigasi'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/* ────────────────────────────────────────
   INFO TILE (detail sheet)
──────────────────────────────────────── */

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 15, color: AppTheme.primary),
            const SizedBox(height: 5),
            Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: valueColor ?? AppTheme.textPrimary,
              ),
            ),
            Text(
              label,
              style: const TextStyle(
                fontSize: 10,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// TARUH DI LUAR CLASS (GLOBAL)
void showGlobalImagePopup(BuildContext context, String imageUrl, String name) {
  showDialog(
    context: context,
    builder: (context) => Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(10),
      child: Stack(
        alignment: Alignment.center,
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: InteractiveViewer(
              // Agar bisa di-zoom
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: imageUrl.startsWith('http')
                    ? CachedNetworkImage(
                        imageUrl: imageUrl,
                        fit: BoxFit.contain,
                      )
                    : Image.file(File(imageUrl), fit: BoxFit.contain),
              ),
            ),
          ),
          Positioned(
            top: 10,
            right: 10,
            child: CircleAvatar(
              backgroundColor: Colors.black54,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
