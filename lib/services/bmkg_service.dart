// lib/services/bmkg_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/app_models.dart';
// ignore: duplicate_import
import 'dart:convert';
// ignore: duplicate_import
import 'package:http/http.dart' as http;
// ignore: duplicate_import
import '../models/app_models.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Tambahan untuk Caching

class BmkgService {
  static const _apiBase = 'https://api.bmkg.go.id/publik/prakiraan-cuaca';

  // ✅ Daftar kode ADM4 Kota Bandar Lampung (18 = Lampung, 71 = Kota Bandar Lampung)
  // Format: 18.71.[kode_kecamatan].[kode_kelurahan]
  // Disusun dari yang paling central → fallback ke wilayah lain
  // Hapus underscore (_) agar menjadi public
  static const adm4List = [
    '18.71.05.1001', // Tanjungkarang Pusat
    '18.71.03.1001', // Tanjungkarang Barat
    '18.71.04.1001', // Tanjungkarang Timur
    '18.71.08.1001', // Kedaton
    '18.71.10.1001', // Rajabasa
    '18.71.11.1001', // Sukarame
    '18.71.13.1001', // Way Halim
    '18.71.01.1001', // Telukbetung Selatan
    '18.71.09.1001', // Telukbetung Utara
    '18.71.12.1001', // Panjang
  ];

  // 1. TAMBAHKAN MAP NAMA WILAYAH INI
  static const adm4Names = {
    '18.71.05.1001': 'Tanjung Karang Pusat',
    '18.71.03.1001': 'Tanjung Karang Barat',
    '18.71.04.1001': 'Tanjung Karang Timur',
    '18.71.08.1001': 'Kedaton',
    '18.71.10.1001': 'Rajabasa',
    '18.71.11.1001': 'Sukarame',
    '18.71.13.1001': 'Way Halim',
    '18.71.01.1001': 'Teluk Betung Selatan',
    '18.71.09.1001': 'Teluk Betung Utara',
    '18.71.12.1001': 'Panjang',
  };

  //Penerjemah cuaca
  String getWeatherDesc(int code) {
    switch (code) {
      case 0:
        return 'Cerah';
      case 1:
      case 2:
        return 'Cerah Berawan';
      case 3:
        return 'Berawan';
      case 4:
        return 'Berawan Tebal';
      case 5:
        return 'Udara Kabur';
      case 10:
        return 'Asap';
      case 45:
        return 'Kabut';
      case 60:
        return 'Hujan Ringan';
      case 61:
        return 'Hujan Sedang';
      case 63:
        return 'Hujan Lebat';
      case 95:
        return 'Hujan Petir';
      case 97:
        return 'Hujan Petir Lokal';
      default:
        return 'Berawan';
    }
  }

  /// Ambil cuaca dari beberapa ADM4 sampai dapat data valid
  /// Ambil cuaca BMKG
  /// Jika adm4 dikirim → pakai lokasi user
  /// Jika null → fallback daftar Bandar Lampung
  Future<BmkgWeather> fetchWeather(
      [String? adm4, bool skipFallback = false]) async {
    final targetAdm4 = adm4 ?? adm4List.first;

    if (adm4 != null) {
      try {
        final uri = Uri.parse('$_apiBase?adm4=$adm4');
        final resp = await http.get(uri).timeout(const Duration(seconds: 5));

        if (resp.statusCode == 200) {
          final body = json.decode(resp.body);
          final parsed = _parse(body);

          if (parsed.lokasi.isNotEmpty && parsed.temperature > 0) {
            await _saveToCache(adm4, parsed); // Simpan ke HP saat sukses
            return parsed;
          }
        }
      } catch (_) {
        // JIKA OFFLINE: Coba ambil dari HP dulu sebelum menyerah
        final cachedData = await _getFromCache(adm4);
        if (cachedData != null) return cachedData;
      }
    }

    if (skipFallback) {
      final cachedData = await _getFromCache(targetAdm4);
      if (cachedData != null) return cachedData;
      return _offlineWeather();
    }

    // Fallback default
    for (final kode in adm4List) {
      try {
        final uri = Uri.parse('$_apiBase?adm4=$kode');
        final resp = await http.get(uri).timeout(const Duration(seconds: 5));

        if (resp.statusCode == 200) {
          final body = json.decode(resp.body);
          final parsed = _parse(body);

          if (parsed.lokasi.isNotEmpty && parsed.temperature > 0) {
            await _saveToCache(kode, parsed); // Simpan ke HP
            return parsed;
          }
        }
      } catch (_) {
        continue;
      }
    }

    // Upaya terakhir: Cek cache wilayah default
    final fallbackCache = await _getFromCache(adm4List.first);
    if (fallbackCache != null) return fallbackCache;

    return _offlineWeather();
  }

  // --- FUNGSI CACHING ---

  Future<void> _saveToCache(String adm4, BmkgWeather weather) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = json.encode(weather.toJson());
      await prefs.setString('weather_$adm4', jsonString);
    } catch (_) {}
  }

  Future<BmkgWeather?> _getFromCache(String adm4) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString('weather_$adm4');

      if (jsonString != null) {
        final Map<String, dynamic> jsonMap = json.decode(jsonString);
        final cachedWeather = BmkgWeather.fromJson(jsonMap);

        // Tambahkan tanda agar user sadar ini data simpanan lama
        cachedWeather.description = '${cachedWeather.description} (Offline)';
        return cachedWeather;
      }
    } catch (_) {}
    return null;
  }

  // --- FUNGSI PARSING & OFFLINE BAWAAN ---

  BmkgWeather _parse(Map<String, dynamic> data) {
    try {
      final item = data['data'][0];
      final lokasi = item['lokasi'];
      final cuaca = item['cuaca'][0][0];

      return BmkgWeather(
        lokasi: lokasi['kecamatan']?.toString() ?? 'Bandar Lampung',
        provinsi: lokasi['provinsi']?.toString() ?? 'Lampung',
        description: cuaca['weather_desc']?.toString() ?? 'Tidak diketahui',
        temperature: double.tryParse(cuaca['t']?.toString() ?? '') ?? 28.0,
        humidity: double.tryParse(cuaca['hu']?.toString() ?? '') ?? 75.0,
        windDirection: cuaca['wd_to']?.toString() ?? 'Tenggara',
        windSpeed:
            (double.tryParse(cuaca['ws']?.toString() ?? '') ?? 3.0) * 3.6,
        lastUpdated: DateTime.now(),
        weatherCode: cuaca['weather']?.toString() ?? '1',
      );
    } catch (_) {
      return _offlineWeather();
    }
  }

  BmkgWeather _offlineWeather() {
    return BmkgWeather(
      lokasi: 'Bandar Lampung',
      provinsi: 'Lampung',
      description: 'Offline (Tidak ada jaringan & data)',
      temperature: 29.0,
      humidity: 80.0,
      windDirection: '-',
      windSpeed: 0.0,
      lastUpdated: DateTime.now(),
      weatherCode: '0',
    );
  }
}
