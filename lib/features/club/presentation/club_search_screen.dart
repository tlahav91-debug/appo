import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/tokens.dart';
import '../application/club_provider.dart';
import '../domain/watch_club.dart';

class ClubSearchScreen extends ConsumerStatefulWidget {
  const ClubSearchScreen({super.key});

  @override
  ConsumerState<ClubSearchScreen> createState() => _ClubSearchScreenState();
}

class _ClubSearchScreenState extends ConsumerState<ClubSearchScreen> {
  final _searchCtrl = TextEditingController();
  String _query = '';
  bool _showCreate = false;
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    _nameCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final clubsAsync = ref.watch(clubSearchProvider(_query));
    final actionAsync = ref.watch(clubActionProvider);

    return Scaffold(
      backgroundColor: bgDeep,
      appBar: AppBar(
        backgroundColor: bgDeep,
        foregroundColor: textCol,
        title: Text('Find a Club',
            style: GoogleFonts.nunito(
                color: textCol, fontWeight: FontWeight.w900, fontSize: 18)),
        actions: [
          TextButton(
            onPressed: () => setState(() => _showCreate = !_showCreate),
            child: Text(
              _showCreate ? 'Cancel' : '+ Create',
              style: GoogleFonts.sora(
                  color: cyan, fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Create form
          if (_showCreate)
            _CreateClubPanel(
              nameCtrl: _nameCtrl,
              descCtrl: _descCtrl,
              isLoading: actionAsync.isLoading,
              onSubmit: () => _createClub(context),
            ),
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              controller: _searchCtrl,
              style: GoogleFonts.sora(color: textCol, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Search clubs…',
                hintStyle: GoogleFonts.sora(color: textDim),
                filled: true,
                fillColor: card,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                prefixIcon: const Icon(Icons.search, color: textDim),
                suffixIcon: _query.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: textDim),
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() => _query = '');
                        },
                      )
                    : null,
              ),
              onChanged: (v) => setState(() => _query = v.trim()),
            ),
          ),
          // Results
          Expanded(
            child: clubsAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator(color: cyan)),
              error: (e, _) => Center(
                child: Text('Failed to load clubs',
                    style: GoogleFonts.sora(color: textDim)),
              ),
              data: (clubs) {
                if (clubs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('👥', style: TextStyle(fontSize: 40)),
                        const SizedBox(height: 12),
                        Text(
                          _query.isEmpty
                              ? 'No clubs yet — create one!'
                              : 'No clubs found for "$_query"',
                          style:
                              GoogleFonts.sora(color: textDim, fontSize: 14),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  itemCount: clubs.length,
                  itemBuilder: (_, i) => _ClubRow(
                    club: clubs[i],
                    isLoading: actionAsync.isLoading,
                    onJoin: () => _joinClub(context, clubs[i].id),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _createClub(BuildContext context) async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return;
    try {
      final clubId = await ref
          .read(clubActionProvider.notifier)
          .create(name, _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim());
      if (context.mounted) {
        context.pop();
        context.push('/club/$clubId');
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(_friendlyError(e.toString()),
              style: GoogleFonts.sora(color: textCol)),
          backgroundColor: surface,
        ));
      }
    }
  }

  Future<void> _joinClub(BuildContext context, String clubId) async {
    try {
      await ref.read(clubActionProvider.notifier).join(clubId);
      if (context.mounted) {
        context.pop();
        context.push('/club/$clubId');
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(_friendlyError(e.toString()),
              style: GoogleFonts.sora(color: textCol)),
          backgroundColor: surface,
        ));
      }
    }
  }

  String _friendlyError(String raw) {
    if (raw.contains('already_in_club')) return 'You\'re already in a club.';
    if (raw.contains('club_full')) return 'This club is full (20 members max).';
    if (raw.contains('club_not_found')) return 'Club not found.';
    return 'Something went wrong. Please try again.';
  }
}

class _CreateClubPanel extends StatelessWidget {
  final TextEditingController nameCtrl;
  final TextEditingController descCtrl;
  final bool isLoading;
  final VoidCallback onSubmit;

  const _CreateClubPanel({
    required this.nameCtrl,
    required this.descCtrl,
    required this.isLoading,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cyanDim),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Create Club',
              style: GoogleFonts.nunito(
                  color: textCol, fontWeight: FontWeight.w800, fontSize: 15)),
          const SizedBox(height: 10),
          _field(nameCtrl, 'Club name*'),
          const SizedBox(height: 8),
          _field(descCtrl, 'Description (optional)'),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: isLoading ? null : onSubmit,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                gradient: cyanGrad,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: isLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: textCol))
                    : Text('Create',
                        style: GoogleFonts.nunito(
                            color: textCol,
                            fontWeight: FontWeight.w900,
                            fontSize: 14)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _field(TextEditingController ctrl, String hint) {
    return TextField(
      controller: ctrl,
      style: const TextStyle(color: textCol, fontSize: 13),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: textDim, fontSize: 13),
        filled: true,
        fillColor: surface,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

class _ClubRow extends StatelessWidget {
  final WatchClub club;
  final bool isLoading;
  final VoidCallback onJoin;

  const _ClubRow(
      {required this.club, required this.isLoading, required this.onJoin});

  @override
  Widget build(BuildContext context) {
    final isFull = club.memberCount >= 20;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border),
      ),
      child: Row(
        children: [
          const Text('👥', style: TextStyle(fontSize: 20)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(club.name,
                    style: GoogleFonts.nunito(
                        color: textCol,
                        fontWeight: FontWeight.w800,
                        fontSize: 14),
                    overflow: TextOverflow.ellipsis),
                if (club.description != null)
                  Text(club.description!,
                      style: GoogleFonts.sora(color: textDim, fontSize: 11),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                Text('${club.memberCount}/20 members',
                    style: GoogleFonts.sora(color: textSec, fontSize: 11)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: (isLoading || isFull) ? null : onJoin,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                gradient: isFull ? null : cyanGrad,
                color: isFull ? card : null,
                borderRadius: BorderRadius.circular(8),
                border: isFull ? Border.all(color: border) : null,
              ),
              child: Text(
                isFull ? 'Full' : 'Join',
                style: GoogleFonts.nunito(
                  color: isFull ? textDim : textCol,
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
