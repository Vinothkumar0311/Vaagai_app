import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:http/http.dart' as http;

/// Google Drive upload via Google Apps Script proxy.
/// Chunks large files and tracks each chunk's Drive fileId for reliable reassembly.
class DriveUploadService {
  static const String _scriptUrl =
      'https://script.google.com/macros/s/AKfycbzc_YMcrZxzp7F5W7aZdqiYiv2t37iNeY-I9jF92FiTEej4mH_q9D_rAQBtvuY8t1v9/exec';

  // Max base64 chars per chunk (~900KB binary → safe under 2MB POST limit)
  static const int _chunkSize = 1200000;

  static Future<String> uploadFile({
    required File file,
    required String fileName,
    required String mimeType,
  }) async {
    final bytes = await file.readAsBytes();
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
    final client = http.Client();
    try {
      final request = http.Request('POST', Uri.parse(_scriptUrl))
        ..followRedirects = false
        ..body = json.encode(payload);

      final streamed = await client.send(request);
      final initial = await http.Response.fromStream(streamed);

      String responseBody;

      if (initial.statusCode == 302) {
        final location = initial.headers['location'];
        if (location == null) throw Exception('Redirect without location header');
        final redirected = await client.get(Uri.parse(location));
        responseBody = redirected.body;
      } else if (initial.statusCode == 200) {
        responseBody = initial.body;
      } else {
        throw Exception(
            'HTTP ${initial.statusCode}: ${initial.body.substring(0, min(300, initial.body.length))}');
      }

      final data = json.decode(responseBody) as Map<String, dynamic>;
      if (data['status'] != 'success') {
        throw Exception('Script error: ${data['message']}');
      }
      return data;
    } finally {
      client.close();
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
