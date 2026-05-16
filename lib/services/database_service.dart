// lib/services/database_service.dart
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/app_models.dart';
import 'package:flutter/foundation.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  // FIX: Gunakan GETTER agar client hanya dipanggil SAAT DIBUTUHKAN (lazy loading)
  // Ini akan mencegah error inisialisasi saat aplikasi pertama kali dibuka
  SupabaseClient get supabase => Supabase.instance.client;

  static const String _keyDeletedNotifs = 'deleted_notifications';

  // Ambil daftar ID yang dihapus di HP ini
  Future<List<String>> getLocalDeletedIds() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_keyDeletedNotifs) ?? [];
  }

  // Simpan ID ke daftar hapus di HP ini
  Future<void> saveIdToLocalDeleted(String id) async {
    final prefs = await SharedPreferences.getInstance();
    // PAKAI KEY YANG SAMA: 'deleted_notif_ids'
    List<String> deleted = prefs.getStringList('deleted_notif_ids') ?? [];

    if (!deleted.contains(id)) {
      deleted.add(id);
      await prefs.setStringList(
          'deleted_notif_ids', deleted); // SIMPAN DENGAN KEY YANG SAMA
      debugPrint("ID $id berhasil disimpan ke memori HP.");
    }
  }

  //STATUS APLIAKSI
  Future<Map<String, dynamic>?> getAppStatus() async {
    return await supabase.from('app_status').select().eq('id', 1).maybeSingle();
  }

  Future<void> updateAppStatus(String status, String message) async {
    await supabase.from('app_status').upsert({
      'id': 1,
      'status': status,
      'message': message,
      'updated_at': DateTime.now().toIso8601String(),
    });
  }

  // ══════════════════════════════════════════════════════════════════
  // SHELTER (Cloud PostgreSQL)
  // ══════════════════════════════════════════════════════════════════

  // Di dalam class DatabaseService
  Future<String?> uploadShelterImage(File imageFile) async {
    try {
      // 1. Buat ekstensi dan nama file yang unik (menggunakan timestamp)
      final fileExtension = imageFile.path.split('.').last;
      final fileName =
          'shelter_${DateTime.now().millisecondsSinceEpoch}.$fileExtension';

      // 2. Ganti 'shelter_images' dengan nama BUCKET Anda di Supabase
      final String bucketName = 'shelter_images';

      // 3. Proses upload file fisik ke bucket Supabase
      await Supabase.instance.client.storage
          .from(bucketName)
          .upload(fileName, imageFile);

      // 4. Ambil URL publik dari file yang barusan di-upload
      final publicUrl = Supabase.instance.client.storage
          .from(bucketName)
          .getPublicUrl(fileName);

      return publicUrl; // URL ini yang akan masuk ke variabel imageUrl
    } catch (e) {
      print('Gagal upload gambar ke Supabase: $e');
      return null; // Jika gagal, kembalikan null agar tidak error
    }
  }

  Future<void> insertOrUpdateShelter(Shelter s) async {
    // Gunakan .toJson() karena di Model sudah kita ubah namanya
    // Pastikan nama tabel di Supabase adalah 'shelters' (biasanya jamak)
    await supabase.from('shelter').upsert(s.toJson());
  }

  Future<List<Shelter>> getShelters() async {
    try {
      final response = await supabase
          .from('shelter')
          .select()
          .order('name', ascending: true);

      debugPrint("DATA RAW SHELTER:");
      debugPrint(response.toString());

      List<Shelter> shelters = [];

      for (final item in response) {
        try {
          debugPrint("ITEM:");
          debugPrint(item.toString());

          shelters.add(
            Shelter.fromJson(item),
          );
        } catch (e) {
          debugPrint("ERROR PARSING SHELTER:");
          debugPrint(e.toString());
        }
      }

      debugPrint("TOTAL SHELTER BERHASIL: ${shelters.length}");

      return shelters;
    } catch (e) {
      debugPrint("ERROR GET SHELTERS:");
      debugPrint(e.toString());

      return [];
    }
  }

  Future<void> deleteShelter(String id) async {
    await supabase.from('shelter').delete().eq('id', id);
  }

  Future<void> updateShelterOccupancy(String id, int occ) async {
    await supabase
        .from('shelter')
        .update({'current_occupancy': occ}).eq('id', id);
  }

  // ══════════════════════════════════════════════════════════════════
  // LAPORAN WARGA (Cloud PostgreSQL)
  // ══════════════════════════════════════════════════════════════════

  Future<void> insertReport(WargaReport report) async {
    await supabase.from('laporan').insert({
      'id': report.id,
      'description': report.description,
      'location': report.location,
      'time': report.time.toIso8601String(),
      'reporterName': report.reporterName, // Pakai N besar
      'isVerified': report.isVerified, // Pakai V besar
      'imagePath': report.imagePath, // PAKAI P BESAR (Jangan image_path)
    });
  }

  Future<List<WargaReport>> getReports() async {
    try {
      final response = await supabase
          .from('laporan')
          .select()
          // Pastikan di tabel Supabase kolomnya bernama 'time' atau 'created_at'
          .order('time', ascending: false);

      // Ganti .fromMap(m) menjadi .fromJson(m)
      // Tambahkan (response as List) agar Flutter yakin ini adalah data list
      return (response as List).map((m) => WargaReport.fromJson(m)).toList();
    } catch (e) {
      print("Error getReports: $e");
      return [];
    }
  }

  Future<void> verifyReport(String id) async {
    await supabase.from('laporan').update({'isVerified': true}).eq('id', id);
  }

  Future<void> deleteReport(String id) async {
    await supabase.from('laporan').delete().eq('id', id);
  }

  // ══════════════════════════════════════════════════════════════════
  // NOTIFIKASI ADMIN (Cloud PostgreSQL)
  // ══════════════════════════════════════════════════════════════════

  Future<void> insertNotification(AdminNotification notif) async {
    // Hindari menggunakan .toJson() langsung jika isinya masih menggunakan is_read.
    // Kirim Map secara manual agar kunci (key) PASTI sama dengan kolom di database.
    await supabase.from('notifikasi').insert({
      'id': notif.id,
      'title': notif.title,
      'message': notif.message,
      'time': notif.time.toIso8601String(),
      'priority': notif.priority,
      'isRead': notif.isRead, // Pastikan 'R' besar sesuai SQL kamu
    });
  }

  Future<List<AdminNotification>> getNotifications() async {
    try {
      final response = await supabase
          .from('notifikasi')
          .select()
          .order('time', ascending: false);

      return (response as List)
          .map((m) => AdminNotification.fromJson(m))
          .toList();
    } catch (e) {
      debugPrint("Error getNotifications: $e");
      return [];
    }
  }

  Future<void> markNotificationRead(String id) async {
    // Gunakan 'isRead' (R besar) agar tidak error PGRST204
    await supabase.from('notifikasi').update({'isRead': true}).eq('id', id);
  }

  Future<void> markAllNotificationsRead() async {
    await supabase.from('notifikasi').update({'isRead': true}).eq(
        'isRead', false); // Gunakan 'isRead' di sini juga
  }

  Future<void> deleteNotification(String id) async {
    await supabase.from('notifikasi').delete().eq('id', id);
  }

  Future<int> unreadNotificationCount() async {
    // Menghitung jumlah notifikasi yang belum dibaca
    final response =
        await supabase.from('notifikasi').select('id').eq('isRead', false);

    return (response as List).length;
  }
}
