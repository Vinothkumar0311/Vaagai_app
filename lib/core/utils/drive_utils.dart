// No imports needed for this utility class

class DriveUtils {
  /// Transforms a Google Drive link into a direct view/download URL.
  /// Handles /file/d/ID/view, open?id=ID, and direct ID formats.
  static String? getDirectViewUrl(String? originalUrl) {
    if (originalUrl == null || originalUrl.isEmpty) return null;
    
    // If it's already a proxied link, keep it
    if (originalUrl.contains('/api/drive-image')) return originalUrl;
    
    String? fileId;

    if (originalUrl.contains('/file/d/')) {
      final match = RegExp(r'/d/([a-zA-Z0-9_-]+)').firstMatch(originalUrl);
      if (match != null) fileId = match.group(1);
    } else if (originalUrl.contains('id=')) {
      final match = RegExp(r'id=([a-zA-Z0-9_-]+)').firstMatch(originalUrl);
      if (match != null) fileId = match.group(1);
    } else if (RegExp(r'^[a-zA-Z0-9_-]{25,}$').hasMatch(originalUrl)) {
      // It looks like a raw Drive ID
      fileId = originalUrl;
    }

    if (fileId != null) {
      // Use Google's native thumbnail service for reliable image rendering
      return 'https://drive.google.com/thumbnail?id=$fileId&sz=w400';
    }

    return originalUrl;
  }


  /// Transforms a Google Drive link into a direct download URL.
  static String? getDirectDownloadUrl(String? originalUrl) {
    if (originalUrl == null || originalUrl.isEmpty) return null;
    
    String? fileId;

    if (originalUrl.contains('/file/d/')) {
      final match = RegExp(r'/d/([a-zA-Z0-9_-]+)').firstMatch(originalUrl);
      if (match != null) fileId = match.group(1);
    } else if (originalUrl.contains('id=')) {
      final match = RegExp(r'id=([a-zA-Z0-9_-]+)').firstMatch(originalUrl);
      if (match != null) fileId = match.group(1);
    } else if (RegExp(r'^[a-zA-Z0-9_-]{25,}$').hasMatch(originalUrl)) {
      // It looks like a raw Drive ID
      fileId = originalUrl;
    }

    if (fileId != null) {
      return 'https://drive.google.com/uc?export=download&id=$fileId';
    }

    return originalUrl;
  }
}
