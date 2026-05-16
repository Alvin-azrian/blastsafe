// lib/data/app_provider.dart
// REDESIGN: Terhubung 100% ke Cloud Supabase (Sinkron antar HP)

// ignore_for_file: unused_import, unused_field

import 'package:flutter/material.dart';
import '../models/app_models.dart';
import '../services/database_service.dart';
import '../services/notification_service.dart';
import '../services/bmkg_service.dart';
import '../services/location_service.dart';
import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:supabase/supabase.dart';

final supabase = Supabase.instance.client;

class AppProvider extends ChangeNotifier {
  AppState _state = AppState();

  List<Shelter> _shelters = [];

  List<WargaReport> _reports = [];

  List<AdminNotification> _notifications = [];

  bool _warningDismissed = false;

  bool _isFetchingMore = false;

// report page
  int _reportPage = 0;

  final int _reportLimit = 10;

  bool _isLoadingMoreReports = false;

  bool _hasMoreReports = true;

// fetch report

  bool get isLoadingMoreReports => _isLoadingMoreReports;

  bool get hasMoreReports => _hasMoreReports;

  // 1. TAMBAHKAN LOADING STATE
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  // BMKG
  BmkgWeather? _bmkgWeather;
  bool _bmkgLoading = false;
  String? _bmkgError;

  // Services
  final _db = DatabaseService();
  final _notifSvc = NotificationService();
  final _bmkgSvc = BmkgService();

  // ── Getters ──────────────────────────────────────────────────────
  AppState get state => _state;
  List<Shelter> get shelters => List.unmodifiable(_shelters);
  List<WargaReport> get reports => List.unmodifiable(_reports);
  List<AdminNotification> get notifications =>
      List.unmodifiable(_notifications);
  bool get showWarningBanner =>
      !_warningDismissed && _state.status != FloodStatus.aman;

  BmkgWeather? get bmkgWeather => _bmkgWeather;
  bool get bmkgLoading => _bmkgLoading;
  String? get bmkgError => _bmkgError;

  int get unreadNotifCount => _notifications.where((n) => !n.isRead).length;

  // ── Init ─────────────────────────────────────────────────────────
  AppProvider() {
    _initData();
    listenToNotifications();
    listenToShelters();
  }

  // Tambahkan di dalam class AppProvider
  void listenToNotifications() {
    _db.supabase
        .channel('public:notifikasi')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'notifikasi',
          callback: (payload) {
            debugPrint('Ada notifikasi baru masuk!');

            // 1. Ambil data dari payload Supabase
            final newRecord = payload.newRecord;

            // 2. Buat objek AdminNotification dari data tersebut
            final newNotif = AdminNotification(
              id: newRecord['id'].toString(),
              title: newRecord['title'] ?? 'Peringatan Baru',
              message: newRecord['message'] ?? '',
              time: DateTime.parse(
                  newRecord['time'] ?? DateTime.now().toIso8601String()),
              priority: newRecord['priority'] ?? 'normal',
            );

            // 3. Muat ulang list notifikasi agar muncul di layar
            _loadNotificationsFromDb();

            // 4. Panggil fungsi yang benar dari notification_service.dart
            _notifSvc.showAdminNotification(newNotif);
          },
        )
        .subscribe();
  }

  // TAMBAHKAN FUNGSI INI DI BAWAH listenToNotifications()
  void listenToShelters() {
    _db.supabase
        .channel(
            'public:shelters_channel') // Nama channel bisa bebas, kita buat spesifik
        .onPostgresChanges(
          // Menggunakan .all agar aplikasi merespon penambahan (insert),
          // perubahan kapasitas (update), dan penghapusan (delete) shelter
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'shelter',
          callback: (payload) {
            debugPrint(
                'Data shelter berubah secara real-time! Memperbarui UI...');

            // Langsung panggil fungsi load untuk menyegarkan data dan menghitung ulang jarak
            _loadSheltersFromDb();
          },
        )
        .subscribe();
  }

  //INI BUAT LOGIN ADMIN YAH DERR
  // Di dalam class AppProvider
  Future<bool> checkAdminLogin(String username, String password) async {
    try {
      _isLoading = true;
      notifyListeners();

      final response = await supabase
          .from('admins')
          .select()
          .eq('username', username.trim())
          .eq('password', password)
          .maybeSingle();

      if (response != null) {
        // Simpan sesi ke memori HP agar tidak perlu login ulang tiap buka app
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('isLoggedIn', true);
        await prefs.setString('currentUser', username);

        _state = _state.copyWith(isLoggedIn: true, currentUser: username);
        await _loadNotificationsFromDb();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint("Login Error: $e");
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _initData() async {
    await _loadStatusFromDb();
    await _loadSheltersFromDb();
    await _loadReportsFromDb();
    await _loadNotificationsFromDb();
    await fetchBmkgWeather();
  }

  // Tambahkan parameter {BuildContext? context} di sini
  Future<void> refreshAllData({BuildContext? context}) async {
    try {
      _isLoading = true;
      notifyListeners();

      // 1. Coba ambil data terbaru dari Supabase (Online)
      await _loadStatusFromDb();
      await _loadSheltersFromDb();
      await _loadReportsFromDb();
      await _loadNotificationsFromDb();

      // 2. JIKA BERHASIL: Simpan salinan data terbaru ke memori HP
      await _saveToLocal();

      debugPrint("Sinkronisasi online berhasil: ${_shelters.length} shelter.");
    } catch (e) {
      debugPrint("Gagal online, mencoba memuat data offline: $e");

      // 3. JIKA GAGAL: Ambil data dari cadangan yang tersimpan di memori HP
      await _loadFromLocal();

      // Munculkan SnackBar dengan warna Oranye (sebagai penanda mode offline)
      if (context != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: const [
                Icon(Icons.cloud_off, color: Colors.white, size: 20),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Mode Offline: Menampilkan data terakhir yang tersimpan.',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
            backgroundColor:
                Colors.orange.shade800, // Warna oranye untuk peringatan offline
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.only(bottom: 20, left: 16, right: 16),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ── Status Banjir (Cloud Supabase) ───────────────────────────────
  /// Mengambil status banjir terakhir yang disimpan di database
  Future<void> _loadStatusFromDb() async {
    try {
      final data = await _db.getAppStatus();
      if (data != null) {
        // Mencari enum FloodStatus yang cocok dengan teks dari database
        final dbStatus = FloodStatus.values.firstWhere(
          (e) => e.name == data['status'],
          orElse: () => FloodStatus.aman,
        );

        _state.status = dbStatus;
        _state.warningMessage = data['message'] ?? '';
        _state.showWarning = dbStatus != FloodStatus.aman;
        _warningDismissed = false;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Gagal memuat status dari DB: $e');
    }
  }

  /// Memperbarui status banjir ke database (Hanya Admin)
  Future<void> updateStatus(FloodStatus newStatus, String message) async {
    try {
      // 1. Kirim ke Database Supabase agar permanen
      await _db.updateAppStatus(newStatus.name, message);

      // 2. Update tampilan lokal aplikasi
      _state.status = newStatus;
      _state.warningMessage = message;
      _state.showWarning = newStatus != FloodStatus.aman;
      _warningDismissed = false;
      notifyListeners();
    } catch (e) {
      debugPrint('Gagal update status ke DB: $e');
    }
  }

  // ── Shelter CRUD (Cloud Supabase) ────────────────────────────────

  Future<void> _loadSheltersFromDb() async {
    final rawShelters = await _db.getShelters();
    final pos = await LocationService.getCurrentPosition();

    if (pos != null) {
      for (var s in rawShelters) {
        s.distance = LocationService.distanceInKm(
          fromLat: pos.latitude,
          fromLng: pos.longitude,
          toLat: s.lat,
          toLng: s.lng,
        );
      }
    }
    _shelters = rawShelters;
    notifyListeners();
  }

  Future<void> updateShelterWithImage(Shelter shelter, File? imageFile) async {
    String? imageUrl = shelter.imageUrl;

    if (imageFile != null) {
      imageUrl = await _db.uploadShelterImage(imageFile);
    }

    final updated = Shelter(
      id: shelter.id,
      name: shelter.name,
      address: shelter.address,
      type: shelter.type,
      capacity: shelter.capacity,
      currentOccupancy: shelter.currentOccupancy,
      lat: shelter.lat,
      lng: shelter.lng,
      distance: shelter.distance,
      imageUrl: imageUrl,
      phone: shelter.phone,
    );

    await _db.insertOrUpdateShelter(updated);
    await _loadSheltersFromDb();
  }

  Future<void> addShelterWithImage(Shelter shelter, File? imageFile) async {
    String? imageUrl;

    if (imageFile != null) {
      imageUrl = await _db.uploadShelterImage(imageFile);
    }

    final newShelter = Shelter(
      id: shelter.id,
      name: shelter.name,
      address: shelter.address,
      capacity: shelter.capacity,
      currentOccupancy: shelter.currentOccupancy,
      type: shelter.type,
      lat: shelter.lat,
      lng: shelter.lng,
      imageUrl: imageUrl,
      distance: shelter.distance, // Tambahkan ini
      phone: shelter.phone, // Tambahkan ini
    );

    await _db.insertOrUpdateShelter(newShelter);
    await _loadSheltersFromDb();
  }

  Future<void> addShelter(Shelter shelter) async {
    await _db.insertOrUpdateShelter(shelter);
    await _loadSheltersFromDb();
  }

  Future<void> editShelter(Shelter updated) async {
    await _db.insertOrUpdateShelter(updated);
    await _loadSheltersFromDb();
  }

  Future<void> deleteShelter(String id) async {
    await _db.deleteShelter(id);
    await _loadSheltersFromDb();
  }

  Future<void> updateShelterOccupancy(
      String shelterId, int newOccupancy) async {
    try {
      // Gunakan 'currentOccupancy' (Sama persis dengan yang di model/fromJson)
      await supabase.from('shelter').update({
        'currentOccupancy': newOccupancy
      }) // <-- Pakai O besar, tanpa garis bawah
          .eq('id', shelterId);

      final index = _shelters.indexWhere((s) => s.id == shelterId);
      if (index != -1) {
        _shelters[index] = _shelters[index].copyWith(
          currentOccupancy: newOccupancy,
        );

        notifyListeners();
        await _saveToLocal();
        debugPrint("Berhasil update database Supabase!");
      }
    } catch (e) {
      // Jika muncul error lagi di sini, baca pesan di terminal ya
      debugPrint("Gagal update data admin: $e");
      rethrow;
    }
  }

  // ── Laporan Warga (Cloud Supabase) ───────────────────────────────

  Future<void> _loadReportsFromDb() async {
    _reports = await _db.getReports();
    notifyListeners();
  }

  Future<void> fetchReports({bool loadMore = false}) async {
    if (_isLoadingMoreReports) return;

    _isLoadingMoreReports = true;

    try {
      if (!loadMore) {
        _reportPage = 0;
        _hasMoreReports = true;
        _reports.clear();
      }

      final from = _reportPage * _reportLimit;
      final to = from + _reportLimit - 1;

      final response = await supabase
          .from('laporan')
          .select()
          .order('time', ascending: false)
          .range(from, to);

      final newReports =
          (response as List).map((e) => WargaReport.fromJson(e)).toList();

      if (newReports.isEmpty) {
        _hasMoreReports = false;
        return;
      }

      if (newReports.length < _reportLimit) {
        _hasMoreReports = false;
      }

      _reports.addAll(newReports);
      _reportPage++;
    } catch (e) {
      debugPrint('Error fetch reports: $e');
    }

    _isLoadingMoreReports = false;
    notifyListeners();
  }

  Future<void> addReport(WargaReport report) async {
    await _db.insertReport(report);
    await _loadReportsFromDb();
  }

  Future<void> verifyReport(String id) async {
    await _db.verifyReport(id);
    await _loadReportsFromDb();
  }

  Future<void> deleteReport(String id) async {
    await _db.deleteReport(id);
    await _loadReportsFromDb();
  }

  Future<void> rejectReport(String id) async {
    await _db.deleteReport(id);
    await _loadReportsFromDb();
  }

  // ── Notifikasi Admin (Cloud Supabase) ────────────────────────────

  List<String> _localDeletedIds = []; // Simpan ID yang dihapus secara lokal

  // GANTI fungsi ini di app_provider.dart
  // Di dalam class AppProvider (app_provider.dart)

  Future<void> _loadNotificationsFromDb() async {
    try {
      // 1. Ambil data asli/mentah dari Supabase
      final allNotifs = await _db.getNotifications();

      // 2. Ambil daftar ID yang disembunyikan lokal di HP ini
      final prefs = await SharedPreferences.getInstance();
      final deletedIds = prefs.getStringList('deleted_notif_ids') ?? [];
      debugPrint("DEBUG: ID yang dihapus di HP ini adalah: $deletedIds");

      // 3. LOGIKA PEMISAH (Kunci utamanya di sini)
      if (_state.isLoggedIn) {
        // JIKA ADMIN: Tampilkan SEMUA data dari database.
        // Jangan disaring pakai deletedIds supaya histori tetap utuh.
        _notifications = allNotifs;
      } else {
        // JIKA USER: Baru disaring supaya yang sudah dihapus tidak muncul.
        _notifications =
            allNotifs.where((n) => !deletedIds.contains(n.id)).toList();
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Gagal muat notif: $e');
    }
  }

  Future<void> markNotificationRead(String id) async {
    try {
      await _db.markNotificationRead(id);

      await _loadNotificationsFromDb();
    } catch (e) {
      debugPrint('Gagal menandai notifikasi dibaca: $e');
    }
  }

  Future<void> markAllNotificationsRead() async {
    try {
      await _db.markAllNotificationsRead();
      await _loadNotificationsFromDb();
    } catch (e) {
      debugPrint('Gagal menandai semua notifikasi dibaca: $e');
    }
  }

  // GANTI fungsi ini di app_provider.dart
  Future<void> deleteNotification(String id) async {
    // 1. HAPUS DARI LIST LOKAL SEGERA (Agar UI sinkron dengan Dismissible)
    _notifications.removeWhere((n) => n.id == id);
    notifyListeners(); // Beritahu UI bahwa list sudah berkurang

    try {
      if (_state.isLoggedIn) {
        // AKSI ADMIN: Hapus di Supabase
        await _db.deleteNotification(id);
      } else {
        // AKSI USER: Sembunyikan di SharedPreferences
        await _db.saveIdToLocalDeleted(id);
      }
    } catch (e) {
      debugPrint('Gagal hapus data di background: $e');
      // Opsional: Jika gagal, bisa panggil _loadNotificationsFromDb() untuk kembalikan data
    }
  }

  // Tetap gunakan ini untuk ADMIN
  Future<void> sendAdminNotification({
    required String title,
    required String message,
    String priority = 'normal',
  }) async {
    try {
      // 1. Buat Objek Notifikasi
      final notif = AdminNotification(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: title,
        message: message,
        time: DateTime.now(),
        priority: priority,
      );

      // 2. Simpan ke Database Supabase (Wajib Berhasil)
      await _db.insertNotification(notif);

      // 3. Coba munculkan notifikasi lokal (Gunakan try-catch terpisah agar tidak mematikan fungsi utama)
      try {
        await _notifSvc.showAdminNotification(notif);
      } catch (notifErr) {
        debugPrint("Gagal memunculkan notifikasi lokal HP: $notifErr");
        // Kita biarkan saja karena yang penting data sudah masuk ke database
      }

      // 4. Refresh data lokal
      await _loadNotificationsFromDb();
    } catch (e) {
      debugPrint("Error kirim notif admin: $e");
      rethrow; // Lempar balik agar UI bisa menangkap error-nya
    }
  }

  // ── BMKG & Utility ──────────────────────────────────────────────

  Future<void> fetchBmkgWeather([String? adm4]) async {
    _bmkgLoading = true;
    notifyListeners();
    try {
      _bmkgWeather = await _bmkgSvc.fetchWeather(adm4);
      _bmkgError = null;
    } catch (e) {
      _bmkgError = 'Gagal sinkron data BMKG';
    } finally {
      _bmkgLoading = false;
      notifyListeners();
    }
  }

  void dismissWarning() {
    _warningDismissed = true;
    notifyListeners();
  }

  void login(String user) {
    _state.isLoggedIn = true;
    _state.adminUser = user;
    notifyListeners();
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    _state = _state.copyWith(isLoggedIn: false, currentUser: null);
    notifyListeners();
  }

  // ── Tips & Kontak (Daftar Statis) ────────────────────────────────

  List<SafetyTip> get safetyTips => [
        const SafetyTip(
            icon: '⚡',
            title: 'Matikan Listrik',
            description:
                'Segera matikan listrik dari MCB/saklar utama untuk menghindari korsleting dan bahaya tersengat listrik saat banjir.'),
        const SafetyTip(
            icon: '📦',
            title: 'Pindahkan Barang Berharga',
            description:
                'Angkat dokumen penting (KTP, KK, sertifikat), elektronik, dan barang berharga ke tempat yang lebih tinggi.'),
        const SafetyTip(
            icon: '🎒',
            title: 'Siapkan Tas Darurat',
            description:
                'Siapkan tas berisi: obat-obatan, makanan & air minum 3 hari, pakaian, senter, dokumen penting, uang tunai.'),
        const SafetyTip(
            icon: '🚫',
            title: 'Hindari Arus Deras',
            description:
                'Jangan coba menyeberangi arus banjir meskipun tampak dangkal. Arus 15 cm sudah bisa menghanyutkan orang dewasa.'),
        const SafetyTip(
            icon: '🏠',
            title: 'Ikuti Jalur Evakuasi',
            description:
                'Gunakan jalur evakuasi yang telah ditentukan. Jangan ambil jalan pintas yang tidak dikenal saat banjir.'),
        const SafetyTip(
            icon: '📱',
            title: 'Tetap Terhubung',
            description:
                'Beritahu keluarga dan tetangga situasi terkini. Simpan nomor darurat dan pastikan HP terisi penuh.'),
        const SafetyTip(
            icon: '🐾',
            title: 'Jangan Lupakan Hewan Peliharaan',
            description:
                'Bawa hewan peliharaan saat evakuasi. Jika tidak memungkinkan, ikat di tempat tinggi dengan cukup makanan.'),
        const SafetyTip(
            icon: '🔦',
            title: 'Persiapan Darurat Normal',
            description:
                'Simpan dokumen penting dalam plastik waterproof. Ketahui jalur evakuasi terdekat dari rumah Anda.'),
      ];

  List<EmergencyContact> get emergencyContacts => [
        const EmergencyContact(
            name: 'BPBD Bandar Lampung',
            phone: '0721252741', // Nomor Telepon Kantor BPBD Balam
            icon: '🚒',
            description: 'Badan Penanggulangan Bencana Daerah'),
        const EmergencyContact(
            name: 'Call Center Darurat',
            phone: '112', // Layanan Darurat Terpadu (Gratis)
            icon: '🚨',
            description: 'Layanan Tunggal Darurat Bandar Lampung'),
        const EmergencyContact(
            name: 'Ambulans (PSC 119)',
            phone: '0811721119', // Nomor Khusus PSC 119 Bandar Lampung
            icon: '🚑',
            description: 'Layanan Gawat Darurat Medis 24 Jam'),
        const EmergencyContact(
            name: 'Pemadam Kebakaran',
            phone: '0721252741', // Sama dengan BPBD karena satu atap
            icon: '🔥',
            description: 'Dinas Pemadam Kebakaran & Penyelamatan'),
        const EmergencyContact(
            name: 'Polresta Bandar Lampung',
            phone: '0721250308', // Nomor Langsung Polresta Balam
            icon: '👮',
            description: 'Kepolisian Resor Kota Bandar Lampung'),
        const EmergencyContact(
            name: 'SAR Lampung',
            phone: '0721771002', // Kantor Basarnas Lampung
            icon: '🚁',
            description: 'Badan Nasional Pencarian dan Pertolongan'),
        const EmergencyContact(
            name: 'PLN Bandar Lampung',
            phone: '123',
            icon: '⚡',
            description: 'Gangguan Listrik dan Kabel Putus'),
      ];

  // FUNGSI UNTUK SIMPAN DATA KE MEMORI HP
  Future<void> _saveToLocal() async {
    final prefs = await SharedPreferences.getInstance();
    // Kita ubah daftar shelter menjadi string JSON agar bisa disimpan
    String encodedData = json.encode(_shelters.map((s) => s.toJson()).toList());
    await prefs.setString('cached_shelters', encodedData);
  }

  // FUNGSI UNTUK AMBIL DATA DARI MEMORI HP (SAAT OFFLINE)
  Future<void> _loadFromLocal() async {
    final prefs = await SharedPreferences.getInstance();
    String? cachedData = prefs.getString('cached_shelters');

    if (cachedData != null) {
      List<dynamic> decodedData = json.decode(cachedData);
      _shelters = decodedData.map((item) => Shelter.fromJson(item)).toList();
      notifyListeners();
      debugPrint("Data offline berhasil dimuat: ${_shelters.length} shelter.");
    }
  }
}
