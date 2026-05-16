// lib/services/notification_service.dart
// Layanan notifikasi lokal (flutter_local_notifications)
// Pop-up muncul di luar aplikasi ketika admin mengirim pesan/peringatan.

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../models/app_models.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  /// Inisialisasi — panggil sekali di main() sebelum runApp
  Future<void> initialize() async {
    if (_initialized) return;

    // Android: gunakan ikon default launcher
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS/macOS
    const darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
    );

    await _plugin.initialize(initSettings);

    // Minta izin notifikasi (Android 13+)
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    _initialized = true;
  }

  /// Kirim notifikasi pop-up dari admin ke user
  /// [notif] berisi judul, isi, dan prioritas.
  Future<void> showAdminNotification(AdminNotification notif) async {
    await initialize();

    // Tentukan importance berdasarkan prioritas
    final importance = _importanceFromPriority(notif.priority);
    final priority = _priorityFromStr(notif.priority);

    final androidDetails = AndroidNotificationDetails(
      'admin_channel',             // channel id
      'Pesan Admin BlastSafe',     // channel name
      channelDescription: 'Notifikasi peringatan dan informasi dari Admin',
      importance: importance,
      priority: priority,
      icon: '@mipmap/ic_launcher',
      color: _colorFromPriority(notif.priority),
      playSound: true,
      enableVibration: notif.priority != 'normal',
      styleInformation: BigTextStyleInformation(notif.message),
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    // Gunakan hash id agar setiap notif unik
    final notifId = notif.id.hashCode.abs() % 2147483647;

    await _plugin.show(
      notifId,
      '${notif.priorityLabel} — ${notif.title}',
      notif.message,
      details,
    );
  }

  /// Batalkan semua notifikasi
  Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }

  // ─── Helper ──────────────────────────────────────────────────────

  Importance _importanceFromPriority(String p) {
    switch (p) {
      case 'darurat': return Importance.max;
      case 'penting': return Importance.high;
      default: return Importance.defaultImportance;
    }
  }

  Priority _priorityFromStr(String p) {
    switch (p) {
      case 'darurat': return Priority.max;
      case 'penting': return Priority.high;
      default: return Priority.defaultPriority;
    }
  }

  // Warna badge/notif
  Color _colorFromPriority(String p) {
    switch (p) {
      case 'darurat': return const Color(0xFFD32F2F); // merah
      case 'penting': return const Color(0xFFFF8F00); // oranye
      default: return const Color(0xFF1565C0);        // biru
    }
  }
}
