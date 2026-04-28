import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/tokens.dart';
import '../../../shared/widgets/hud.dart';
import '../application/profile_provider.dart';

class NotificationPrefsScreen extends ConsumerStatefulWidget {
  const NotificationPrefsScreen({super.key});

  @override
  ConsumerState<NotificationPrefsScreen> createState() => _NotificationPrefsScreenState();
}

class _NotificationPrefsScreenState extends ConsumerState<NotificationPrefsScreen> {
  Map<String, bool>? _prefs;
  bool _saving = false;

  static const _rows = [
    (key: 'new_episodes',    label: 'New Episodes',     subtitle: 'When a new episode drops from a series you follow', icon: Icons.play_circle_outline),
    (key: 'streak_reminder', label: 'Streak Reminder',  subtitle: 'Daily reminder to keep your streak alive',          icon: Icons.local_fire_department_outlined),
    (key: 'creator_updates', label: 'Creator Updates',  subtitle: 'When a creator you follow posts an update',         icon: Icons.movie_creation_outlined),
    (key: 'inbox_rewards',   label: 'Inbox Rewards',    subtitle: 'When you have unclaimed coins or gems waiting',     icon: Icons.card_giftcard_outlined),
  ];

  @override
  void initState() {
    super.initState();
    final profile = ref.read(profileProvider).valueOrNull;
    if (profile != null) {
      _prefs = Map<String, bool>.from(profile.notificationPrefs);
    }
  }

  Future<void> _toggle(String key, bool value) async {
    if (_saving) return;
    setState(() {
      _prefs = {...?_prefs, key: value};
      _saving = true;
    });

    try {
      final session = Supabase.instance.client.auth.currentSession;
      if (session == null) return;
      await Supabase.instance.client.functions.invoke(
        'update-notification-prefs',
        headers: {'Authorization': 'Bearer ${session.accessToken}'},
        body: {'prefs': {key: value}},
      );
      ref.invalidate(profileProvider);
    } catch (_) {
      // Revert optimistic update on failure
      if (mounted) setState(() => _prefs = {...?_prefs, key: !value});
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(profileProvider);

    // Hydrate from provider if local state not yet set
    profileAsync.whenData((p) {
      if (_prefs == null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) setState(() => _prefs = Map<String, bool>.from(p.notificationPrefs));
        });
      }
    });

    final prefs = _prefs ?? {};

    return Scaffold(
      backgroundColor: bgDeep,
      appBar: const HUD(),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        children: [
          Text(
            '🔔 Notifications',
            style: GoogleFonts.nunito(
              color: textCol,
              fontWeight: FontWeight.w900,
              fontSize: 24,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Choose which notifications you receive',
            style: GoogleFonts.sora(color: textDim, fontSize: 13),
          ),
          const SizedBox(height: 24),
          ..._rows.map((row) => _PrefTile(
                icon: row.icon,
                label: row.label,
                subtitle: row.subtitle,
                value: prefs[row.key] ?? true,
                onChanged: _saving ? null : (v) => _toggle(row.key, v),
              )),
        ],
      ),
    );
  }
}

class _PrefTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final bool value;
  final ValueChanged<bool>? onChanged;

  const _PrefTile({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderHi),
      ),
      child: SwitchListTile(
        secondary: Icon(icon, color: cyan, size: 22),
        title: Text(
          label,
          style: GoogleFonts.nunito(
            color: textCol,
            fontWeight: FontWeight.w700,
            fontSize: 15,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: GoogleFonts.sora(color: textDim, fontSize: 12),
        ),
        value: value,
        onChanged: onChanged,
        activeColor: cyan,
        inactiveThumbColor: textDim,
        inactiveTrackColor: surface,
      ),
    );
  }
}
