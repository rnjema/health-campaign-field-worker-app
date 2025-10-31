import 'dart:convert';
import 'dart:io';
import 'package:flutter_image_compress/flutter_image_compress.dart';

/// Utility class for image compression
class ImageCompressionUtils {
  /// Compresses an image file and returns base64 string
  ///
  /// [file] - The image file to compress
  /// [maxWidth] - Maximum width of the compressed image (default: 1920)
  /// [maxHeight] - Maximum height of the compressed image (default: 1920)
  /// [quality] - Compression quality 0-100 (default: 85)
  ///
  /// Returns a Map with 'name' and 'data' (base64 string)
  static Future<Map<String, String>> compressAndEncode(
    File file, {
    int maxWidth = 1920,
    int maxHeight = 1920,
    int quality = 85,
  }) async {
    try {
      // Get the file name
      final fileName = file.path.split('/').last;

      // Compress the image
      final compressedBytes = await FlutterImageCompress.compressWithFile(
        file.absolute.path,
        minWidth: maxWidth,
        minHeight: maxHeight,
        quality: quality,
      );

      if (compressedBytes == null) {
        throw Exception('Image compression failed');
      }

      // Convert to base64
      final base64String = base64Encode(compressedBytes);

      // Get file extension to determine MIME type
      final extension = fileName.split('.').last.toLowerCase();
      final mimeType = _getMimeType(extension);

      // Return with data URL format
      return {
        'name': fileName,
        'data': 'data:$mimeType;base64,$base64String',
      };
    } catch (e) {
      throw Exception('Failed to compress image: $e');
    }
  }

  /// Compresses multiple image files
  ///
  /// Returns a List of Maps containing name and base64 data
  static Future<List<Map<String, String>>> compressMultiple(
    List<File> files, {
    int maxWidth = 1920,
    int maxHeight = 1920,
    int quality = 85,
  }) async {
    final List<Map<String, String>> compressedImages = [];

    for (final file in files) {
      try {
        final compressed = await compressAndEncode(
          file,
          maxWidth: maxWidth,
          maxHeight: maxHeight,
          quality: quality,
        );
        compressedImages.add(compressed);
      } catch (e) {
        // Log error but continue with other images
        print('Error compressing ${file.path}: $e');
      }
    }

    return compressedImages;
  }

  /// Determines MIME type from file extension
  static String _getMimeType(String extension) {
    switch (extension) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'webp':
        return 'image/webp';
      case 'bmp':
        return 'image/bmp';
      default:
        return 'image/jpeg'; // Default fallback
    }
  }

  /// Estimates the size of the base64 string in KB
  static double estimateBase64Size(String base64String) {
    // Remove data URL prefix if present
    final data = base64String.contains(',')
        ? base64String.split(',')[1]
        : base64String;

    // Base64 encoding increases size by ~33%, but we're calculating the string size
    return (data.length / 1024);
  }

  /// Validates if the compressed image is under the size limit
  ///
  /// [base64String] - The base64 encoded string
  /// [maxSizeKB] - Maximum allowed size in KB (default: 1024 KB = 1 MB)
  ///
  /// Returns true if under limit, false otherwise
  static bool isUnderSizeLimit(String base64String, {int maxSizeKB = 1024}) {
    final sizeKB = estimateBase64Size(base64String);
    return sizeKB <= maxSizeKB;
  }
}
