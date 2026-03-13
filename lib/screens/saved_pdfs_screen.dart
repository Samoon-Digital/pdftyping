import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';

class SavedPdfsScreen extends StatefulWidget {
  const SavedPdfsScreen({super.key});

  @override
  State<SavedPdfsScreen> createState() => _SavedPdfsScreenState();
}

class _SavedPdfsScreenState extends State<SavedPdfsScreen> {
  List<File> _pdfs = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadPdfs();
  }

  Future<void> _loadPdfs() async {
    setState(() => _loading = true);
    final dir = await getApplicationDocumentsDirectory();
    final files =
        dir
            .listSync()
            .whereType<File>()
            .where((f) => f.path.endsWith('.pdf'))
            .toList()
          ..sort(
            (a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()),
          );
    setState(() {
      _pdfs = files;
      _loading = false;
    });
  }

  Future<void> _deletePdf(File file) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('PDF हटाएं?'),
        content: Text(
          '${_fileName(file)} को हमेशा के लिए हटा दिया जाएगा।',
          style: const TextStyle(fontFamily: 'NotoSansDevanagari'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('रद्द करें'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('हटाएं', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await file.delete();
      _loadPdfs();
    }
  }

  Future<void> _openPdf(File file) async {
    final bytes = await file.readAsBytes();
    await Printing.layoutPdf(
      onLayout: (_) async => bytes,
      name: _fileName(file),
    );
  }

  String _fileName(File file) =>
      file.path.split(Platform.pathSeparator).last.replaceAll('.pdf', '');

  String _formatDate(File file) {
    final dt = file.lastModifiedSync();
    return '${dt.day.toString().padLeft(2, '0')}/'
        '${dt.month.toString().padLeft(2, '0')}/'
        '${dt.year}  '
        '${dt.hour.toString().padLeft(2, '0')}:'
        '${dt.minute.toString().padLeft(2, '0')}';
  }

  String _fileSize(File file) {
    final bytes = file.lengthSync();
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Saved PDFs'),
        actions: [
          IconButton(
            onPressed: _loadPdfs,
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _pdfs.isEmpty
          ? _buildEmpty()
          : RefreshIndicator(
              onRefresh: _loadPdfs,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                itemCount: _pdfs.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (_, i) => _PdfCard(
                  file: _pdfs[i],
                  name: _fileName(_pdfs[i]),
                  date: _formatDate(_pdfs[i]),
                  size: _fileSize(_pdfs[i]),
                  onOpen: () => _openPdf(_pdfs[i]),
                  onDelete: () => _deletePdf(_pdfs[i]),
                ),
              ),
            ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.bookmark_border_rounded,
            size: 72,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            'कोई PDF सेव नहीं है',
            style: TextStyle(
              fontFamily: 'NotoSansDevanagari',
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'आवेदन एडिटर से PDF बनाएं,\nवो यहाँ दिखेगी।',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'NotoSansDevanagari',
              fontSize: 14,
              color: Colors.grey.shade400,
            ),
          ),
        ],
      ),
    );
  }
}

class _PdfCard extends StatelessWidget {
  final File file;
  final String name;
  final String date;
  final String size;
  final VoidCallback onOpen;
  final VoidCallback onDelete;

  const _PdfCard({
    required this.file,
    required this.name,
    required this.date,
    required this.size,
    required this.onOpen,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      elevation: 1,
      shadowColor: Colors.black.withValues(alpha: 0.08),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onOpen,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFEBEE),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.picture_as_pdf_rounded,
                  color: Color(0xFFE53935),
                  size: 26,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontFamily: 'NotoSansDevanagari',
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF212121),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.access_time_rounded,
                          size: 12,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          date,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade500,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          size,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade400,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline_rounded),
                color: Colors.grey.shade400,
                tooltip: 'हटाएं',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
