import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

/// Image helper with caching and CDN support
class ImageHelper {
  // CDN base URL (Firebase Storage veya başka CDN)
  static const String _cdnBaseUrl = 'https://firebasestorage.googleapis.com';
  
  /// Cached network image widget
  static Widget cachedImage(
    String imageUrl, {
    BoxFit fit = BoxFit.cover,
    double? width,
    double? height,
    Widget? placeholder,
    Widget? errorWidget,
    BorderRadius? borderRadius,
  }) {
    final widget = CachedNetworkImage(
      imageUrl: _getCdnUrl(imageUrl),
      fit: fit,
      width: width,
      height: height,
      placeholder: (context, url) =>
          placeholder ??
          Container(
            color: Colors.grey.shade200,
            child: const Center(
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
      errorWidget: (context, url, error) =>
          errorWidget ??
          Container(
            color: Colors.grey.shade200,
            child: const Icon(Icons.error_outline, color: Colors.grey),
          ),
      memCacheWidth: width?.toInt(),
      memCacheHeight: height?.toInt(),
      maxWidthDiskCache: 1000,
      maxHeightDiskCache: 1000,
    );

    if (borderRadius != null) {
      return ClipRRect(
        borderRadius: borderRadius,
        child: widget,
      );
    }

    return widget;
  }

  /// Avatar image (circular)
  static Widget avatar(
    String? imageUrl, {
    double size = 40,
    String? fallbackText,
    Color? backgroundColor,
  }) {
    if (imageUrl == null || imageUrl.isEmpty) {
      return CircleAvatar(
        radius: size / 2,
        backgroundColor: backgroundColor ?? Colors.blue,
        child: Text(
          fallbackText?.substring(0, 1).toUpperCase() ?? '?',
          style: TextStyle(
            color: Colors.white,
            fontSize: size / 2,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }

    return ClipOval(
      child: CachedNetworkImage(
        imageUrl: _getCdnUrl(imageUrl),
        width: size,
        height: size,
        fit: BoxFit.cover,
        placeholder: (context, url) => CircleAvatar(
          radius: size / 2,
          backgroundColor: Colors.grey.shade200,
          child: const CircularProgressIndicator(strokeWidth: 2),
        ),
        errorWidget: (context, url, error) => CircleAvatar(
          radius: size / 2,
          backgroundColor: backgroundColor ?? Colors.blue,
          child: Text(
            fallbackText?.substring(0, 1).toUpperCase() ?? '?',
            style: TextStyle(
              color: Colors.white,
              fontSize: size / 2,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        memCacheWidth: size.toInt(),
        memCacheHeight: size.toInt(),
      ),
    );
  }

  /// Thumbnail image (küçük boyut, optimize)
  static Widget thumbnail(
    String imageUrl, {
    double size = 80,
    BoxFit fit = BoxFit.cover,
    BorderRadius? borderRadius,
  }) {
    return cachedImage(
      imageUrl,
      width: size,
      height: size,
      fit: fit,
      borderRadius: borderRadius,
    );
  }

  /// Hero image (büyük boyut, yüksek kalite)
  static Widget hero(
    String imageUrl, {
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
  }) {
    return CachedNetworkImage(
      imageUrl: _getCdnUrl(imageUrl),
      width: width,
      height: height,
      fit: fit,
      placeholder: (context, url) => Container(
        color: Colors.grey.shade200,
        child: const Center(
          child: CircularProgressIndicator(strokeWidth: 3),
        ),
      ),
      errorWidget: (context, url, error) => Container(
        color: Colors.grey.shade200,
        child: const Icon(Icons.broken_image, size: 48, color: Colors.grey),
      ),
      // Yüksek kalite için cache boyutlarını artır
      maxWidthDiskCache: 2000,
      maxHeightDiskCache: 2000,
    );
  }

  /// CDN URL'ini döndür
  static String _getCdnUrl(String url) {
    // Eğer zaten CDN URL'i ise direkt döndür
    if (url.startsWith('http')) {
      return url;
    }

    // Firebase Storage path'i ise CDN URL'e çevir
    return '$_cdnBaseUrl/$url';
  }

  /// Precache images (önceden yükle)
  static Future<void> precacheImages(
    BuildContext context,
    List<String> imageUrls,
  ) async {
    for (final url in imageUrls) {
      await precacheImage(
        CachedNetworkImageProvider(_getCdnUrl(url)),
        context,
      );
    }
  }

  /// Clear image cache
  static Future<void> clearCache() async {
    await CachedNetworkImage.evictFromCache('');
  }

  /// Get cache size (debug için)
  static Future<int> getCacheSize() async {
    // CachedNetworkImage cache size'ı almak için
    // Not: Bu özellik direkt desteklenmiyor, manuel hesaplama gerekebilir
    return 0;
  }
}

/// Image placeholder widget
class ImagePlaceholder extends StatelessWidget {
  final double? width;
  final double? height;
  final IconData icon;

  const ImagePlaceholder({
    super.key,
    this.width,
    this.height,
    this.icon = Icons.image_outlined,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      color: Colors.grey.shade200,
      child: Icon(
        icon,
        size: 48,
        color: Colors.grey.shade400,
      ),
    );
  }
}
