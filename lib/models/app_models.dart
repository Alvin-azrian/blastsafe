// lib/models/app_models.dart

enum FloodStatus { aman, waspada, siaga, bahaya }

class AppState {
  FloodStatus status;
  String warningMessage;
  bool showWarning;
  String adminUser;
  bool isLoggedIn;
  final String? currentUser;

  AppState({
    this.status = FloodStatus.aman,
    this.warningMessage = '',
    this.showWarning = false,
    this.adminUser = '',
    this.isLoggedIn = false,
    this.currentUser,
  });

  // TAMBAHKAN FUNGSI INI:
  AppState copyWith({
    FloodStatus? status,
    bool? isLoggedIn,
    String? currentUser,
  }) {
    return AppState(
      status: status ?? this.status,
      isLoggedIn: isLoggedIn ?? this.isLoggedIn,
      currentUser: currentUser ?? this.currentUser,
    );
  }

  String get statusLabel {
    switch (status) {
      case FloodStatus.aman:
        return 'AMAN';
      case FloodStatus.waspada:
        return 'WASPADA';
      case FloodStatus.siaga:
        return 'SIAGA';
      case FloodStatus.bahaya:
        return 'BAHAYA';
    }
  }

  String get statusEmoji {
    switch (status) {
      case FloodStatus.aman:
        return '✅';
      case FloodStatus.waspada:
        return '⚠️';
      case FloodStatus.siaga:
        return '🔶';
      case FloodStatus.bahaya:
        return '🚨';
    }
  }
}

class Shelter {
  final String id;
  final String name;
  final String address;
  final int capacity;
  final int currentOccupancy;
  final String type;
  final double lat;
  final double lng;
  final String? imageUrl;
  final String phone;

  double distance;

  bool get isAvailable => currentOccupancy < capacity;

  double get occupancyPercent {
    if (capacity <= 0) return 0;
    return (currentOccupancy / capacity).clamp(0.0, 1.0);
  }

  Shelter({
    required this.id,
    required this.name,
    required this.address,
    required this.capacity,
    required this.currentOccupancy,
    required this.type,
    required this.lat,
    required this.lng,
    this.imageUrl,
    this.distance = 0,
    this.phone = '-',
  });

  // FUNGSI COPYWITH: Solusi untuk mengupdate variabel final secara aman
  Shelter copyWith({
    String? id,
    String? name,
    String? address,
    int? capacity,
    int? currentOccupancy,
    String? type,
    double? lat,
    double? lng,
    String? imageUrl,
    String? phone,
    double? distance,
  }) {
    return Shelter(
      id: id ?? this.id,
      name: name ?? this.name,
      address: address ?? this.address,
      capacity: capacity ?? this.capacity,
      currentOccupancy: currentOccupancy ?? this.currentOccupancy,
      type: type ?? this.type,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      imageUrl: imageUrl ?? this.imageUrl,
      phone: phone ?? this.phone,
      distance: distance ?? this.distance,
    );
  }

  // Konversi dari JSON (Supabase/Cache) ke Objek Dart
  factory Shelter.fromJson(Map<String, dynamic> m) {
    return Shelter(
      id: m['id']?.toString() ?? '',
      name: m['name']?.toString() ?? 'Tanpa Nama',
      address: m['address']?.toString() ?? '-',
      capacity: int.tryParse(m['capacity']?.toString() ?? '0') ?? 0,
      currentOccupancy:
          int.tryParse(m['currentOccupancy']?.toString() ?? '0') ?? 0,
      type: m['type']?.toString() ?? 'Gedung',
      lat: double.tryParse(m['lat']?.toString() ?? '0.0') ?? 0.0,
      lng: double.tryParse(m['lng']?.toString() ?? '0.0') ?? 0.0,
      imageUrl: m['image_url']?.toString(),
      distance: double.tryParse(m['distance']?.toString() ?? '0.0') ?? 0.0,
      phone: m['phone']?.toString() ?? '-',
    );
  }

  // Konversi dari Objek Dart ke JSON (Untuk simpan ke Cache Offline)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'capacity': capacity,
      'currentOccupancy': currentOccupancy,
      'type': type,
      'lat': lat,
      'lng': lng,
      'image_url': imageUrl,
      'phone': phone,
      'distance': distance,
    };
  }

  String get statusLabel {
    if (capacity == 0) return 'Tidak Diketahui';
    if (currentOccupancy >= capacity) return 'Penuh';
    if (currentOccupancy >= capacity * 0.8) return 'Hampir Penuh';
    return 'Tersedia';
  }
}

/// Laporan dari warga — disimpan ke SQLite
class WargaReport {
  final String id;
  final String description;
  final String location;
  final DateTime time;
  final String reporterName;
  final bool isVerified;
  final String? imagePath;

  const WargaReport({
    required this.id,
    required this.description,
    required this.location,
    required this.time,
    required this.reporterName,
    this.isVerified = false,
    this.imagePath,
  });

  /// Konversi ke Map untuk SQLite
  // Ganti nama ke toJson agar standar
  Map<String, dynamic> toJson() => {
        'id': id,
        'description': description,
        'location': location,
        'time': time.toIso8601String(),
        'reporterName': reporterName,
        'isVerified': isVerified,
        'imagePath': imagePath,
      };

  // GANTI INI DARI fromMap KE fromJson
  factory WargaReport.fromJson(Map<String, dynamic> map) => WargaReport(
        id: map['id']?.toString() ?? '',
        description: map['description']?.toString() ?? '',
        location: map['location']?.toString() ?? '',
        time:
            DateTime.tryParse(map['time']?.toString() ?? '') ?? DateTime.now(),
        reporterName:
            map['reporterName']?.toString() ?? 'Anonim', // Fokus ke CamelCase
        isVerified: map['isVerified'] == true, // Fokus ke CamelCase
        imagePath: map['imagePath']?.toString(), // Fokus ke CamelCase
      );
}

class SafetyTip {
  final String icon;
  final String title;
  final String description;

  const SafetyTip({
    required this.icon,
    required this.title,
    required this.description,
  });
}

class EmergencyContact {
  final String name;
  final String phone;
  final String icon;
  final String description;

  const EmergencyContact({
    required this.name,
    required this.phone,
    required this.icon,
    required this.description,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// Model baru: Notifikasi dari Admin
// ─────────────────────────────────────────────────────────────────────────────

/// Notifikasi yang dikirim admin, disimpan di SQLite dan ditampilkan sebagai
/// local notification (pop-up) di perangkat user.
class AdminNotification {
  final String id;
  final String title;
  final String message;
  final DateTime time;
  final String priority; // 'normal' | 'penting' | 'darurat'
  bool isRead;

  AdminNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.time,
    this.priority = 'normal',
    this.isRead = false,
  });

  String get priorityLabel {
    switch (priority) {
      case 'darurat':
        return '🚨 DARURAT';
      case 'penting':
        return '⚠️ PENTING';
      default:
        return 'ℹ️ INFO';
    }
  }

  // Digunakan jika ingin menyimpan balik ke database/local storage
  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'message': message,
        'time': time.toIso8601String(),
        'priority': priority,
        'isRead': isRead,
        // Sesuaikan dengan nama kolom di DB (biasanya is_read)
      };

  // 2. GANTI DARI fromMap KE fromJson
  factory AdminNotification.fromJson(Map<String, dynamic> map) =>
      AdminNotification(
        id: map['id']?.toString() ?? '',
        title: map['title']?.toString() ?? '',
        message: map['message']?.toString() ?? '',
        time: map['time'] != null
            ? DateTime.parse(map['time'].toString())
            : DateTime.now(),
        priority: map['priority']?.toString() ?? 'normal',
        // Cek 'is_read' (standar DB) atau 'isRead' (standar Map lokal)
        isRead: map['isRead'] == true || map['isRead'] == 1,
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// Model baru: Data BMKG
// ─────────────────────────────────────────────────────────────────────────────

/// Data cuaca dari API BMKG
class BmkgWeather {
  String lokasi;
  String provinsi;
  String description;
  double temperature;
  double humidity;
  String windDirection;
  double windSpeed;
  DateTime lastUpdated;
  String weatherCode; // kode cuaca BMKG (hujan, cerah, dll)

  BmkgWeather({
    required this.lokasi,
    required this.provinsi,
    required this.description,
    required this.temperature,
    required this.humidity,
    required this.windDirection,
    required this.windSpeed,
    required this.lastUpdated,
    required this.weatherCode,
  });

  // 1. Mengubah Object menjadi JSON (Untuk disimpan ke memori HP)
  Map<String, dynamic> toJson() => {
        'lokasi': lokasi,
        'provinsi': provinsi,
        'description': description,
        'temperature': temperature,
        'humidity': humidity,
        'windDirection': windDirection,
        'windSpeed': windSpeed,
        'lastUpdated': lastUpdated.toIso8601String(),
        'weatherCode': weatherCode,
      };

  // 2. Mengubah JSON kembali menjadi Object (Untuk dibaca saat Offline)
  factory BmkgWeather.fromJson(Map<String, dynamic> json) => BmkgWeather(
        lokasi: json['lokasi'] ?? '',
        provinsi: json['provinsi'] ?? '',
        description: json['description'] ?? '',
        temperature: (json['temperature'] ?? 0.0).toDouble(),
        humidity: (json['humidity'] ?? 0.0).toDouble(),
        windDirection: json['windDirection'] ?? '',
        windSpeed: (json['windSpeed'] ?? 0.0).toDouble(),
        lastUpdated: json['lastUpdated'] != null
            ? DateTime.parse(json['lastUpdated'])
            : DateTime.now(),
        weatherCode: json['weatherCode'] ?? '0',
      );

  String get weatherEmoji {
    // Kode berdasarkan kode cuaca BMKG
    if (weatherCode == '60' || weatherCode == '61' || weatherCode == '63') {
      return '🌧️';
    }
    if (weatherCode == '80' || weatherCode == '81' || weatherCode == '82') {
      return '⛈️';
    }
    if (weatherCode == '1' || weatherCode == '2') return '🌤️';
    if (weatherCode == '3' || weatherCode == '4') return '☁️';
    if (weatherCode == '45') return '🌫️';
    return '🌤️';
  }

  bool get isRaining =>
      weatherCode == '60' ||
      weatherCode == '61' ||
      weatherCode == '63' ||
      weatherCode == '80' ||
      weatherCode == '81' ||
      weatherCode == '82';
}
