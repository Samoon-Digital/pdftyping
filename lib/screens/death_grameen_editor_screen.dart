import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../widgets/suggestible_input_field.dart';
import '../widgets/pdf_generation_widgets.dart';

class DeathGrameenEditorScreen extends StatefulWidget {
  final VoidCallback? onPdfSaved;
  const DeathGrameenEditorScreen({super.key, this.onPdfSaved});

  @override
  State<DeathGrameenEditorScreen> createState() =>
      _DeathGrameenEditorScreenState();
}

class _DeathGrameenEditorScreenState extends State<DeathGrameenEditorScreen> {
  final _deceasedNameCtrl = TextEditingController();
  final _gramCtrl = TextEditingController();
  final _postCtrl = TextEditingController();
  final _vikasKhandCtrl = TextEditingController();
  final _tehsilCtrl = TextEditingController();
  final _jilaCtrl = TextEditingController(text: 'लखीमपुर खीरी');
  final _deathDateCtrl = TextEditingController();
  final _deathGramCtrl = TextEditingController();
  final _dateCtrl = TextEditingController();

  final _formKey = GlobalKey<FormState>();
  bool _deathGramManuallyEdited = false;
  int _step = 0;

  @override
  void initState() {
    super.initState();
    // Auto-fill मृत्यु का ग्राम from ग्राम, unless user edits it manually
    _gramCtrl.addListener(() {
      if (!_deathGramManuallyEdited) {
        final val = _gramCtrl.text;
        if (_deathGramCtrl.text != val) {
          _deathGramCtrl.text = val;
          setState(() {});
        }
      }
    });
    // Auto-fill today's date
    final now = DateTime.now();
    _dateCtrl.text =
        '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}';
  }

  Future<void> _pickDeathDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      locale: const Locale('hi', 'IN'),
    );
    if (picked != null && mounted) {
      _deathDateCtrl.text =
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
    final deceased = _deceasedNameCtrl.text.trim();
    final gram = _gramCtrl.text.trim();
    final post = _postCtrl.text.trim();
    final vikasKhand = _vikasKhandCtrl.text.trim();
    final tehsil = _tehsilCtrl.text.trim();
    final jila = _jilaCtrl.text.trim();
    final deathDate = _deathDateCtrl.text.trim();
    final deathGram = _deathGramCtrl.text.trim();

    return [
      const _TextSegment('प्रमाणित किया जाता है कि ', false),
      _TextSegment(
        deceased.isEmpty ? 'मृतक / मृतका का नाम' : deceased,
        deceased.isEmpty,
      ),
      const _TextSegment(' ग्राम ', false),
      _TextSegment(gram.isEmpty ? 'ग्राम का नाम' : gram, gram.isEmpty),
      const _TextSegment(' पोस्ट ', false),
      _TextSegment(post.isEmpty ? 'पोस्ट' : post, post.isEmpty),
      const _TextSegment(' विकास खण्ड ', false),
      _TextSegment(
        vikasKhand.isEmpty ? 'विकास खण्ड' : vikasKhand,
        vikasKhand.isEmpty,
      ),
      const _TextSegment(' व तहसील ', false),
      _TextSegment(tehsil.isEmpty ? 'तहसील' : tehsil, tehsil.isEmpty),
      const _TextSegment(' जिला ', false),
      _TextSegment(jila.isEmpty ? 'जिला' : jila, false),
      const _TextSegment(
        ' की / के मूल निवासी / निवासनी थी  इनकी मृत्यु दिनांक ',
        false,
      ),
      _TextSegment(
        deathDate.isEmpty ? 'मृत्यु दिनांक' : deathDate,
        deathDate.isEmpty,
      ),
      const _TextSegment(' को  अपने ग्राम ', false),
      _TextSegment(
        deathGram.isEmpty ? 'ग्राम का नाम' : deathGram,
        deathGram.isEmpty,
      ),
      const _TextSegment(
        ' के निजी आवास  पर आकस्मिक रूप से हो गई थी  मैं इनको भली भांति जानता / जानती  व पहचानता / पहचानती हूँ।',
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
              // Left=136dp≈2 inch, Right=45dp on A4 (560dp=210mm → 1dp≈0.375mm)
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

    final docsDir = await getApplicationDocumentsDirectory();
    final deceased = _deceasedNameCtrl.text.trim();
    final now = DateTime.now();
    final stamp =
        '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}_'
        '${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}${now.second.toString().padLeft(2, '0')}';
    final safeDeceased = deceased
        .replaceAll(RegExp(r'[^\w\u0900-\u097F ]'), '')
        .trim();
    final fileName =
        'मृत्यु_प्रमाण_${safeDeceased.isNotEmpty ? safeDeceased : 'प्रमाण'}_$stamp.pdf';
    final pdfBytes = await pdf.save();
    final file = File('${docsDir.path}/$fileName');
    await file.writeAsBytes(pdfBytes);

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
    _deceasedNameCtrl.dispose();
    _gramCtrl.dispose();
    _postCtrl.dispose();
    _vikasKhandCtrl.dispose();
    _tehsilCtrl.dispose();
    _jilaCtrl.dispose();
    _deathDateCtrl.dispose();
    _deathGramCtrl.dispose();
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
          title: Text(
            _step == 0 ? 'मृत्यु प्रमाण पत्र' : 'प्रमाण पत्र प्रीव्यू',
          ),
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
              controller: _deceasedNameCtrl,
              fieldKey: 'death_deceased_name',
              label: 'मृतक / मृतका का नाम',
              hint: 'जैसे : राम प्रसाद पुत्र शिवदयाल',
              onChanged: (_) => setState(() {}),
            ),
            SuggestibleInputField(
              controller: _gramCtrl,
              fieldKey: 'death_gram',
              label: 'निवासी ग्राम',
              hint: 'जैसे : गड़निया',
              onChanged: (_) => setState(() {}),
            ),
            SuggestibleInputField(
              controller: _postCtrl,
              fieldKey: 'death_post',
              label: 'पोस्ट',
              hint: 'जैसे : त्रिकोलिया',
              onChanged: (_) => setState(() {}),
            ),
            SuggestibleInputField(
              controller: _vikasKhandCtrl,
              fieldKey: 'death_vikas_khand',
              label: 'विकास खण्ड (ब्लॉक)',
              hint: 'जैसे : पलिया कलाँ',
              onChanged: (_) => setState(() {}),
            ),
            SuggestibleInputField(
              controller: _tehsilCtrl,
              fieldKey: 'death_tehsil',
              label: 'तहसील',
              hint: 'जैसे : पलिया कलाँ',
              onChanged: (_) => setState(() {}),
            ),
            SuggestibleInputField(
              controller: _jilaCtrl,
              fieldKey: 'death_jila',
              label: 'जिला',
              hint: 'जैसे : लखीमपुर खीरी',
              onChanged: (_) => setState(() {}),
            ),
            SuggestibleInputField(
              controller: _deathDateCtrl,
              fieldKey: 'death_death_date',
              label: 'मृत्यु दिनांक',
              hint: 'जैसे : 10/03/2026',
              readOnly: true,
              onTap: _pickDeathDate,
              suffixIcon: const Icon(Icons.calendar_today_rounded, size: 20),
            ),
            SuggestibleInputField(
              controller: _deathGramCtrl,
              fieldKey: 'death_death_gram',
              label: 'मृत्यु का ग्राम',
              hint: 'जैसे : गड़निया (स्वतः भर जाता है)',
              onChanged: (_) {
                _deathGramManuallyEdited = true;
                setState(() {});
              },
            ),
            SuggestibleInputField(
              controller: _dateCtrl,
              fieldKey: 'death_cert_date',
              label: 'प्रमाण पत्र दिनांक',
              hint: 'जैसे : 14/03/2026',
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
    final isPdf = fontSize != null;

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
        // ── Heading — centered, regular weight, 2pt larger ──
        Align(
          alignment: Alignment.center,
          child: Text(
            'ग्राम प्रधान द्वारा प्रमाणित मृत्यु प्रमाण पत्र',
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

        // ── Footer: दिनांक left, हस्ताक्षर व मोहर right ──
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            RichText(
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
            Padding(
              // 23dp ≈ (68−45)dp so the text ends 1 inch from A4 right edge
              padding: const EdgeInsets.only(right: 23),
              child: Text('हस्ताक्षर व मोहर', style: baseStyle),
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
