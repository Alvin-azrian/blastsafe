// lib/screens/notifikasi_screen.dart
// FIX:
//   1. Error hapus/baca notifikasi: GestureDetector bertumpuk → pakai Dismissible
//      + tombol hapus menggunakan stopPropagation agar tidak konflik dengan tap card
//   2. DateFormat id_ID bekerja karena initializeDateFormatting dipanggil di main.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../data/app_provider.dart';
import '../models/app_models.dart';
import '../theme.dart';

class NotifikasiScreen extends StatelessWidget {
  const NotifikasiScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (ctx, provider, _) {
        final notifs = provider.notifications;

        return Scaffold(
          backgroundColor: AppTheme.surface,
          appBar: AppBar(
            title: const Text('Notifikasi'),
            backgroundColor: AppTheme.primary,
            actions: [
              if (notifs.any((n) => !n.isRead))
                TextButton(
                  onPressed: provider.markAllNotificationsRead,
                  child: const Text(
                    'Baca Semua',
                    style: TextStyle(color: Colors.white, fontSize: 13),
                  ),
                ),
            ],
          ),
          body: notifs.isEmpty
              ? _emptyState()
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: notifs.length,
                  itemBuilder: (ctx, i) {
                    final notif = notifs[i];

                    return Dismissible(
                      // Gunakan key yang sangat unik
                      key: Key('notif_${notif.id}'),
                      direction: DismissDirection.endToStart,

                      // Efek visual saat geser
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        margin: const EdgeInsets.only(bottom: 10),
                        decoration: BoxDecoration(
                          color: AppTheme.statusBahaya,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(Icons.delete, color: Colors.white),
                      ),

                      confirmDismiss: (_) async {
                        return await showDialog<bool>(
                              context: ctx,
                              builder: (c) => AlertDialog(
                                title: const Text('Hapus Notifikasi?'),
                                content: Text('Hapus "${notif.title}"?'),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(c, false),
                                    child: const Text('Batal'),
                                  ),
                                  ElevatedButton(
                                    onPressed: () => Navigator.pop(c, true),
                                    child: const Text('Hapus'),
                                  ),
                                ],
                              ),
                            ) ??
                            false;
                      },

                      onDismissed: (direction) {
                        // Memanggil fungsi hapus yang sudah kita perbaiki di atas
                        provider.deleteNotification(notif.id);

                        ScaffoldMessenger.of(ctx).showSnackBar(
                          const SnackBar(
                            content: Text('Notifikasi dihapus'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },

                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _NotifCard(
                          notif: notif,
                          provider: provider,
                        ),
                      ),
                    );
                  },
                ),
        );
      },
    );
  }
}

Widget _emptyState() {
  return const Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('🔔', style: TextStyle(fontSize: 48)),
        SizedBox(height: 12),
        Text(
          'Belum ada notifikasi',
          style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary),
        ),
        SizedBox(height: 4),
        Text(
          'Pesan dari admin akan muncul di sini',
          style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
        ),
        SizedBox(height: 8),
        Text(
          '← Geser kartu ke kiri untuk menghapus',
          style: TextStyle(fontSize: 11, color: AppTheme.textSecondary),
        ),
      ],
    ),
  );
}

class _NotifCard extends StatelessWidget {
  final AdminNotification notif;
  final AppProvider provider;

  const _NotifCard({required this.notif, required this.provider});

  Color get _priorityColor {
    switch (notif.priority) {
      case 'darurat':
        return AppTheme.statusBahaya;
      case 'penting':
        return AppTheme.statusWaspada;
      default:
        return AppTheme.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    // FIX: Gunakan InkWell dengan splash agar tap terasa lebih natural
    // dan tidak ada konflik gesture dengan tombol hapus
    return InkWell(
      onTap: () {
        if (!notif.isRead) provider.markNotificationRead(notif.id);
        _showDetail(context);
      },
      borderRadius: BorderRadius.circular(14),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: notif.isRead ? Colors.white : _priorityColor.withOpacity(0.05),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: notif.isRead
                ? AppTheme.border
                : _priorityColor.withOpacity(0.4),
            width: notif.isRead ? 1 : 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: _priorityColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      notif.priorityLabel,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: _priorityColor,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    _formatTime(notif.time),
                    style: const TextStyle(
                        fontSize: 10, color: AppTheme.textSecondary),
                  ),
                  if (!notif.isRead) ...[
                    const SizedBox(width: 8),
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: _priorityColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 8),
              Text(
                notif.title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: notif.isRead ? FontWeight.w500 : FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                notif.message,
                style: const TextStyle(
                    fontSize: 12, color: AppTheme.textSecondary, height: 1.4),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              // Hint geser untuk hapus
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (!notif.isRead)
                    GestureDetector(
                      // FIX: stopPropagation agar tidak trigger card tap
                      onTap: () => provider.markNotificationRead(notif.id),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          '✓ Tandai Dibaca',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.primary,
                          ),
                        ),
                      ),
                    )
                  else
                    const SizedBox.shrink(),
                  const Text(
                    '← geser untuk hapus',
                    style:
                        TextStyle(fontSize: 10, color: AppTheme.textSecondary),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDetail(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _priorityColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                notif.priority == 'darurat'
                    ? '🚨'
                    : notif.priority == 'penting'
                        ? '⚠️'
                        : 'ℹ️',
                style: const TextStyle(fontSize: 20),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                notif.title,
                style:
                    const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              notif.message,
              style: const TextStyle(fontSize: 14, height: 1.6),
            ),
            const SizedBox(height: 12),
            Text(
              // FIX: DateFormat sekarang tidak error karena initializeDateFormatting
              // dipanggil di main.dart sebelum runApp()
              'Dikirim: ${DateFormat('dd MMM yyyy, HH:mm', 'id_ID').format(notif.time)}',
              style:
                  const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime t) {
    final diff = DateTime.now().difference(t);
    if (diff.inMinutes < 60) return '${diff.inMinutes} mnt lalu';
    if (diff.inHours < 24) return '${diff.inHours} jam lalu';
    if (diff.inDays < 7) return '${diff.inDays} hari lalu';
    return DateFormat('dd/MM/yy').format(t);
  }
}
