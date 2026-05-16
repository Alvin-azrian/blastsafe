// lib/screens/kontak_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/app_provider.dart';
import '../models/app_models.dart';
import '../theme.dart';
import 'shelter_screen.dart' show AppScreenHeader;
import 'package:url_launcher/url_launcher.dart';

class KontakScreen extends StatelessWidget {
  const KontakScreen({super.key});

  // ignore: unused_element
  Future<void> _makePhoneCall(String phoneNumber) async {
    // Membersihkan nomor telepon dari karakter non-digit (seperti spasi atau tanda kurung)
    final String cleanNumber = phoneNumber.replaceAll(RegExp(r'[^0-9+]'), '');
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: cleanNumber,
    );

    if (await canopyLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    } else {
      // Tambahkan pesan error jika dialer tidak bisa dibuka
      debugPrint('Tidak bisa membuka dialer telepon untuk nomor: $phoneNumber');
    }
  }

// Fungsi pembantu untuk mengecek apakah URL bisa dibuka
  Future<bool> canopyLaunchUrl(Uri uri) async {
    return await canLaunchUrl(uri);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        return Scaffold(
          backgroundColor: AppTheme.surface,
          body: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // ── CONSISTENT HEADER ──────────────────
              SliverToBoxAdapter(
                child: AppScreenHeader(
                  emoji: '🚨',
                  title: 'Kontak Darurat',
                  subtitle: 'Hubungi bantuan dengan cepat & tepat',
                ),
              ),
              SliverToBoxAdapter(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 800),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final double contentWidth = constraints.maxWidth;
                          final bool isWideScreen = contentWidth > 600;
                          final double cardWidth = isWideScreen
                              ? (contentWidth / 2) - 8
                              : contentWidth;

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildHeroBanner(),
                              const SizedBox(height: 24),
                              const Text(
                                'Nomor Darurat',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Wrap(
                                spacing: 16,
                                runSpacing: 12,
                                children: provider.emergencyContacts
                                    .map((contact) => SizedBox(
                                          width: cardWidth,
                                          child: _ContactCard(contact: contact),
                                        ))
                                    .toList(),
                              ),
                              const SizedBox(height: 24),
                              const Text(
                                'Prosedur Saat Menghubungi',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Wrap(
                                spacing: 16,
                                runSpacing: 12,
                                children: [
                                  SizedBox(
                                    width: cardWidth,
                                    child: const _ProcedureCard(
                                      step: '1',
                                      icon: '📍',
                                      title: 'Sebutkan Lokasi',
                                      desc:
                                          'Nama desa/jalan, RT/RW, patokan terdekat',
                                    ),
                                  ),
                                  SizedBox(
                                    width: cardWidth,
                                    child: const _ProcedureCard(
                                      step: '2',
                                      icon: '👥',
                                      title: 'Jumlah Orang',
                                      desc:
                                          'Berapa orang yang membutuhkan bantuan',
                                    ),
                                  ),
                                  SizedBox(
                                    width: cardWidth,
                                    child: const _ProcedureCard(
                                      step: '3',
                                      icon: '🏥',
                                      title: 'Kondisi Darurat',
                                      desc:
                                          'Ada orang sakit/terluka? Lansia? Bayi?',
                                    ),
                                  ),
                                  SizedBox(
                                    width: cardWidth,
                                    child: const _ProcedureCard(
                                      step: '4',
                                      icon: '📱',
                                      title: 'Tetap di Jalur',
                                      desc:
                                          'Jangan tutup telepon sebelum petugas minta. Ikuti instruksi mereka.',
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              _buildInfoContainer(),
                              const SizedBox(height: 24),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeroBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFC62828), Color(0xFFEF5350)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFC62828).withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          const Text('🚨', style: TextStyle(fontSize: 32)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Butuh Bantuan Segera?',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Hubungi salah satu nomor darurat di bawah ini. Berikan info lokasi Anda dengan jelas.',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.85),
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoContainer() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.info.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.info.withOpacity(0.2)),
      ),
      child: const Row(
        children: [
          Text('💡', style: TextStyle(fontSize: 20)),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Simpan screenshot nomor darurat ini atau catat di buku kecil. Pastikan HP selalu terisi minimal 50% saat banjir mengancam.',
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.textSecondary,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ContactCard extends StatelessWidget {
  final EmergencyContact contact;
  const _ContactCard({required this.contact});

  Color get _cardColor =>
      contact.phone.length <= 3 ? AppTheme.statusBahaya : AppTheme.primary;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => _showCallDialog(context, contact),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: _cardColor.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(contact.icon,
                        style: const TextStyle(fontSize: 22)),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        contact.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        contact.description,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton.icon(
                  onPressed: () => _showCallDialog(context, contact),
                  icon: const Icon(Icons.phone, color: Colors.white, size: 14),
                  label: const Text(
                    'Panggil',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _cardColor,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ProcedureCard extends StatelessWidget {
  final String step, icon, title, desc;

  const _ProcedureCard({
    required this.step,
    required this.icon,
    required this.title,
    required this.desc,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppTheme.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                step,
                style: const TextStyle(
                  color: AppTheme.primary,
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(icon, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  desc,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
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

void _showCallDialog(BuildContext context, EmergencyContact contact) {
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Column(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: AppTheme.statusBahaya.withOpacity(0.1),
            child: Icon(Icons.phone_in_talk,
                color: AppTheme.statusBahaya, size: 30),
          ),
          const SizedBox(height: 16),
          Text(
            contact.name,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            contact.phone,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.primary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            contact.description,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          style: TextButton.styleFrom(
            foregroundColor: AppTheme.textSecondary,
          ),
          child: const Text('Batal'),
        ),
        ElevatedButton.icon(
          onPressed: () async {
            Navigator.pop(ctx);

            // Logika pembersihan nomor langsung di sini
            final String cleanNumber =
                contact.phone.replaceAll(RegExp(r'[^0-9+]'), '');
            final Uri launchUri = Uri(scheme: 'tel', path: cleanNumber);

            if (await canLaunchUrl(launchUri)) {
              await launchUrl(launchUri);
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Tidak dapat membuka aplikasi telepon')),
              );
            }
          },
          icon: const Icon(Icons.phone, size: 16, color: Colors.white),
          label: const Text('Panggil', style: TextStyle(color: Colors.white)),
          // ... style lainnya ...
        ),
      ],
    ),
  );
}
