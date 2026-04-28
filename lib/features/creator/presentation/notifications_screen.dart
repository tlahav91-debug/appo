import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/tokens.dart';
import '../application/notifications_provider.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  Future<void> _markRead(String notificationId) async {
    await Supabase.instance.client.functions.invoke(
      'mark-notification-read',
      body: {'notification_id': notificationId},
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifsAsync = ref.watch(notificationsProvider);

    return Scaffold(
      backgroundColor: bgDeep,
      appBar: AppBar(
        backgroundColor: bgDeep,
        elevation: 0,
        leading: BackButton(color: textCol),
        title: Text(
          'Notifications',
          style: GoogleFonts.nunito(color: textCol, fontWeight: FontWeight.w800, fontSize: 20),
        ),
      ),
      body: notifsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: gold)),
        error: (e, _) => Center(child: Text('Failed to load notifications', style: GoogleFonts.sora(color: textDim))),
        data: (notifs) {
          if (notifs.isEmpty) {
            return Center(
              child: Text('No notifications yet.', style: GoogleFonts.sora(color: textDim, fontSize: 14)),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: notifs.length,
            itemBuilder: (context, i) {
              final n = notifs[i];
              return _NotificationTile(
                notification: n,
                onTap: () => _markRead(n['id'] as String),
              );
            },
          );
        },
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final Map<String, dynamic> notification;
  final VoidCallback onTap;
  const _NotificationTile({required this.notification, required this.onTap});

  String _icon(String type) {
    switch (type) {
      case 'content_approved': return '✅';
      case 'content_rejected': return '❌';
      case 'payout_processed': return '💸';
      case 'milestone_100_views': return '🎉';
      case 'milestone_1k_views': return '🚀';
      case 'milestone_10k_views': return '🔥';
      case 'new_episode_from_followed': return '🎬';
      default: return '🔔';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isRead = notification['is_read'] as bool;
    final type = notification['type'] as String;
    final title = notification['title'] as String;
    final body = notification['body'] as String;
    final createdAt = notification['created_at'] as String;
    final ts = DateTime.tryParse(createdAt)?.toLocal();
    final timeStr = ts != null ? '${ts.month}/${ts.day} ${ts.hour}:${ts.minute.toString().padLeft(2, '0')}' : '';

    return InkWell(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isRead ? surface : surface.withOpacity(0.95),
          borderRadius: BorderRadius.circular(12),
          border: isRead ? null : Border.all(color: gold.withOpacity(0.3), width: 1),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_icon(type), style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: GoogleFonts.nunito(color: textCol, fontWeight: FontWeight.w700, fontSize: 14)),
                  const SizedBox(height: 2),
                  Text(body, style: GoogleFonts.sora(color: textSec, fontSize: 12)),
                  const SizedBox(height: 4),
                  Text(timeStr, style: GoogleFonts.sora(color: textDim, fontSize: 11)),
                ],
              ),
            ),
            if (!isRead)
              Container(
                width: 8, height: 8,
                decoration: const BoxDecoration(color: gold, shape: BoxShape.circle),
              ),
          ],
        ),
      ),
    );
  }
}
