import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kpss_2026/core/theme/app_colors.dart';
import '../cubit/quiz_cubit.dart';

class FavoriteButton extends StatefulWidget {
  final String questionId;

  const FavoriteButton({super.key, required this.questionId});

  @override
  State<FavoriteButton> createState() => _FavoriteButtonState();
}

class _FavoriteButtonState extends State<FavoriteButton> {
  bool _isFavorite = false;

  @override
  void initState() {
    super.initState();
    _checkStatus();
  }

  @override
  void didUpdateWidget(FavoriteButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.questionId != widget.questionId) {
      _checkStatus();
    }
  }

  Future<void> _checkStatus() async {
    if (!mounted) return;
    final isFav = await context.read<QuizCubit>().checkFavoriteStatus(widget.questionId);
    if (mounted) setState(() => _isFavorite = isFav);
  }

  Future<void> _toggle() async {
    setState(() => _isFavorite = !_isFavorite);
    await context.read<QuizCubit>().toggleFavorite(widget.questionId);
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(
        _isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
        color: _isFavorite ? Colors.red : const Color(0xFF6B7280),
        size: 24,
      ),
      onPressed: _toggle,
      style: IconButton.styleFrom(
        backgroundColor: AppColors.background,
      ),
    );
  }
}
