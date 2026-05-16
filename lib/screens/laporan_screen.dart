// lib/screens/laporan_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import '../data/app_provider.dart';
import '../models/app_models.dart';
import '../theme.dart';
import 'shelter_screen.dart' show AppScreenHeader, AppHeaderStat;
import 'package:url_launcher/url_launcher.dart';
import '../widgets/video_player_widget.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';

class LaporanScreen extends StatefulWidget {
  const LaporanScreen({super.key});

  @override
  State<LaporanScreen> createState() => _LaporanScreenState();
}

class _LaporanScreenState extends State<LaporanScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _descCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _latCtrl = TextEditingController();
  final _lngCtrl = TextEditingController();

  File? _selectedImage;
  final _picker = ImagePicker();

  bool _isSubmitting = false;
  bool _submitted = false; // Tambahkan ini
  double _uploadProgress = 0; // Tambahkan ini

  @override
  void dispose() {
    _descCtrl.dispose();
    _locationCtrl.dispose();
    _nameCtrl.dispose();
    _latCtrl.dispose();
    _lngCtrl.dispose();
    super.dispose();
  }

  // Fungsi untuk mengambil gambar
  Future<void> _pickMedia(bool isVideo) async {
    final XFile? media = isVideo
        ? await _picker.pickVideo(
            source: ImageSource.gallery,
            maxDuration: const Duration(seconds: 15), // Batas durasi 15 detik
          )
        : await _picker.pickImage(
            source: ImageSource.gallery,
            imageQuality: 50, // Kompres foto agar hemat storage
          );

    if (media != null) {
      // 1. Cek ukuran file (Maksimal 40MB untuk menjaga limit 50MB Supabase)
      final bytes = await media.length();
      final megaBytes = bytes / (1024 * 1024);

      if (megaBytes > 40) {
        if (mounted) {
          _showSnack(
              context,
              'File terlalu besar (Max 40MB). Silakan pilih video lain.',
              Colors.red);
        }
        return; // Berhenti jika file terlalu besar
      }

      // 2. Jika lolos pengecekan, baru simpan ke state
      setState(() {
        _selectedImage = File(media.path);
      });
    }
  }

  void _showSnack(BuildContext ctx, String msg, Color color) {
    ScaffoldMessenger.of(ctx).showSnackBar(
      SnackBar(
        content: Text(
          msg,
          style:
              const TextStyle(fontWeight: FontWeight.w600, color: Colors.white),
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  // Fungsi untuk mengambil titik koordinat GPS pengguna
  Future<void> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content:
                Text('Layanan lokasi tidak aktif. Silakan aktifkan GPS Anda.')),
      );
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return;
    }

    Position position = await Geolocator.getCurrentPosition();
    setState(() {
      _latCtrl.text = position.latitude.toStringAsFixed(6);
      _lngCtrl.text = position.longitude.toStringAsFixed(6);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        final total = provider.reports.length;
        final verified = provider.reports.where((r) => r.isVerified).length;
        final pending = total - verified;

        return Scaffold(
          backgroundColor: AppTheme.surface,
          body: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: AppScreenHeader(
                  emoji: '📋',
                  title: 'Laporan Warga',
                  subtitle: 'Laporkan kondisi lapangan di sekitarmu',
                  stats: [
                    AppHeaderStat(
                      icon: Icons.article_outlined,
                      label: 'Total Laporan',
                      value: '$total',
                    ),
                    AppHeaderStat(
                      icon: Icons.verified_outlined,
                      label: 'Terverifikasi',
                      value: '$verified',
                      valueColor: const Color(0xFF6EE7B7),
                    ),
                    AppHeaderStat(
                      icon: Icons.hourglass_top_outlined,
                      label: 'Menunggu',
                      value: '$pending',
                      valueColor: const Color(0xFFFCD34D),
                    ),
                  ],
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 400),
                    transitionBuilder: (child, anim) => FadeTransition(
                      opacity: anim,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0, 0.08),
                          end: Offset.zero,
                        ).animate(anim),
                        child: child,
                      ),
                    ),
                    child: _submitted
                        ? _SuccessBanner(
                            key: const ValueKey('success'),
                            onReset: () {
                              setState(() {
                                _submitted = false;
                                _uploadProgress = 0; // Agar bar balik ke 0
                                _selectedImage = null; // Hapus media lama
                              });
                            },
                          )
                        : _FormCard(
                            key: const ValueKey('form'),
                            formKey: _formKey,
                            descCtrl: _descCtrl,
                            locationCtrl: _locationCtrl,
                            nameCtrl: _nameCtrl,
                            latCtrl: _latCtrl,
                            lngCtrl: _lngCtrl,
                            selectedImage: _selectedImage,
                            // Pastikan fungsi-fungsi di bawah ini namanya sama di file kamu
                            onPickImage: () => _pickMedia(false),
                            onGetLocation: _getCurrentLocation,
                            isSubmitting: _isSubmitting,
                            onSubmit: () => _submit(context),
                          ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
                  child: _buildReportsHeader(provider),
                ),
              ),
              provider.isLoading && provider.reports.isEmpty
                  ? const SliverToBoxAdapter(
                      child: SizedBox(
                        height: 400,
                        child: LaporanShimmer(),
                      ),
                    )
                  : provider.reports.isEmpty
                      ? SliverToBoxAdapter(child: _buildEmptyState())
                      : SliverPadding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                          sliver: SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (ctx, i) => GestureDetector(
                                onTap: () => _showReportDetail(
                                  context,
                                  provider.reports[i],
                                ),
                                child: _AnimatedReportCard(
                                  report: provider.reports[i],
                                  index: i,
                                ),
                              ),
                              childCount: provider.reports.length,
                            ),
                          ),
                        ),
            ],
          ),
        );
      },
    );
  }

  // Pop up

  void _showReportDetail(BuildContext context, WargaReport report) {
    // Fungsi untuk membuka Google Maps
    void openMap(String locationText) async {
      // Mencoba mendeteksi apakah ada koordinat di dalam teks lokasi
      final regExp =
          RegExp(r'(?:Lat|Lac):\s*(-?\d+\.\d+),\s*Lng:\s*(-?\d+\.\d+)');
      final match = regExp.firstMatch(locationText);

      Uri mapUri;

      if (match != null) {
        final lat = match.group(1);
        final lng = match.group(2);
        // Membuka koordinat langsung di Google Maps
        mapUri = Uri.parse(
            'https://www.google.com/maps/search/?api=1&query=$lat,$lng');
      } else {
        // Jika tidak ada format koordinat, cari menggunakan teks lokasi
        mapUri = Uri.parse(
            'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(locationText)}');
      }

      try {
        // Pastikan package url_launcher sudah ditambahkan di pubspec.yaml
        // dan jalankan perintah flutter pub get
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
                          color: AppTheme.primary.withOpacity(0.1),
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
                              color: AppTheme.primary,
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
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            Text(
                              'Pelapor',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppTheme.textSecondary.withOpacity(0.6),
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

                  // 2. Penjelasan Kejadian
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

                  // 3. Dokumentasi
                  const Text(
                    'Dokumentasi',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: AppTheme.surface,
                        border: Border.all(color: AppTheme.border),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: (report.imagePath != null &&
                              report.imagePath!.isNotEmpty &&
                              report.imagePath != 'null')
                          ? Builder(
                              builder: (context) {
                                // Cek apakah file adalah video berdasarkan ekstensi URL
                                final url = report.imagePath!.toLowerCase();
                                final isVideo = url.endsWith('.mp4') ||
                                    url.endsWith('.mov') ||
                                    url.endsWith('.avi');

                                if (isVideo) {
                                  // Tampilkan Video Player jika format video
                                  return AppVideoPlayer(url: report.imagePath);
                                } else {
                                  // Tampilkan Image jika format gambar
                                  return CachedNetworkImage(
                                    imageUrl: report.imagePath!,
                                    fit: BoxFit.contain,
                                    errorWidget: (context, url, error) {
                                      return const Center(
                                        child: Icon(
                                          Icons.broken_image,
                                          size: 36,
                                          color: AppTheme.textSecondary,
                                        ),
                                      );
                                    },
                                  );
                                }
                              },
                            )
                          : const Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.image_outlined,
                                    size: 36,
                                    color: AppTheme.textSecondary,
                                  ),
                                  SizedBox(height: 6),
                                  Text(
                                    'Tidak ada dokumentasi dilampirkan',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: AppTheme.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Tombol Tutup
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Tutup',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  if (_isSubmitting)
                    Container(
                      color: Colors.black.withOpacity(0.6),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircularProgressIndicator(
                              value: _uploadProgress,
                              strokeWidth: 6,
                              color: Colors.white,
                              backgroundColor: Colors.white24,
                            ),
                            const SizedBox(height: 20),
                            Text(
                              "Mengirim Laporan: ${(_uploadProgress * 100).toInt()}%",
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold),
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
      },
    );
  }

  Widget _buildReportsHeader(AppProvider provider) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 20,
          decoration: BoxDecoration(
            color: AppTheme.primary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 10),
        const Text(
          'Laporan Masuk',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: AppTheme.textPrimary,
          ),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: AppTheme.primary.withOpacity(0.09),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppTheme.primary.withOpacity(0.18)),
          ),
          child: Text(
            '${provider.reports.length} laporan',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppTheme.primary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppTheme.primary.withOpacity(0.07),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.inbox_outlined,
              size: 36,
              color: AppTheme.primary,
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'Belum ada laporan',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 5),
          const Text(
            'Jadilah yang pertama melapor!',
            style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }

  void _submit(BuildContext context) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
      _uploadProgress = 0.3;
    });

    try {
      String? uploadedUrl;

      if (_selectedImage != null) {
        final path = _selectedImage!.path.toLowerCase();
        final extension = path.split('.').last;
        final isVideo = ['mp4', 'mov', 'avi', 'mkv'].contains(extension);
        final bucketName = isVideo ? 'laporan_videos' : 'laporan_images';

        // Gunakan nama file yang sangat spesifik
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final fileName = 'vid_$timestamp.$extension';

        await Supabase.instance.client.storage.from(bucketName).upload(
              fileName,
              _selectedImage!,
            );

        // Ambil URL publik setelah berhasil upload
        uploadedUrl = Supabase.instance.client.storage
            .from(bucketName)
            .getPublicUrl(fileName);
      }

      // ... (Langkah 5 & 6 tetap sama) ...
      String locationText = _locationCtrl.text.trim();
      if (_latCtrl.text.isNotEmpty && _lngCtrl.text.isNotEmpty) {
        locationText += ' (Lat: ${_latCtrl.text}, Lng: ${_lngCtrl.text})';
      }

      final newReport = WargaReport(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        description: _descCtrl.text.trim(),
        location: locationText,
        time: DateTime.now(),
        reporterName:
            _nameCtrl.text.trim().isEmpty ? 'Anonim' : _nameCtrl.text.trim(),
        imagePath: uploadedUrl,
        isVerified: false,
      );

      await context.read<AppProvider>().addReport(newReport);

      // ── Reset Form & State ──
      _descCtrl.clear();
      _locationCtrl.clear();
      _nameCtrl.clear();
      _latCtrl.clear();
      _lngCtrl.clear();

      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _uploadProgress = 1.0; //
          _submitted = true;
          _selectedImage = null;
        });
      }
    } catch (e) {
      debugPrint("Error Submit Laporan: $e");
      if (mounted) {
        setState(() => _isSubmitting = false);
        // Tambahkan pesan error khusus ukuran file jika terkena limit 413
        String msg = e.toString().contains('413')
            ? 'Ukuran file terlalu besar! Maksimal 40MB.'
            : 'Gagal mengirim laporan: $e';

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), backgroundColor: Colors.red),
        );
      }
    }
  }
}

class _FormCard extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController descCtrl;
  final TextEditingController locationCtrl;
  final TextEditingController nameCtrl;
  final TextEditingController latCtrl;
  final TextEditingController lngCtrl;
  final File? selectedImage;
  final VoidCallback onPickImage;
  final VoidCallback onGetLocation;
  final bool isSubmitting;
  final VoidCallback onSubmit;

  const _FormCard({
    super.key,
    required this.formKey,
    required this.descCtrl,
    required this.locationCtrl,
    required this.nameCtrl,
    required this.latCtrl,
    required this.lngCtrl,
    required this.selectedImage,
    required this.onPickImage,
    required this.onGetLocation,
    required this.isSubmitting,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.04),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(20)),
                border: Border(bottom: BorderSide(color: AppTheme.border)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.edit_note_rounded,
                      color: AppTheme.primary,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Kirim Laporan Kondisi',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Bantu warga lain dengan melaporkan kondisi lapangan',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                children: [
                  _StyledField(
                    controller: nameCtrl,
                    icon: Icons.person_outline,
                    label: 'Nama Anda',
                    hint: 'Pak Budi / Anonim (opsional)',
                    required: false,
                  ),
                  const SizedBox(height: 12),
                  _StyledField(
                    controller: locationCtrl,
                    icon: Icons.location_on_outlined,
                    label: 'Lokasi Kejadian',
                    hint: 'Contoh: Jl. Raya Panengahan KM 3',
                    required: true,
                    validator: (v) => v == null || v.trim().isEmpty
                        ? 'Lokasi wajib diisi'
                        : null,
                  ),
                  const SizedBox(height: 12),

                  // Koordinat Form
                  Row(
                    children: [
                      Expanded(
                        child: _StyledField(
                          controller: latCtrl,
                          icon: Icons.pin_drop_outlined,
                          label: 'Latitude (opsional)',
                          hint: '-5.4510',
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _StyledField(
                          controller: lngCtrl,
                          icon: Icons.pin_drop_outlined,
                          label: 'Longitude (opsional)',
                          hint: '105.2680',
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: onGetLocation,
                      icon: const Icon(Icons.my_location, size: 16),
                      label: const Text('Ambil Lokasi Saat Ini',
                          style: TextStyle(fontSize: 12)),
                      style: TextButton.styleFrom(
                        foregroundColor: AppTheme.primary,
                        padding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),

                  //Dokumentasi
                  Align(
                    alignment: Alignment.centerLeft,
                    child: const Text(
                      'Dokumentasi Kondisi',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  InkWell(
                    onTap: () {
                      // Memunculkan pilihan bawah agar user bisa pilih jenis media
                      showModalBottomSheet(
                        context: context,
                        backgroundColor: Colors.white,
                        shape: const RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.vertical(top: Radius.circular(20)),
                        ),
                        builder: (ctx) => SafeArea(
                          child: Wrap(
                            children: [
                              ListTile(
                                leading: const Icon(Icons.camera_alt,
                                    color: AppTheme.primary),
                                title: const Text('Ambil / Pilih Foto'),
                                onTap: () {
                                  Navigator.pop(ctx);
                                  onPickImage(); // Ini memanggil _pickMedia(false)
                                },
                              ),
                              ListTile(
                                leading: const Icon(Icons.videocam,
                                    color: AppTheme.primary),
                                title: const Text('Ambil / Pilih Video'),
                                onTap: () {
                                  Navigator.pop(ctx);
                                  // Kita buat callback baru untuk video
                                  // Karena kita di _FormCard, pastikan fungsi ini sudah dioper dari parent
                                  // Atau panggil langsung jika kamu menaruh logika di sini
                                  (context.findAncestorStateOfType<
                                          _LaporanScreenState>())
                                      ?._pickMedia(true);
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: AppTheme.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.border),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            selectedImage != null
                                ? Icons.check_circle
                                : Icons.perm_media_outlined,
                            color: selectedImage != null
                                ? AppTheme.statusAman
                                : AppTheme.primary,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            selectedImage != null
                                ? 'Media berhasil dipilih'
                                : 'Pilih Foto atau Video (Opsional)',
                            style: TextStyle(
                              fontSize: 12,
                              color: selectedImage != null
                                  ? AppTheme.statusAman
                                  : AppTheme.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Di dalam class _FormCard, di bawah InkWell dokumentasi
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.info_outline,
                          size: 14, color: AppTheme.textSecondary),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Maksimal durasi video 15 detik atau ukuran file 40MB.',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppTheme.textSecondary.withOpacity(0.8),
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    ],
                  ),

                  // Letakkan tepat di bawah penutup InkWell
                  if (selectedImage != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Builder(
                          builder: (context) {
                            final path = selectedImage!.path.toLowerCase();
                            final isVideo =
                                path.endsWith('.mp4') || path.endsWith('.mov');

                            return Container(
                              height: 180,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: AppTheme.surface,
                                border: Border.all(color: AppTheme.border),
                              ),
                              child: isVideo
                                  ? AppVideoPlayer(
                                      file:
                                          selectedImage) // Pratinjau Video Lokal
                                  : Image.file(selectedImage!,
                                      fit:
                                          BoxFit.cover), // Pratinjau Foto Lokal
                            );
                          },
                        ),
                      ),
                    ),
                  const SizedBox(height: 12),

                  _StyledField(
                    controller: descCtrl,
                    icon: Icons.description_outlined,
                    label: 'Deskripsi Kondisi',
                    hint:
                        'Contoh: Jalan terendam ±50 cm, kendaraan tidak bisa lewat',
                    required: true,
                    maxLines: 3,
                    alignLabelWithHint: true,
                    validator: (v) => v == null || v.trim().isEmpty
                        ? 'Deskripsi wajib diisi'
                        : null,
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: isSubmitting ? null : onSubmit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor:
                            AppTheme.primary.withOpacity(0.6),
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        child: isSubmitting
                            ? const Row(
                                key: ValueKey('loading'),
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  ),
                                  SizedBox(width: 10),
                                  Text(
                                    'Mengirim...',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              )
                            : const Row(
                                key: ValueKey('idle'),
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.send_rounded, size: 16),
                                  SizedBox(width: 8),
                                  Text(
                                    'Kirim Laporan',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                      ),
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

class _StyledField extends StatelessWidget {
  final TextEditingController controller;
  final IconData icon;
  final String label;
  final String hint;
  final bool required;
  final int maxLines;
  final bool alignLabelWithHint;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;

  const _StyledField({
    required this.controller,
    required this.icon,
    required this.label,
    required this.hint,
    this.required = false,
    this.maxLines = 1,
    this.alignLabelWithHint = false,
    this.keyboardType = TextInputType.text,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppTheme.textSecondary,
              ),
            ),
            if (required) ...[
              const SizedBox(width: 4),
              const Text(
                '*',
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.statusBahaya,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 5),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          validator: validator,
          keyboardType: keyboardType,
          style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              fontSize: 12,
              color: AppTheme.textSecondary.withOpacity(0.6),
            ),
            prefixIcon: Icon(icon, size: 18, color: AppTheme.primary),
            alignLabelWithHint: alignLabelWithHint,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            filled: true,
            fillColor: AppTheme.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppTheme.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppTheme.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppTheme.primary, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppTheme.statusBahaya),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  const BorderSide(color: AppTheme.statusBahaya, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}

class _SuccessBanner extends StatelessWidget {
  final VoidCallback onReset;
  const _SuccessBanner({super.key, required this.onReset});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.statusAman.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: AppTheme.statusAman.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppTheme.statusAman.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.check_circle_outline_rounded,
              size: 40,
              color: AppTheme.statusAman,
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'Laporan Berhasil Dikirim!',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Terima kasih. Laporan Anda akan ditinjau admin dan membantu warga lain.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: AppTheme.textSecondary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onReset,
              icon: const Icon(Icons.add_circle_outline, size: 16),
              label: const Text('Kirim Laporan Lain'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.primary,
                side: const BorderSide(color: AppTheme.primary),
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                textStyle: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AnimatedReportCard extends StatefulWidget {
  final WargaReport report;
  final int index;

  const _AnimatedReportCard({required this.report, required this.index});

  @override
  State<_AnimatedReportCard> createState() => _AnimatedReportCardState();
}

class _AnimatedReportCardState extends State<_AnimatedReportCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fade;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 350 + widget.index * 60),
    );
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    Future.delayed(Duration(milliseconds: widget.index * 70), () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: _ReportCardContent(report: widget.report),
      ),
    );
  }
}

class _ReportCardContent extends StatelessWidget {
  final WargaReport report;
  const _ReportCardContent({required this.report});

  String _timeAgo(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 60) return '${diff.inMinutes} mnt lalu';
    if (diff.inHours < 24) return '${diff.inHours} jam lalu';
    return '${diff.inDays} hari lalu';
  }

  @override
  Widget build(BuildContext context) {
    final isVerified = report.isVerified;
    final statusColor =
        isVerified ? AppTheme.statusAman : AppTheme.statusWaspada;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.04),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(18)),
              border: Border(bottom: BorderSide(color: AppTheme.border)),
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withOpacity(0.1),
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
                        color: AppTheme.primary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        report.reporterName,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      Text(
                        _timeAgo(report.time),
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: statusColor.withOpacity(0.25)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isVerified
                            ? Icons.verified_outlined
                            : Icons.hourglass_top_outlined,
                        size: 11,
                        color: statusColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isVerified ? 'Terverifikasi' : 'Menunggu',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: statusColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  report.description,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    height: 1.5,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.location_on_outlined,
                        size: 13,
                        color: AppTheme.primary,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          report.location,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.textSecondary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // ── TAMBAHAN PREVIEW GAMBAR / VIDEOS MAMA GUFRON──
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    height: 160,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      border: Border.all(color: AppTheme.border),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: report.imagePath != null &&
                            report.imagePath!.isNotEmpty &&
                            report.imagePath != 'null'
                        ? Builder(
                            builder: (context) {
                              final url = report.imagePath!.toLowerCase();
                              // Cek apakah file adalah video
                              final isVideo = url.endsWith('.mp4') ||
                                  url.endsWith('.mov') ||
                                  url.endsWith('.avi');

                              if (isVideo) {
                                // Tampilkan Icon Video atau Thumbnail sederhana agar list tidak berat
                                return VideoThumbnailWidget(
                                    key: ValueKey(report.imagePath),
                                    url: report.imagePath!);
                              } else {
                                // Jika gambar, tampilkan seperti biasa
                                return CachedNetworkImage(
                                  imageUrl: report.imagePath!,
                                  fit: BoxFit.contain,
                                  errorWidget: (context, url, error) =>
                                      const Icon(Icons.broken_image),
                                );
                              }
                            },
                          )
                        : const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.image_outlined,
                                    size: 28, color: AppTheme.textSecondary),
                                SizedBox(height: 4),
                                Text(
                                  'Tidak ada dokumentasi',
                                  style: TextStyle(
                                      fontSize: 10,
                                      color: AppTheme.textSecondary),
                                ),
                              ],
                            ),
                          ),
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

class LaporanShimmer extends StatelessWidget {
  const LaporanShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: 6,
      padding: const EdgeInsets.all(16),
      itemBuilder: (_, __) {
        return Shimmer.fromColors(
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Container(width: 40, height: 40, color: Colors.grey),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(height: 10, color: Colors.grey),
                      const SizedBox(height: 8),
                      Container(height: 10, width: 180, color: Colors.grey),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
