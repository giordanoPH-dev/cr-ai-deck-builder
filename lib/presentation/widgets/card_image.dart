import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import 'skeleton_widgets.dart';

class CardImage extends StatelessWidget {
  final String url;
  final String? cardName;
  final double? size;
  final BoxFit fit;

  const CardImage({
    super.key,
    required this.url,
    this.cardName,
    this.size,
    this.fit = BoxFit.contain,
  });

  @override
  Widget build(BuildContext context) {
    if (url.isEmpty) {
      return _placeholder();
    }

    return Image.network(
      url,
      fit: fit,
      width: size,
      height: size,
      loadingBuilder: (_, child, progress) {
        if (progress == null) return child;
        return ShimmerBox(width: size ?? 40, height: size ?? 40, borderRadius: 6);
      },
      errorBuilder: (context, error, stackTrace) {
        debugPrint(
          '[CardImage] ERRO ao carregar — card: $cardName | url: $url | erro: $error',
        );
        return _placeholder();
      },
    );
  }

  Widget _placeholder() {
    final initials = cardName != null && cardName!.isNotEmpty
        ? cardName![0].toUpperCase()
        : '?';
    return Center(
      child: Text(
        initials,
        style: TextStyle(
          color: AppColors.textDisabled,
          fontSize: (size ?? 24) * 0.4,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
