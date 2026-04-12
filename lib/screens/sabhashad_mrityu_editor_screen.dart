import 'dart:ui' as ui;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import '../services/pdf_saver.dart';
import '../widgets/suggestible_input_field.dart';
import '../widgets/pdf_generation_widgets.dart';
import '../widgets/web_a4_layout.dart';

class SabhashadMrityuEditorScreen extends StatefulWidget {
  final VoidCallback? onPdfSaved;
  final String? editorTitle;
  const SabhashadMrityuEditorScreen({
    super.key,
    this.onPdfSaved,
    this.editorTitle,
  });

  @override
  State<SabhashadMrityuEditorScreen> createState() =>
      _SabhashadMrityuEditorScreenState();
}

class _SabhashadMrityuEditorScreenState
    extends State<SabhashadMrityuEditorScreen> {
  final _nameCtrl = TextEditingController();
  final _makanCtrl = TextEditingController();
  final _wardCtrl = TextEditingController();
  final _mohallahCtrl = TextEditingController();
  final _shaharCtrl = TextEditingController();
  final _jilaCtrl = TextEditingController();
  final _mrityuDateCtrl = TextEditingController();
  final _mrityuMohallahCtrl = TextEditingController();
  final _dateCtrl = TextEditingController();

  final _formKey = GlobalKey<FormState>();
  final bool _mrityuMohallahManuallyEdited = false;
  int _step = 0;

  @override
  void initState() {
    super.initState();
    // Auto-fill मृत्यु मोहल्ला from निवासी मोहल्ला unless manually edited
    _mohallahCtrl.addListener(() {
      if (!_mrityuMohallahManuallyEdited) {
        final val = _mohallahCtrl.text;
        if (_mrityuMohallahCtrl.text != val) {
          _mrityuMohallahCtrl.text = val;
          setState(() {});
        }
      }
    });
    // Auto-fill today's date
    final now = DateTime.now();
    _dateCtrl.text =
        '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}';

    if (!kIsWeb) {
      FirebaseAnalytics.instance.logEvent(
        name: 'editor_open',
        parameters: {
          'editor_title': widget.editorTitle ?? 'sabhashad_mrityu_editor',
        },
      );
    }
  }

  Future<void> _pickMrityuDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(1950),
      lastDate: DateTime(2100),
      locale: const Locale('hi', 'IN'),
    );
    if (picked != null && mounted) {
      _mrityuDateCtrl.text =
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
  List<_SabMrityuSegment> _buildDocumentSegments() {
    final name = _nameCtrl.text.trim();
    final makan = _makanCtrl.text.trim();
    final ward = _wardCtrl.text.trim();
    final mohallah = _mohallahCtrl.text.trim();
    final shahar = _shaharCtrl.text.trim();
    final jila = _jilaCtrl.text.trim();
    final mrityuDate = _mrityuDateCtrl.text.trim();
    final mrityuMohallah = _mrityuMohallahCtrl.text.trim();

    return [
      const _SabMrityuSegment('प्रमाणित किया जाता है कि ', false),
      _SabMrityuSegment(
        name.isEmpty ? 'फलक नाज पुत्री कमाल अहमद' : name,
        name.isEmpty,
      ),
      const _SabMrityuSegment(' मकान संख्या ', false),
      _SabMrityuSegment(makan.isEmpty ? '******' : makan, false),
      const _SabMrityuSegment(' वार्ड संख्या ', false),
      _SabMrityuSegment(ward.isEmpty ? '******' : ward, false),
      const _SabMrityuSegment(' मोहल्ला ', false),
      _SabMrityuSegment(
        mohallah.isEmpty ? 'पठान 2' : mohallah,
        mohallah.isEmpty,
      ),
      const _SabMrityuSegment(' शहर/कस्बा ', false),
      _SabMrityuSegment(shahar.isEmpty ? 'पलिया कलां' : shahar, shahar.isEmpty),
      const _SabMrityuSegment(' जिला ', false),
      _SabMrityuSegment(jila.isEmpty ? 'लखीमपुर खीरी' : jila, jila.isEmpty),
      const _SabMrityuSegment(
        '  की / के मूल निवासी / निवासनी हैं  इनकी मृत्यु दिनांक ',
        false,
      ),
      _SabMrityuSegment(
        mrityuDate.isEmpty ? 'मृत्यु दिनांक' : mrityuDate,
        mrityuDate.isEmpty,
      ),
      const _SabMrityuSegment(' को  अपने मोहल्ले ', false),
      _SabMrityuSegment(
        mrityuMohallah.isEmpty ? 'पठान 2' : mrityuMohallah,
        mrityuMohallah.isEmpty,
      ),
      const _SabMrityuSegment(
        ' के निजी आवास पर हुई है  मैं इनको भली भांति जानता / जानती व पहचानता / पहचानती हूँ |',
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
    await Future.delayed(const Duration(milliseconds: 100));

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
        'मृत्यु_प्रमाण_${safeName.isNotEmpty ? safeName : 'प्रमाण'}_$stamp.pdf';
    final pdfBytes = await pdf.save();

    if (kIsWeb) {
      if (!mounted) return;
      await showWebPdfSuccessDialog(
        context,
        fileName: fileName,
        pdfBytes: pdfBytes,
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
          widget.onPdfSaved?.call();
          Navigator.of(context).popUntil((route) => route.isFirst);
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
    _makanCtrl.dispose();
    _wardCtrl.dispose();
    _mohallahCtrl.dispose();
    _shaharCtrl.dispose();
    _jilaCtrl.dispose();
    _mrityuDateCtrl.dispose();
    _mrityuMohallahCtrl.dispose();
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
        body: WebA4Layout(
          child: _step == 0 ? _buildInputStep() : _buildReviewStep(),
        ),
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
              fieldKey: 'sab_mrityu_name',
              label: 'नाम',
              hint: 'जैसे : फलक नाज पुत्री कमाल अहमद',
              onChanged: (_) => setState(() {}),
            ),
            SuggestibleInputField(
              controller: _makanCtrl,
              fieldKey: 'sab_mrityu_makan',
              label: 'मकान संख्या',
              hint: 'जैसे : 35/ए',
              onChanged: (_) => setState(() {}),
            ),
            SuggestibleInputField(
              controller: _wardCtrl,
              fieldKey: 'sab_mrityu_ward',
              label: 'वार्ड संख्या',
              hint: 'जैसे : 8',
              onChanged: (_) => setState(() {}),
            ),
            SuggestibleInputField(
              controller: _mohallahCtrl,
              fieldKey: 'sab_mrityu_mohallah',
              label: 'मोहल्ला',
              hint: 'जैसे : पठान 2',
              onChanged: (_) => setState(() {}),
            ),
            SuggestibleInputField(
              controller: _shaharCtrl,
              fieldKey: 'sab_mrityu_shahar',
              label: 'शहर / कस्बा',
              hint: 'जैसे : पलिया कलां',
              onChanged: (_) => setState(() {}),
            ),
            SuggestibleInputField(
              controller: _jilaCtrl,
              fieldKey: 'sab_mrityu_jila',
              label: 'जिला',
              hint: 'जैसे : लखीमपुर खीरी',
              onChanged: (_) => setState(() {}),
            ),
            SuggestibleInputField(
              controller: _mrityuDateCtrl,
              fieldKey: 'sab_mrityu_date',
              label: 'मृत्यु दिनांक',
              hint: 'जैसे : 10/03/2026',
              readOnly: true,
              onTap: _pickMrityuDate,
              suffixIcon: const Icon(Icons.calendar_today_rounded, size: 20),
            ),
            // मृत्यु मोहल्ला इनपुट छिपाया गया — यह स्वतः निवासी मोहल्ला से भरेगा
            SuggestibleInputField(
              controller: _dateCtrl,
              fieldKey: 'sab_mrityu_cert_date',
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
            'सभासद द्वारा प्रमाणित\nमृत्यु प्रमाण पत्र',
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
              child: Text('सभासद हस्ताक्षर/ मोहर', style: baseStyle),
            ),
          ],
        ),
      ],
    );
  }
}

// ── Text segment: normal or placeholder ──
class _SabMrityuSegment {
  final String text;
  final bool isPlaceholder;
  const _SabMrityuSegment(this.text, this.isPlaceholder);
}
