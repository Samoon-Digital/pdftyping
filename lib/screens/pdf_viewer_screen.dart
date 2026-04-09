import 'dart:io';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import '../services/ad_service.dart';

class PdfViewerScreen extends StatefulWidget {
  final File file;
  final String title;

  const PdfViewerScreen({super.key, required this.file, required this.title});

  @override
  State<PdfViewerScreen> createState() => _PdfViewerScreenState();
}

class _PdfViewerScreenState extends State<PdfViewerScreen> {
  final _viewerKey = GlobalKey<SfPdfViewerState>();

  @override
  void initState() {
    super.initState();
    AdService.instance.pushAppOpenSuppression();
  }

  @override
  void dispose() {
    AdService.instance.popAppOpenSuppression();
    super.dispose();
  }

  Future<void> _share() async {
    final bytes = await widget.file.readAsBytes();
    await Printing.sharePdf(bytes: bytes, filename: '${widget.title}.pdf');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2B2B2B),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 1,
        // Back button — left side
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back_rounded),
          tooltip: 'वापस जाएं',
        ),
        title: Text(
          widget.title,
          style: const TextStyle(
            fontFamily: 'NotoSansDevanagari',
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Color(0xFF212121),
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        // Share button — right side
        actions: [
          IconButton(
            onPressed: _share,
            icon: const Icon(Icons.share_rounded),
            tooltip: 'Share',
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SfPdfViewer.file(
        widget.file,
        key: _viewerKey,
        canShowScrollHead: true,
        canShowScrollStatus: true,
        canShowPaginationDialog: true,
        enableDoubleTapZooming: true,
        enableTextSelection: false,
        onDocumentLoadFailed: (PdfDocumentLoadFailedDetails details) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('PDF load नहीं हो सकी: ${details.error}'),
              backgroundColor: Colors.red.shade700,
            ),
          );
        },
      ),
    );
  }
}
