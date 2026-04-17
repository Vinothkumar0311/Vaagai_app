import 'dart:io';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;

class PdfViewerScreen extends StatefulWidget {
  final String pdfUrl;
  final String title;

  const PdfViewerScreen({super.key, required this.pdfUrl, required this.title});

  @override
  State<PdfViewerScreen> createState() => _PdfViewerScreenState();
}

class _PdfViewerScreenState extends State<PdfViewerScreen> {
  bool _isDownloading = false;

  Future<void> _downloadPdf() async {
    setState(() {
      _isDownloading = true;
    });

    try {
      final response = await http.get(Uri.parse(widget.pdfUrl));
      if (response.statusCode == 200) {
        final bytes = response.bodyBytes;
        final dir = await getApplicationDocumentsDirectory();
        
        // Clean filename
        String fileName = widget.title.replaceAll(RegExp(r'[^\w\s\.-]'), '_');
        if (!fileName.toLowerCase().endsWith('.pdf')) {
          fileName += '.pdf';
        }
        
        final file = File('${dir.path}/$fileName');
        await file.writeAsBytes(bytes);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Downloaded to: ${file.path}'),
              backgroundColor: const Color(0xFF1B5E20),
            ),
          );
        }
      } else {
        throw Exception('Failed to download file');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Download failed: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isDownloading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryGreen = Color(0xFF1B5E20);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        backgroundColor: Colors.white,
        foregroundColor: primaryGreen,
        elevation: 0.5,
        actions: [
          _isDownloading
              ? const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: primaryGreen),
                  ),
                )
              : IconButton(
                  icon: const Icon(Icons.download_rounded),
                  onPressed: _downloadPdf,
                  tooltip: 'Download PDF',
                ),
        ],
      ),
      body: SfPdfViewer.network(
        widget.pdfUrl,
        canShowScrollHead: false,
        canShowScrollStatus: false,
        enableDocumentLinkAnnotation: false,
        enableTextSelection: false,
        onDocumentLoadFailed: (PdfDocumentLoadFailedDetails details) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to load PDF: ${details.description}'), backgroundColor: Colors.red),
          );
        },
      ),
    );
  }
}
