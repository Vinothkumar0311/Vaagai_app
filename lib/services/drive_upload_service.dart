import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

/// Google Drive upload via Google Apps Script proxy.
/// Chunks large files and tracks each chunk's Drive fileId for reliable reassembly.
class DriveUploadService {
  static const String _scriptUrl =
      'https://script.google.com/macros/s/AKfycbzZMuGI_W5rmFeY1wCTsR1mAqjA0QZHtvpCnymvbKoNTScnKYkCTECYoTKEICwUaDJS/exec';

  // Max base64 chars per chunk (~900KB binary → safe under 2MB POST limit)
  static const int _chunkSize = 1200000;

  static Future<String> uploadFile({
    required Uint8List bytes,
    required String fileName,
    required String mimeType,
  }) async {
    final base64Str = base64Encode(bytes);

    _log('File: $fileName | ${bytes.length} bytes | base64: ${base64Str.length} chars');

    if (base64Str.length <= _chunkSize) {
      _log('Single-shot upload');
      return await _singleUpload(base64Str, mimeType, fileName);
    }

    _log('Chunked upload');
    return await _chunkedUpload(base64Str, mimeType, fileName);
  }

  // ── Single upload (small files) ────────────────────────────────────────────

  static Future<String> _singleUpload(
      String base64Str, String mimeType, String fileName) async {
    final result = await _post({
      'action': 'upload',
      'base64': base64Str,
      'mimeType': mimeType,
      'fileName': fileName,
    });
    return result['url'] as String;
  }

  // ── Chunked upload (large files) ───────────────────────────────────────────

  static Future<String> _chunkedUpload(
      String base64Str, String mimeType, String fileName) async {
    final uploadId = DateTime.now().millisecondsSinceEpoch.toRadixString(36);
    final totalChunks = (base64Str.length / _chunkSize).ceil();
    final fileIds = <String>[];

    _log('Uploading $totalChunks chunks [id=$uploadId]');

    for (var i = 0; i < totalChunks; i++) {
      final start = i * _chunkSize;
      final end = min(start + _chunkSize, base64Str.length);
      final chunk = base64Str.substring(start, end);

      _log('Chunk ${i + 1}/$totalChunks (${chunk.length} chars)');

      final result = await _post({
        'action': 'chunk',
        'id': uploadId,
        'index': i,
        'chunk': chunk,
      });

      // The script returns the Drive fileId of the saved chunk
      final fileId = result['fileId'] as String?;
      if (fileId == null || fileId.isEmpty) {
        throw Exception('Chunk ${i + 1} did not return a fileId');
      }
      fileIds.add(fileId);
      _log('Chunk ${i + 1} saved → fileId: $fileId');
    }

    _log('Finalizing with ${fileIds.length} chunk fileIds…');
    final result = await _post({
      'action': 'finalize',
      'fileIds': fileIds, // Pass IDs for direct lookup (avoids name-search bugs)
      'mimeType': mimeType,
      'fileName': fileName,
    });

    return result['url'] as String;
  }

  // ── HTTP helper ────────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> _post(Map<String, dynamic> payload) async {
    try {
      // Use simple http.post which auto-follows redirects on all platforms.
      // On web, the browser controls redirects so followRedirects=false breaks.
      // Use text/plain content-type to avoid CORS preflight (simple request),
      // since Google Apps Script does not send CORS headers for application/json POSTs.
      var response = await http.post(
        Uri.parse(_scriptUrl),
        headers: {'Content-Type': 'text/plain'},
        body: json.encode(payload),
      );

      _log('Response status: ${response.statusCode}');

      // Manually follow redirect if the HTTP client didn't do it automatically
      if (response.statusCode == 302 || response.statusCode == 303) {
        String? redirectUrl = response.headers['location'];
        if (redirectUrl == null || redirectUrl.isEmpty) {
          final match = RegExp(r'HREF="(.*?)"', caseSensitive: false).firstMatch(response.body);
          if (match != null) {
            redirectUrl = match.group(1);
          }
        }
        
        if (redirectUrl != null && redirectUrl.isNotEmpty) {
          _log('Following redirect...');
          response = await http.get(Uri.parse(redirectUrl));
          _log('Redirect response status: ${response.statusCode}');
        }
      }

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception(
            'HTTP ${response.statusCode}: ${response.body.substring(0, min(300, response.body.length))}');
      }

      final data = json.decode(response.body) as Map<String, dynamic>;
      if (data['status'] != 'success') {
        throw Exception('Script error: ${data['message']}');
      }
      return data;
    } catch (e) {
      _log('Error: $e');
      rethrow;
    }
  }

  // ── Utilities ──────────────────────────────────────────────────────────────

  static String mimeTypeFrom(String fileName) {
    switch (fileName.split('.').last.toLowerCase()) {
      case 'pdf': return 'application/pdf';
      case 'png': return 'image/png';
      case 'jpg':
      case 'jpeg': return 'image/jpeg';
      default: return 'application/octet-stream';
    }
  }

  // ignore: avoid_print
  static void _log(String msg) => print('[DriveUpload] $msg');
}
