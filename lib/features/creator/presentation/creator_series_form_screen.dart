import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/tokens.dart';
import '../application/creator_series_provider.dart';

const _genres = [
  'Romance',
  'Thriller',
  'Comedy',
  'Drama',
  'Action',
  'Mystery',
];

class CreatorSeriesFormScreen extends ConsumerStatefulWidget {
  final String? seriesId;
  const CreatorSeriesFormScreen({super.key, this.seriesId});

  @override
  ConsumerState<CreatorSeriesFormScreen> createState() =>
      _CreatorSeriesFormScreenState();
}

class _CreatorSeriesFormScreenState
    extends ConsumerState<CreatorSeriesFormScreen> {
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _coverUrlCtrl = TextEditingController();
  String _genre = _genres.first;
  bool _loading = false;
  bool _initialized = false;

  bool get _isEdit => widget.seriesId != null;

  @override
  void initState() {
    super.initState();
    if (_isEdit) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        final data = await ref
            .read(creatorSeriesRepositoryProvider)
            .fetchSeriesById(widget.seriesId!);
        if (data != null && mounted && !_initialized) {
          _initialized = true;
          setState(() {
            _titleCtrl.text = data['title'] as String? ?? '';
            _descCtrl.text = data['description'] as String? ?? '';
            _coverUrlCtrl.text = data['cover_url'] as String? ?? '';
            final g = data['genre'] as String? ?? '';
            if (_genres.contains(g)) _genre = g;
          });
        }
      });
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _coverUrlCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final title = _titleCtrl.text.trim();
    if (title.isEmpty) {
      _showSnack('Title is required', isError: true);
      return;
    }
    setState(() => _loading = true);
    try {
      final repo = ref.read(creatorSeriesRepositoryProvider);
      final coverUrl = _coverUrlCtrl.text.trim();
      if (_isEdit) {
        await repo.updateSeries(
          widget.seriesId!,
          title: title,
          description: _descCtrl.text.trim(),
          genre: _genre,
          coverUrl: coverUrl.isNotEmpty ? coverUrl : null,
        );
      } else {
        await repo.createSeries(
          title: title,
          description: _descCtrl.text.trim(),
          genre: _genre,
          coverUrl: coverUrl.isNotEmpty ? coverUrl : null,
        );
      }
      ref.invalidate(mySeriesProvider);
      if (mounted) context.pop();
    } catch (e) {
      if (mounted) {
        _showSnack(e.toString().replaceFirst('Exception: ', ''),
            isError: true);
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: GoogleFonts.sora(color: textCol)),
      backgroundColor: isError ? lava : surface,
      behavior: SnackBarBehavior.floating,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final coverUrl = _coverUrlCtrl.text.trim();

    return Scaffold(
      backgroundColor: bgDeep,
      appBar: AppBar(
        backgroundColor: bgDeep,
        elevation: 0,
        leading: BackButton(color: textCol),
        title: Text(
          _isEdit ? 'Edit Series' : 'New Series',
          style: GoogleFonts.nunito(
              color: textCol, fontWeight: FontWeight.w800, fontSize: 20),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
        children: [
          // Cover preview
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: coverUrl.isNotEmpty
                ? Image.network(
                    coverUrl,
                    height: 120,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _coverPlaceholder(),
                  )
                : _coverPlaceholder(),
          ),
          const SizedBox(height: 16),

          _label('Title'),
          const SizedBox(height: 8),
          _textField(_titleCtrl, hint: 'Series title'),
          const SizedBox(height: 16),

          _label('Description'),
          const SizedBox(height: 8),
          _textField(_descCtrl, hint: 'What is this series about?', maxLines: 3),
          const SizedBox(height: 16),

          _label('Genre'),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _genre,
            dropdownColor: card,
            style: GoogleFonts.sora(color: textCol, fontSize: 15),
            decoration: _inputDecoration('Genre'),
            items: _genres
                .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                .toList(),
            onChanged: (v) {
              if (v != null) setState(() => _genre = v);
            },
          ),
          const SizedBox(height: 16),

          _label('Cover Image URL (optional)'),
          const SizedBox(height: 8),
          TextField(
            controller: _coverUrlCtrl,
            keyboardType: TextInputType.url,
            style: GoogleFonts.sora(color: textCol, fontSize: 15),
            decoration: _inputDecoration('https://…'),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 32),

          GestureDetector(
            onTap: _loading ? null : _save,
            child: Container(
              height: 52,
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: _loading ? null : goldGrad,
                color: _loading ? card : null,
                borderRadius: BorderRadius.circular(26),
              ),
              alignment: Alignment.center,
              child: _loading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                          color: textCol, strokeWidth: 2))
                  : Text(
                      _isEdit ? 'Save Changes' : 'Create Series',
                      style: GoogleFonts.nunito(
                          color: textCol,
                          fontWeight: FontWeight.w800,
                          fontSize: 16),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _coverPlaceholder() {
    return Container(
      height: 120,
      width: double.infinity,
      color: surface,
      child: const Icon(Icons.image_outlined, color: textDim, size: 40),
    );
  }

  Widget _label(String text) => Text(
        text,
        style: GoogleFonts.sora(color: textSec, fontSize: 12),
      );

  Widget _textField(TextEditingController ctrl,
          {String hint = '', int maxLines = 1}) =>
      TextField(
        controller: ctrl,
        maxLines: maxLines,
        style: GoogleFonts.sora(color: textCol, fontSize: 15),
        decoration: _inputDecoration(hint),
      );

  InputDecoration _inputDecoration(String hint) => InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.sora(color: textDim, fontSize: 15),
        filled: true,
        fillColor: surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: cyan, width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      );
}
