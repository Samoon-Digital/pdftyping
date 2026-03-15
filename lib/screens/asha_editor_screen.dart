import 'dart:ui' as ui;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../services/pdf_saver.dart';
import '../widgets/suggestible_input_field.dart';
import '../widgets/pdf_generation_widgets.dart';

class AshaEditorScreen extends StatefulWidget {
  final VoidCallback? onPdfSaved;
  const AshaEditorScreen({super.key, this.onPdfSaved});

  @override
  State<AshaEditorScreen> createState() => _AshaEditorScreenState();
}

class _AshaEditorScreenState extends State<AshaEditorScreen> {
  final _nameCtrl = TextEditingController();
  final _gramCtrl = TextEditingController();
  final _postCtrl = TextEditingController();
  final _vikasKhandCtrl = TextEditingController();
  final _tehsilCtrl = TextEditingController();
  final _jilaCtrl = TextEditingController();
  final _birthDateCtrl = TextEditingController();
  final _janmGramCtrl = TextEditingController();
  final _dateCtrl = TextEditingController();

  final _formKey = GlobalKey<FormState>();
  bool _janmGramManuallyEdited = false;
  int _step = 0;

  @override
  void initState() {
    super.initState();
    // Auto-fill जन्म का ग्राम from निवासी ग्राम unless manually edited
    _gramCtrl.addListener(() {
      if (!_janmGramManuallyEdited) {
        final val = _gramCtrl.text;
        if (_janmGramCtrl.text != val) {
          _janmGramCtrl.text = val;
          setState(() {});
        }
      }
    });
    // Auto-fill today's date
    final now = DateTime.now();
    _dateCtrl.text =
        '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}';
  }

  Future<void> _pickBirthDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(1950),
      lastDate: DateTime(2100),
      locale: const Locale('hi', 'IN'),
    );
    if (picked != null && mounted) {
      _birthDateCtrl.text =
          '${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}';
      setState(() {});
    }
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      locale: const Locale('hi', 'IN'),
    );
    if (picked != null && mounted) {
      _dateCtrl.text =
          '${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}';
      setState(() {});
    }
  }

  // ── Build body text segments ──
  List<_TextSegment> _buildDocumentSegments() {
    final name = _nameCtrl.text.trim();
    final gram = _gramCtrl.text.trim();
    final post = _postCtrl.text.trim();
    final vikasKhand = _vikasKhandCtrl.text.trim();
    final tehsil = _tehsilCtrl.text.trim();
    final jila = _jilaCtrl.text.trim();
    final birthDate = _birthDateCtrl.text.trim();
    final janmGram = _janmGramCtrl.text.trim();

    return [
      const _TextSegment('प्रमाणित किया जाता है कि ', false),
      _TextSegment(
        name.isEmpty ? 'फलक नाज पुत्री कमाल अहमद' : name,
        name.isEmpty,
      ),
      const _TextSegment(' ग्राम ', false),
      _TextSegment(gram.isEmpty ? 'गदनिया' : gram, gram.isEmpty),
      const _TextSegment(' पोस्ट ', false),
      _TextSegment(post.isEmpty ? 'त्रिकौलिया' : post, post.isEmpty),
      const _TextSegment(' विकास खण्ड ', false),
      _TextSegment(
        vikasKhand.isEmpty ? 'पलिया कलां' : vikasKhand,
        vikasKhand.isEmpty,
      ),
      const _TextSegment(' तहसील ', false),
      _TextSegment(tehsil.isEmpty ? 'पलिया कलां' : tehsil, tehsil.isEmpty),
      const _TextSegment(' जिला ', false),
      _TextSegment(jila.isEmpty ? 'लखीमपुर खीरी' : jila, jila.isEmpty),
      const _TextSegment(
        '  की / के मूल निवासी / निवासनी हैं  इनका जन्म दिनांक ',
        false,
      ),
      _TextSegment(
        birthDate.isEmpty ? 'जन्म दिनांक' : birthDate,
        birthDate.isEmpty,
      ),
      const _TextSegment(' को  अपने ग्राम ', false),
      _TextSegment(janmGram.isEmpty ? 'गदनिया' : janmGram, janmGram.isEmpty),
      const _TextSegment(
        ' के निजी आवास  पर हुआ है में इनको भली भांति जानती व पहचानती हूँ',
        false,
      ),
    ];
  }

  // ── Trigger PDF generation ──
  Future<void> _generatePdf() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black45,
      builder: (_) => const PdfGeneratingDialog(),
    );

    try {
      await _doGeneratePdf();
    } catch (_) {
      if (mounted) Navigator.of(context).pop();
    }
  }

  Future<void> _doGeneratePdf() async {
    final pdfCaptureKey = GlobalKey();

    final overlayEntry = OverlayEntry(
      builder: (_) => Positioned(
        left: -2000,
        top: 0,
        child: Material(
          color: Colors.white,
          child: RepaintBoundary(
            key: pdfCaptureKey,
            child: Container(
              width: 560,
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(136, 50, 45, 50),
              child: _buildDocumentPreview(fontSize: 15.0),
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(overlayEntry);
    await WidgetsBinding.instance.endOfFrame;

    final boundary =
        pdfCaptureKey.currentContext!.findRenderObject()
            as RenderRepaintBoundary;
    final ui.Image image = await boundary.toImage(pixelRatio: 4.0);

    const cropPx = 8;
    final cropRecorder = ui.PictureRecorder();
    final cropCanvas = ui.Canvas(cropRecorder);
    cropCanvas.drawImageRect(
      image,
      ui.Rect.fromLTWH(
        0,
        0,
        image.width.toDouble(),
        (image.height - cropPx).toDouble(),
      ),
      ui.Rect.fromLTWH(
        0,
        0,
        image.width.toDouble(),
        (image.height - cropPx).toDouble(),
      ),
      ui.Paint(),
    );
    final croppedImage = await cropRecorder.endRecording().toImage(
      image.width,
      image.height - cropPx,
    );
    final byteData = await croppedImage.toByteData(
      format: ui.ImageByteFormat.png,
    );
    final pngBytes = byteData!.buffer.asUint8List();

    overlayEntry.remove();

    final pdf = pw.Document();
    final pdfImage = pw.MemoryImage(pngBytes);
    final a4Width = PdfPageFormat.a4.width;
    final renderHeight = a4Width * croppedImage.height / croppedImage.width;

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.zero,
        build: (pw.Context ctx) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
          children: [
            pw.SizedBox(
              width: a4Width,
              height: renderHeight,
              child: pw.Image(pdfImage, fit: pw.BoxFit.fitWidth),
            ),
          ],
        ),
      ),
    );

    if (!mounted) return;

    // Construct file name
    final name = _nameCtrl.text.trim();
    final now = DateTime.now();
    final stamp =
        '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}_'
        '${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}${now.second.toString().padLeft(2, '0')}';
    final safeName = name.replaceAll(RegExp(r'[^\w\u0900-\u097F ]'), '').trim();
    final fileName =
        'जन्म_प्रमाण_${safeName.isNotEmpty ? safeName : 'प्रमाण'}_$stamp.pdf';
    final pdfBytes = await pdf.save();

    if (kIsWeb) {
      await Printing.sharePdf(bytes: pdfBytes, filename: fileName);
      if (!mounted) return;
      Navigator.of(context).pop();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            '✅ PDF डाउनलोड हो गई!',
            style: TextStyle(fontFamily: 'NotoSansDevanagari'),
          ),
          backgroundColor: const Color(0xFF2E7D32),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      return;
    }

    // Mobile: save to app documents directory
    await savePdfToDocuments(bytes: pdfBytes, fileName: fileName);

    if (!mounted) return;

    Navigator.of(context).pop(); // dismiss loading dialog

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => PdfSuccessSheet(
        fileName: fileName,
        onViewSaved: () {
          final nav = Navigator.of(context);
          nav.pop();
          nav.pop();
          widget.onPdfSaved?.call();
        },
        onMakeAnother: () {
          Navigator.of(context).pop();
        },
      ),
    );
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _gramCtrl.dispose();
    _postCtrl.dispose();
    _vikasKhandCtrl.dispose();
    _tehsilCtrl.dispose();
    _jilaCtrl.dispose();
    _birthDateCtrl.dispose();
    _janmGramCtrl.dispose();
    _dateCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _step == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) setState(() => _step = 0);
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(_step == 0 ? 'जन्म प्रमाण पत्र' : 'प्रमाण पत्र प्रीव्यू'),
          leading: _step == 1
              ? IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => setState(() => _step = 0),
                )
              : null,
        ),
        body: _step == 0 ? _buildInputStep() : _buildReviewStep(),
      ),
    );
  }

  Widget _buildInputStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'विवरण भरें',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontFamily: 'NotoSansDevanagari',
              ),
            ),
            const SizedBox(height: 12),

            SuggestibleInputField(
              controller: _nameCtrl,
              fieldKey: 'asha_name',
              label: 'नाम',
              hint: 'जैसे : फलक नाज पुत्री कमाल अहमद',
              onChanged: (_) => setState(() {}),
            ),
            SuggestibleInputField(
              controller: _gramCtrl,
              fieldKey: 'asha_gram',
              label: 'निवासी ग्राम',
              hint: 'जैसे : गदनिया',
              onChanged: (_) => setState(() {}),
            ),
            SuggestibleInputField(
              controller: _postCtrl,
              fieldKey: 'asha_post',
              label: 'पोस्ट',
              hint: 'जैसे : त्रिकौलिया',
              onChanged: (_) => setState(() {}),
            ),
            SuggestibleInputField(
              controller: _vikasKhandCtrl,
              fieldKey: 'asha_vikas_khand',
              label: 'विकास खंड (ब्लॉक)',
              hint: 'जैसे : पलिया कलां',
              onChanged: (_) => setState(() {}),
            ),
            SuggestibleInputField(
              controller: _tehsilCtrl,
              fieldKey: 'asha_tehsil',
              label: 'तहसील',
              hint: 'जैसे : पलिया कलां',
              onChanged: (_) => setState(() {}),
            ),
            SuggestibleInputField(
              controller: _jilaCtrl,
              fieldKey: 'asha_jila',
              label: 'जिला',
              hint: 'जैसे : लखीमपुर खीरी',
              onChanged: (_) => setState(() {}),
            ),
            SuggestibleInputField(
              controller: _birthDateCtrl,
              fieldKey: 'asha_birth_date',
              label: 'जन्म दिनांक',
              hint: 'जैसे : 10/03/2026',
              readOnly: true,
              onTap: _pickBirthDate,
              suffixIcon: const Icon(Icons.calendar_today_rounded, size: 20),
            ),
            SuggestibleInputField(
              controller: _janmGramCtrl,
              fieldKey: 'asha_janm_gram',
              label: 'जन्म का ग्राम',
              hint: 'जैसे : गदनिया (स्वतः भर जाता है)',
              onChanged: (_) {
                _janmGramManuallyEdited = true;
                setState(() {});
              },
            ),
            SuggestibleInputField(
              controller: _dateCtrl,
              fieldKey: 'asha_cert_date',
              label: 'प्रमाण पत्र दिनांक',
              hint: 'जैसे : 15/03/2026',
              readOnly: true,
              onTap: _pickDate,
              suffixIcon: const Icon(Icons.calendar_today_rounded, size: 20),
            ),

            const SizedBox(height: 20),

            SizedBox(
              height: 52,
              child: ElevatedButton.icon(
                onPressed: () => setState(() => _step = 1),
                icon: const Icon(Icons.visibility_rounded),
                label: const Text('प्रमाण पत्र देखें'),
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE0E0E0)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Container(
                width: double.infinity,
                color: Colors.white,
                padding: const EdgeInsets.fromLTRB(52, 20, 20, 20),
                child: _buildDocumentPreview(),
              ),
            ),
          ),

          const SizedBox(height: 20),

          SizedBox(
            height: 52,
            child: ElevatedButton.icon(
              onPressed: _generatePdf,
              icon: const Icon(Icons.picture_as_pdf_rounded),
              label: const Text('पीडीएफ बनाएं'),
            ),
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // ── Live preview + off-screen PDF render ──
  Widget _buildDocumentPreview({double? fontSize}) {
    final segments = _buildDocumentSegments();
    final resolvedFontSize =
        fontSize ?? Theme.of(context).textTheme.bodyLarge?.fontSize ?? 16.0;
    final date = _dateCtrl.text.trim();

    final baseStyle = TextStyle(
      fontFamily: 'NotoSansDevanagari',
      fontSize: resolvedFontSize,
      color: const Color(0xFF212121),
      height: 1.8,
    );

    final headingStyle = baseStyle.copyWith(
      fontSize: resolvedFontSize + 2.0,
      fontWeight: FontWeight.normal,
      height: 1.4,
    );

    const TextStyle phStyle = TextStyle(
      color: Color(0xFF1565C0),
      fontWeight: FontWeight.w600,
      decoration: TextDecoration.underline,
      decorationColor: Color(0xFF1565C0),
      decorationStyle: TextDecorationStyle.dashed,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Heading — centered ──
        Align(
          alignment: Alignment.center,
          child: Text(
            'ग्राम पंचायत आशा द्वारा प्रमाणित जन्म प्रमाण पत्र',
            style: headingStyle,
            textAlign: TextAlign.center,
          ),
        ),

        SizedBox(height: resolvedFontSize * 2.0),

        // ── Body paragraph ──
        RichText(
          text: TextSpan(
            style: baseStyle,
            children: segments.map((seg) {
              if (seg.isPlaceholder) {
                return TextSpan(text: seg.text, style: phStyle);
              }
              return TextSpan(text: seg.text);
            }).toList(),
          ),
        ),

        SizedBox(height: resolvedFontSize * 3.0),

        // ── Footer: दिनांक left, आशा हस्ताक्षर/ मोहर right ──
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: RichText(
                text: TextSpan(
                  style: baseStyle,
                  children: [
                    const TextSpan(text: 'दिनांक :- '),
                    TextSpan(
                      text: date.isEmpty ? '……………' : date,
                      style: date.isEmpty ? phStyle : null,
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.only(right: fontSize != null ? 23 : 0),
              child: Text('आशा हस्ताक्षर/ मोहर', style: baseStyle),
            ),
          ],
        ),
      ],
    );
  }
}

// ── Text segment: normal or placeholder ──
class _TextSegment {
  final String text;
  final bool isPlaceholder;
  const _TextSegment(this.text, this.isPlaceholder);
}
