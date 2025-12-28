import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

/// Transparent 1x1 pixel PNG for placeholder
final Uint8List kTransparentImage = Uint8List.fromList([
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D,
  0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
  0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00, 0x00, 0x00,
  0x0A, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
  0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00, 0x00, 0x00, 0x00, 0x49,
  0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82,
]);

/// 🖼️ Image Caching Utility
/// Memory-optimized resim yükleme için helper fonksiyonlar
/// 
/// Kullanım:
/// ImageUtils.cachedAsset('assets/images/logo.png', width: 100, height: 100)
/// ImageUtils.cachedNetwork('https://...', width: 200)
class ImageUtils {
  /// Memory-optimized asset image
  /// cacheWidth/cacheHeight ile decode boyutu sınırlanır
  static Widget cachedAsset(
    String assetPath, {
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
    Color? color,
  }) {
    // Decode boyutunu hesapla (2x pixel density için)
    final cacheWidth = width != null ? (width * 2).toInt() : null;
    final cacheHeight = height != null ? (height * 2).toInt() : null;
    
    return Image.asset(
      assetPath,
      width: width,
      height: height,
      fit: fit,
      color: color,
      cacheWidth: cacheWidth,
      cacheHeight: cacheHeight,
      filterQuality: FilterQuality.medium,
    );
  }
  
  /// Memory-optimized network image with caching
  static Widget cachedNetwork(
    String imageUrl, {
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
    Widget? placeholder,
    Widget? errorWidget,
    int? memCacheWidth,
    int? memCacheHeight,
  }) {
    // Memory cache boyutu (2x pixel density)
    final cacheWidth = memCacheWidth ?? (width != null ? (width * 2).toInt() : null);
    final cacheHeight = memCacheHeight ?? (height != null ? (height * 2).toInt() : null);
    
    return CachedNetworkImage(
      imageUrl: imageUrl,
      width: width,
      height: height,
      fit: fit,
      memCacheWidth: cacheWidth,
      memCacheHeight: cacheHeight,
      placeholder: (context, url) => placeholder ?? _buildShimmer(width, height),
      errorWidget: (context, url, error) => errorWidget ?? _buildErrorWidget(width, height),
      fadeInDuration: const Duration(milliseconds: 200),
      fadeOutDuration: const Duration(milliseconds: 200),
    );
  }
  
  /// Shimmer placeholder
  static Widget _buildShimmer(double? width, double? height) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }
  
  /// Error widget
  static Widget _buildErrorWidget(double? width, double? height) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        Icons.broken_image_outlined,
        color: Colors.grey.shade400,
        size: (width ?? 48) * 0.4,
      ),
    );
  }
  
  /// FadeInImage - smooth fade-in for network images
  static Widget fadeInNetwork(
    String imageUrl, {
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
    Duration fadeInDuration = const Duration(milliseconds: 300),
  }) {
    return FadeInImage.memoryNetwork(
      placeholder: kTransparentImage,
      image: imageUrl,
      width: width,
      height: height,
      fit: fit,
      fadeInDuration: fadeInDuration,
      fadeOutDuration: const Duration(milliseconds: 100),
      imageErrorBuilder: (context, error, stackTrace) => _buildErrorWidget(width, height),
    );
  }
  
  /// FadeInImage - smooth fade-in for asset images
  static Widget fadeInAsset(
    String assetPath, {
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
    Duration fadeInDuration = const Duration(milliseconds: 200),
  }) {
    return FadeInImage(
      placeholder: MemoryImage(kTransparentImage),
      image: AssetImage(assetPath),
      width: width,
      height: height,
      fit: fit,
      fadeInDuration: fadeInDuration,
      fadeOutDuration: const Duration(milliseconds: 100),
      imageErrorBuilder: (context, error, stackTrace) => _buildErrorWidget(width, height),
    );
  }
  
  /// Precache images for faster loading
  static Future<void> precacheImages(BuildContext context, List<String> assetPaths) async {
    for (final path in assetPaths) {
      await precacheImage(AssetImage(path), context);
    }
  }
  
  /// Avatar widget with fallback
  static Widget avatar({
    String? imageUrl,
    String? fallbackText,
    double size = 40,
    Color? backgroundColor,
  }) {
    if (imageUrl != null && imageUrl.isNotEmpty) {
      return ClipOval(
        child: cachedNetwork(
          imageUrl,
          width: size,
          height: size,
          fit: BoxFit.cover,
        ),
      );
    }
    
    // Fallback: İlk harf veya ikon
    final initial = fallbackText?.isNotEmpty == true 
        ? fallbackText![0].toUpperCase() 
        : '?';
    
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.indigo.shade100,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          initial,
          style: TextStyle(
            fontSize: size * 0.4,
            fontWeight: FontWeight.w600,
            color: Colors.indigo.shade700,
          ),
        ),
      ),
    );
  }
}
