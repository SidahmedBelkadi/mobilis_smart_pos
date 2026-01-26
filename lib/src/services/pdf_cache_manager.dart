import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

/// Custom cache manager for PDFs that persists across app restarts
/// Only clears when user logs out
class PdfCacheManager {
  static const String cacheKey = 'pdf_cache';
  static CacheManager? _instance;

  /// Get the singleton cache manager instance
  static CacheManager get instance {
    _instance ??= CacheManager(
      Config(
        cacheKey,
        stalePeriod: const Duration(days: 365), // Keep for 1 year
        maxNrOfCacheObjects: 100, // Max 100 PDFs
        repo: JsonCacheInfoRepository(databaseName: cacheKey),
        fileService: HttpFileService(),
      ),
    );
    return _instance!;
  }

  /// Generate a unique cache key for each PDF
  static String _getCacheKey(String offerName, String lang) {
    return 'pdf_${offerName}_$lang';
  }

  /// Get PDF from cache if it exists
  static Future<Uint8List?> getCachedPdf({
    required String offerName,
    required String lang,
  }) async {
    try {
      final key = _getCacheKey(offerName, lang);
      final fileInfo = await instance.getFileFromCache(key);

      if (fileInfo != null && fileInfo.file.existsSync()) {
        final bytes = await fileInfo.file.readAsBytes();
        debugPrint('PDF Cache HIT for $key (${bytes.length} bytes)');
        return bytes;
      }

      debugPrint('PDF Cache MISS for $key');
      return null;
    } catch (e) {
      debugPrint('Error reading cached PDF: $e');
      return null;
    }
  }

  /// Cache a PDF to disk
  static Future<void> cachePdf({
    required String offerName,
    required String lang,
    required Uint8List pdfBytes,
  }) async {
    try {
      final key = _getCacheKey(offerName, lang);

      // Get temp directory to save the file
      final tempDir = await getTemporaryDirectory();
      final filePath = path.join(tempDir.path, '$key.pdf');
      final file = File(filePath);

      // Write the PDF bytes to file
      await file.writeAsBytes(pdfBytes);

      // Put file in cache manager
      await instance.putFile(
        key,
        pdfBytes,
        maxAge: const Duration(days: 365),
        fileExtension: 'pdf',
      );

      debugPrint('PDF cached for $key (${pdfBytes.length} bytes)');
    } catch (e) {
      debugPrint('Error caching PDF: $e');
    }
  }

  /// Check if a specific PDF is cached
  static Future<bool> isCached({
    required String offerName,
    required String lang,
  }) async {
    try {
      final key = _getCacheKey(offerName, lang);
      final fileInfo = await instance.getFileFromCache(key);
      return fileInfo != null && fileInfo.file.existsSync();
    } catch (e) {
      debugPrint('Error checking cache: $e');
      return false;
    }
  }

  /// Clear all cached PDFs (call on logout)
  static Future<void> clearCache() async {
    try {
      await instance.emptyCache();
      debugPrint('PDF cache cleared completely');
    } catch (e) {
      debugPrint('Error clearing PDF cache: $e');
    }
  }

  /// Clear a specific PDF from cache
  static Future<void> clearSpecificPdf({
    required String offerName,
    required String lang,
  }) async {
    try {
      final key = _getCacheKey(offerName, lang);
      await instance.removeFile(key);
      debugPrint('Cleared cached PDF for $key');
    } catch (e) {
      debugPrint('Error clearing specific PDF: $e');
    }
  }

  /// Get cache statistics
  static Future<Map<String, dynamic>> getCacheStats() async {
    try {
      final cacheInfo = await instance.getFileFromCache(cacheKey);
      final cacheDir = await getTemporaryDirectory();

      return {
        'cacheExists': cacheInfo != null,
        'cachePath': cacheDir.path,
      };
    } catch (e) {
      debugPrint('Error getting cache stats: $e');
      return {};
    }
  }
}
