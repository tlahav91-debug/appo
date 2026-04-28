import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/tokens.dart';
import '../application/comments_provider.dart';
import '../domain/episode_comment.dart';

class CommentsSheet extends ConsumerStatefulWidget {
  final String episodeId;

  const CommentsSheet({super.key, required this.episodeId});

  @override
  ConsumerState<CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends ConsumerState<CommentsSheet> {
  List<EpisodeComment> _comments = [];
  bool _loading = true;
  bool _submitting = false;
  final _controller = TextEditingController();
  RealtimeChannel? _channel;

  @override
  void initState() {
    super.initState();
    _loadComments();
    _channel = Supabase.instance.client
        .channel('comments:${widget.episodeId}')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'episode_comments',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'episode_id',
            value: widget.episodeId,
          ),
          callback: (_) => _loadComments(),
        )
        .subscribe();
  }

  @override
  void dispose() {
    _channel?.unsubscribe();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadComments() async {
    try {
      final data = await Supabase.instance.client
          .from('episode_comments')
          .select('*, profiles(username, avatar_url)')
          .eq('episode_id', widget.episodeId)
          .order('created_at', ascending: false)
          .limit(20);
      if (!mounted) return;
      setState(() {
        _comments = (data as List)
            .map((e) => EpisodeComment.fromJson(e as Map<String, dynamic>))
            .toList();
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<void> _submit() async {
    final text = _controller.text.trim();
    if (text.isEmpty || text.length > 500) return;
    setState(() => _submitting = true);
    try {
      await Supabase.instance.client.functions.invoke(
        'post-episode-comment',
        body: {'episode_id': widget.episodeId, 'body': text},
      );
      _controller.clear();
      await _loadComments();
      ref.invalidate(commentCountProvider(widget.episodeId));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to post comment. Please try again.',
              style: GoogleFonts.sora(color: textCol),
            ),
            backgroundColor: surface,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _deleteComment(String commentId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: card,
        title: Text(
          'Delete comment?',
          style: GoogleFonts.nunito(color: textCol, fontWeight: FontWeight.w700),
        ),
        content: Text(
          'This cannot be undone.',
          style: GoogleFonts.sora(color: textSec, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel', style: GoogleFonts.sora(color: textDim)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              'Delete',
              style: GoogleFonts.sora(color: pink, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await Supabase.instance.client.functions.invoke(
        'delete-episode-comment',
        body: {'comment_id': commentId},
      );
      await _loadComments();
      ref.invalidate(commentCountProvider(widget.episodeId));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to delete comment. Please try again.',
              style: GoogleFonts.sora(color: textCol),
            ),
            backgroundColor: surface,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    return Container(
      height: screenHeight * 0.70,
      decoration: const BoxDecoration(
        color: bgDeep,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 10, bottom: 4),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                Text(
                  'Comments',
                  style: GoogleFonts.nunito(
                    color: textCol,
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close, color: textDim),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const Divider(color: border, height: 1),
          // Comment list
          Expanded(
            child: _loading
                ? _SkeletonList()
                : _comments.isEmpty
                    ? const Center(
                        child: Text(
                          'Be the first to comment 💬',
                          style: TextStyle(color: textDim, fontSize: 14),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(
                            vertical: 8, horizontal: 12),
                        itemCount: _comments.length,
                        itemBuilder: (ctx, i) => _CommentTile(
                          comment: _comments[i],
                          onDelete: _deleteComment,
                        ),
                      ),
          ),
          // Input row
          _InputRow(
            controller: _controller,
            submitting: _submitting,
            onSubmit: _submit,
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Skeleton loading tiles
// ---------------------------------------------------------------------------

class _SkeletonList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        3,
        (_) => Container(
          height: 56,
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: surface,
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Comment tile
// ---------------------------------------------------------------------------

class _CommentTile extends StatelessWidget {
  final EpisodeComment comment;
  final Future<void> Function(String) onDelete;

  const _CommentTile({required this.comment, required this.onDelete});

  String _relativeTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId =
        Supabase.instance.client.auth.currentUser?.id;
    final isOwn = comment.userId == currentUserId;
    final initials = (comment.username?.isNotEmpty == true)
        ? comment.username![0].toUpperCase()
        : '?';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: purpleDim,
            backgroundImage: comment.avatarUrl != null
                ? NetworkImage(comment.avatarUrl!)
                : null,
            child: comment.avatarUrl == null
                ? Text(
                    initials,
                    style: const TextStyle(
                      color: purple,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      comment.username ?? 'Anonymous',
                      style: const TextStyle(
                        color: textCol,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _relativeTime(comment.createdAt),
                      style: const TextStyle(color: textDim, fontSize: 11),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                if (comment.isDeleted)
                  const Text(
                    'This comment was removed.',
                    style: TextStyle(
                      color: textDim,
                      fontStyle: FontStyle.italic,
                      fontSize: 14,
                    ),
                  )
                else
                  Text(
                    comment.body,
                    style: const TextStyle(color: textSec, fontSize: 14),
                  ),
              ],
            ),
          ),
          if (isOwn && !comment.isDeleted)
            IconButton(
              icon: const Icon(
                Icons.delete_outline,
                color: textDim,
                size: 18,
              ),
              onPressed: () => onDelete(comment.id),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Input row
// ---------------------------------------------------------------------------

class _InputRow extends StatefulWidget {
  final TextEditingController controller;
  final bool submitting;
  final VoidCallback onSubmit;

  const _InputRow({
    required this.controller,
    required this.submitting,
    required this.onSubmit,
  });

  @override
  State<_InputRow> createState() => _InputRowState();
}

class _InputRowState extends State<_InputRow> {
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    final hasText = widget.controller.text.trim().isNotEmpty;
    if (hasText != _hasText) {
      setState(() => _hasText = hasText);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final canSend = _hasText && !widget.submitting;
    return Container(
      color: surface,
      padding: EdgeInsets.fromLTRB(
        12,
        8,
        8,
        MediaQuery.of(context).viewInsets.bottom + 8,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: TextField(
              controller: widget.controller,
              maxLines: 3,
              minLines: 1,
              maxLength: 500,
              style: GoogleFonts.sora(color: textCol, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Add a comment…',
                hintStyle: GoogleFonts.sora(color: textDim, fontSize: 14),
                filled: true,
                fillColor: card,
                counterText: '',
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 4),
          IconButton(
            icon: Icon(
              Icons.send_rounded,
              color: canSend ? purple : textDim,
            ),
            onPressed: canSend ? widget.onSubmit : null,
          ),
        ],
      ),
    );
  }
}
