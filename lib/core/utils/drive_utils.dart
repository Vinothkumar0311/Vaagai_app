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
      // Use the Next.js API proxy to avoid CORS and Google restrictions
      // NOTE: For absolute URLs in mobile, you should prepend your web domain here.
      // e.g. 'https://your-vaagai-web.vercel.app/api/drive-image?id=$fileId'
      return 'https://vaagai-mandram.vercel.app/api/drive-image?id=$fileId';
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
