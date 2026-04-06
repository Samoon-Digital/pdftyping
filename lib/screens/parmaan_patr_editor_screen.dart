import 'dart:ui' as ui;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import '../services/pdf_saver.dart';
import '../widgets/pdf_generation_widgets.dart';
import '../widgets/web_a4_layout.dart';
import '../widgets/suggestible_input_field.dart';

/// Two-step editor for "प्रधान द्वारा प्रमाणित प्रमाण पत्र".
/// Step 0 → input form
/// Step 1 → preview → generate PDF
class ParmaanPatrEditorScreen extends StatefulWidget {
  final VoidCallback? onPdfSaved;
  final String? editorTitle;
  const ParmaanPatrEditorScreen({super.key, this.onPdfSaved, this.editorTitle});

  @override
  State<ParmaanPatrEditorScreen> createState() =>
      _ParmaanPatrEditorScreenState();
}

class _ParmaanPatrEditorScreenState extends State<ParmaanPatrEditorScreen> {
  static const List<String> _jaatiOptions = [
    'अन्य पिछड़ा वर्ग',
    'अनुसूचित जाति',
    'अनुसूचित जनजाति',
    'सामान्य',
  ];

  final _nameCtrl = TextEditingController();
  final _relationNameCtrl = TextEditingController();
  final _gramCtrl = TextEditingController();
  final _postCtrl = TextEditingController();
  final _thanaCtrl = TextEditingController();
  final _jilaCtrl = TextEditingController();
  final _jaatiCtrl = TextEditingController();
  final _upjaatiCtrl = TextEditingController();
  final _varsikAayCtrl = TextEditingController();
  final _dateCtrl = TextEditingController();

  // ── Certificate type (multiple selection) ──
  bool _certAay = false;
  bool _certJaati = true;
  bool _certNiwas = false;

  // ── Relation type ──
  String _relationType = 'पुत्र'; // पुत्र / पत्नी / पुत्री

  // ── Step ──
  int _step = 0;
  bool _showJaatiOptions = false;

  // ── PDF photo box size ──
  static const _photoBoxW = 90.0;
  static const _photoBoxH = 112.0;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _dateCtrl.text =
        '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}';

    if (!kIsWeb) {
      FirebaseAnalytics.instance.logEvent(
        name: 'editor_open',
        parameters: {
          'editor_title': widget.editorTitle ?? 'parmaan_patr_editor',
        },
      );
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _relationNameCtrl.dispose();
    _gramCtrl.dispose();
    _postCtrl.dispose();
    _thanaCtrl.dispose();
    _jilaCtrl.dispose();
    _jaatiCtrl.dispose();
    _upjaatiCtrl.dispose();
    _varsikAayCtrl.dispose();
    _dateCtrl.dispose();
    super.dispose();
  }

  String _computedMaasikAay() {
    final annualText = _varsikAayCtrl.text.trim().replaceAll(
      RegExp(r'[^0-9]'),
      '',
    );
    if (annualText.isEmpty) return '';

    final annualIncome = int.tryParse(annualText);
    if (annualIncome == null) return '';

    return (annualIncome ~/ 12).toString();
  }

  TextSpan _docValue(String value, {String emptyText = ''}) {
    return TextSpan(text: value.isEmpty ? emptyText : value);
  }

  // ── Date picker ──
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

  // ── Generate PDF (off-screen capture → A4) ──
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
              // 0.70" L/R, 0.80" top  (560dp ÷ 8.27" = 67.7dp/inch)
              padding: const EdgeInsets.fromLTRB(47, 54, 47, 54),
              child: _buildDocumentWidget(
                fontSize: 13.2, // 14pt body at A4 render scale
              ),
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

    // Crop bottom 8px anti-aliasing artifact
    const cropPx = 8;
    final cropRec = ui.PictureRecorder();
    final cropCanvas = ui.Canvas(cropRec);
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
    final croppedImg = await cropRec.endRecording().toImage(
      image.width,
      image.height - cropPx,
    );
    final byteData = await croppedImg.toByteData(
      format: ui.ImageByteFormat.png,
    );
    final pngBytes = byteData!.buffer.asUint8List();

    overlayEntry.remove();

    // Build PDF
    final pdf = pw.Document();
    final pdfImage = pw.MemoryImage(pngBytes);
    final a4Width = PdfPageFormat.a4.width;
    final renderHeight = a4Width * croppedImg.height / croppedImg.width;

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

    // File name
    final name = _nameCtrl.text.trim();
    final now = DateTime.now();
    final stamp =
        '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}_'
        '${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}${now.second.toString().padLeft(2, '0')}';
    final safeName = name.replaceAll(RegExp(r'[^\w\u0900-\u097F ]'), '').trim();
    final fileName =
        '${safeName.isNotEmpty ? safeName : 'प्रमाण_पत्र'}_$stamp.pdf';
    final pdfBytes = await pdf.save();

    if (kIsWeb) {
      if (!mounted) return;
      await showWebPdfSuccessDialog(
        context,
        fileName: fileName,
        onDownload: () =>
            Printing.sharePdf(bytes: pdfBytes, filename: fileName),
      );
      return;
    }

    await savePdfToDocuments(bytes: pdfBytes, fileName: fileName);
    if (!mounted) return;
    Navigator.of(context).pop();
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
        onMakeAnother: () => Navigator.of(context).pop(),
      ),
    );
  }

  // ══════════════════════════════════════════
  //  BUILD
  // ══════════════════════════════════════════

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
            _step == 0 ? 'प्रमाण पत्र एडिटर' : 'प्रमाण पत्र प्रीव्यू',
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

  // ── Step 0: Input form ──

  Widget _buildInputStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Info banner
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFE3F2FD),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF90CAF9)),
            ),
            child: const Row(
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  size: 20,
                  color: Color(0xFF1565C0),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'जिसके लिए प्रमाण पत्र बनाना है उनकी जानकारी हिंदी में भरें। सभी इनपुट हिंदी में दर्ज करें।',
                    style: TextStyle(
                      fontFamily: 'NotoSansDevanagari',
                      fontSize: 13,
                      color: Color(0xFF1565C0),
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // ── Certificate type selector ──
          _buildCertTypeCard(),
          const SizedBox(height: 14),

          // ── Person info ──
          _sectionLabel('व्यक्ति की जानकारी'),
          SuggestibleInputField(
            controller: _nameCtrl,
            fieldKey: 'parmaan_name',
            label: 'व्यक्ति का नाम',
            hint: 'जैसे : राम प्रसाद',
            onChanged: (_) => setState(() {}),
          ),
          _buildRelationRow(),
          SuggestibleInputField(
            controller: _relationNameCtrl,
            fieldKey: 'parmaan_relation_name',
            label: 'पिता / पति का नाम',
            hint: 'जैसे : श्याम लाल',
            onChanged: (_) => setState(() {}),
          ),

          // ── Address ──
          _sectionLabel('पते की जानकारी'),
          SuggestibleInputField(
            controller: _gramCtrl,
            fieldKey: 'parmaan_gram',
            label: 'ग्राम',
            hint: 'जैसे : ग्राम गदनिया',
            onChanged: (_) => setState(() {}),
          ),
          SuggestibleInputField(
            controller: _postCtrl,
            fieldKey: 'parmaan_post',
            label: 'पोस्ट',
            hint: 'जैसे : त्रिकौलिया',
            onChanged: (_) => setState(() {}),
          ),
          SuggestibleInputField(
            controller: _thanaCtrl,
            fieldKey: 'parmaan_thana',
            label: 'थाना',
            hint: 'जैसे : सम्पूर्णानगर',
            onChanged: (_) => setState(() {}),
          ),
          SuggestibleInputField(
            controller: _jilaCtrl,
            fieldKey: 'parmaan_jila',
            label: 'जिला',
            hint: 'जैसे : लखीमपुर खीरी',
            onChanged: (_) => setState(() {}),
          ),

          if (_certJaati) ...[
            // ── Caste ──
            _sectionLabel('जाति की जानकारी'),
            SuggestibleInputField(
              controller: _jaatiCtrl,
              fieldKey: 'parmaan_jaati',
              label: 'जाति',
              hint: 'जैसे : अन्य पिछड़ा वर्ग , अनुसूचित जाति , जनजाति आदि',
              enableSuggestions: false,
              onTap: () => setState(() => _showJaatiOptions = true),
              onChanged: (_) => setState(() => _showJaatiOptions = true),
            ),
            if (_showJaatiOptions)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _jaatiOptions.map((option) {
                    final selected = _jaatiCtrl.text.trim() == option;
                    return ChoiceChip(
                      label: Text(
                        option,
                        style: const TextStyle(
                          fontFamily: 'NotoSansDevanagari',
                          fontSize: 13,
                        ),
                      ),
                      selected: selected,
                      onSelected: (_) {
                        _jaatiCtrl.text = option;
                        _jaatiCtrl.selection = TextSelection.collapsed(
                          offset: option.length,
                        );
                        setState(() => _showJaatiOptions = false);
                      },
                      selectedColor: const Color(
                        0xFF1565C0,
                      ).withValues(alpha: 0.13),
                      checkmarkColor: const Color(0xFF1565C0),
                      side: BorderSide(
                        color: selected
                            ? const Color(0xFF1565C0)
                            : const Color(0xFFCCCCCC),
                      ),
                    );
                  }).toList(),
                ),
              ),
            SuggestibleInputField(
              controller: _upjaatiCtrl,
              fieldKey: 'parmaan_upjaati',
              label: 'उपजाति',
              hint: 'जैसे : मोमिन / अंसार',
              onChanged: (_) => setState(() {}),
            ),
          ],

          // ── Income (only when आय is selected) ──
          if (_certAay) ...[
            _sectionLabel('आय की जानकारी'),
            SuggestibleInputField(
              controller: _varsikAayCtrl,
              fieldKey: 'parmaan_varsik_aay',
              label: 'वार्षिक आय (रु०)',
              hint: 'जैसे : 60000',
              keyboardType: TextInputType.number,
              onChanged: (_) => setState(() {}),
            ),
          ],

          // ── Date ──
          SuggestibleInputField(
            controller: _dateCtrl,
            fieldKey: 'parmaan_date',
            label: 'दिनांक',
            hint: 'जैसे : 17/03/2026',
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
    );
  }

  Widget _sectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 2, bottom: 2),
      child: Text(
        text,
        style: const TextStyle(
          fontFamily: 'NotoSansDevanagari',
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Color(0xFF666666),
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  Widget _buildCertTypeCard() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE0E0E0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'प्रमाण पत्र का प्रकार',
            style: TextStyle(
              fontFamily: 'NotoSansDevanagari',
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF444444),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              _certChip('आय', _certAay, (v) {
                setState(() => _certAay = v);
              }),
              _certChip('जाति', _certJaati, (v) {
                setState(() {
                  _certJaati = v;
                  if (!v) _showJaatiOptions = false;
                });
              }),
              _certChip('निवास', _certNiwas, (v) {
                setState(() => _certNiwas = v);
              }),
            ],
          ),
        ],
      ),
    );
  }

  Widget _certChip(String label, bool selected, ValueChanged<bool> onChanged) {
    return FilterChip(
      label: Text(
        label,
        style: const TextStyle(fontFamily: 'NotoSansDevanagari', fontSize: 13),
      ),
      selected: selected,
      onSelected: onChanged,
      selectedColor: const Color(0xFF1565C0).withValues(alpha: 0.13),
      checkmarkColor: const Color(0xFF1565C0),
      side: BorderSide(
        color: selected ? const Color(0xFF1565C0) : const Color(0xFFCCCCCC),
      ),
    );
  }

  Widget _buildRelationRow() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(bottom: 6),
            child: Text(
              'सम्बन्ध',
              style: TextStyle(
                fontFamily: 'NotoSansDevanagari',
                fontSize: 12,
                color: Color(0xFF666666),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Row(
            children: ['पुत्र', 'पत्नी', 'पुत्री'].map((type) {
              final selected = _relationType == type;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(
                    type,
                    style: const TextStyle(
                      fontFamily: 'NotoSansDevanagari',
                      fontSize: 13,
                    ),
                  ),
                  selected: selected,
                  onSelected: (_) => setState(() => _relationType = type),
                  selectedColor: const Color(
                    0xFF1565C0,
                  ).withValues(alpha: 0.13),
                  checkmarkColor: const Color(0xFF1565C0),
                  side: BorderSide(
                    color: selected
                        ? const Color(0xFF1565C0)
                        : const Color(0xFFCCCCCC),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ── Step 1: Review ──

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
                color: Colors.white,
                padding: const EdgeInsets.all(12),
                child: _buildDocumentWidget(),
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

  // ══════════════════════════════════════════
  //  DOCUMENT PREVIEW (on-screen + off-screen)
  // ══════════════════════════════════════════

  /// Shared widget that renders the Parmaan Patra document.
  /// [fontSize] — pass explicit value for PDF capture, null for on-screen.
  Widget _buildDocumentWidget({double? fontSize}) {
    final fs =
        fontSize ?? Theme.of(context).textTheme.bodyMedium?.fontSize ?? 14.0;
    // title heading = 18pt, cert chips = 16pt, body = 14pt
    final titleFs = fs * (18.0 / 14.0);
    final headingFs = fs * (16.0 / 14.0);

    final baseStyle = TextStyle(
      fontFamily: 'NotoSansDevanagari',
      fontSize: fs,
      color: const Color(0xFF212121),
      height: 1.85,
    );
    final boldBase = baseStyle.copyWith(fontWeight: FontWeight.bold);
    // Cert-type labels: same 16pt as heading, regular weight (no bold)
    final certStyle = TextStyle(
      fontFamily: 'NotoSansDevanagari',
      fontSize: headingFs,
      color: const Color(0xFF212121),
      height: 1.85,
    );

    const phStyle = TextStyle(
      color: Color(0xFF1565C0),
      fontWeight: FontWeight.w600,
      decoration: TextDecoration.underline,
      decorationColor: Color(0xFF1565C0),
      decorationStyle: TextDecorationStyle.dashed,
    );

    final name = _nameCtrl.text.trim();
    final relName = _relationNameCtrl.text.trim();
    final gram = _gramCtrl.text.trim();
    final post = _postCtrl.text.trim();
    final thana = _thanaCtrl.text.trim();
    final jila = _jilaCtrl.text.trim();
    final jaati = _jaatiCtrl.text.trim();
    final upjaati = _upjaatiCtrl.text.trim();
    final maasik = _computedMaasikAay();
    final varsik = _varsikAayCtrl.text.trim();
    final date = _dateCtrl.text.trim();

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFF212121), width: 0.9),
      ),
      padding: EdgeInsets.fromLTRB(fs * 1.1, fs * 1.2, fs * 1.1, fs * 3.5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(height: fs * 2.0),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IntrinsicWidth(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'प्रधान द्वारा प्रमाणित प्रमाण पत्र',
                            style: TextStyle(
                              fontFamily: 'NotoSansDevanagari',
                              fontSize: titleFs,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF212121),
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 5),
                          Container(
                            height: 1.5,
                            color: const Color(0xFF212121),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: fs * 3.0),
                    Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _docCertChip('आय', _certAay, certStyle, phStyle),
                          SizedBox(width: fs * 1.5),
                          _docCertChip('जाति', _certJaati, certStyle, phStyle),
                          SizedBox(width: fs * 1.5),
                          _docCertChip('निवास', _certNiwas, certStyle, phStyle),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: fs * 0.6),
              Container(
                width: _photoBoxW,
                height: _photoBoxH,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: const Color(0xFF212121),
                    width: 0.8,
                  ),
                ),
                clipBehavior: Clip.antiAlias,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.person_rounded,
                        size: fs * 1.6,
                        color: Colors.grey[350],
                      ),
                      SizedBox(height: fs * 0.25),
                      Text(
                        'यहाँ अपना\nफोटो चिपकाएँ',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'NotoSansDevanagari',
                          fontSize: fs * 0.62,
                          color: Colors.grey[500],
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          SizedBox(height: fs * 2.9), // body 2 extra lines below cert row
          // ── Main body — SizedBox forces full content width ──
          SizedBox(
            width: double.infinity,
            child: RichText(
              textWidthBasis: TextWidthBasis.parent,
              text: TextSpan(
                style: baseStyle,
                children: [
                  const TextSpan(
                    text: 'प्रमाणित किया जाता है कि श्री/श्रीमती/कु0 ',
                  ),
                  _docValue(name),
                  const TextSpan(text: ' '),
                  TextSpan(text: '$_relationType '),
                  _docValue(relName),
                  const TextSpan(text: ' ग्राम '),
                  _docValue(gram),
                  const TextSpan(text: ' '),
                  const TextSpan(text: 'पोस्ट '),
                  _docValue(post),
                  const TextSpan(text: ' '),
                  const TextSpan(text: 'थाना '),
                  _docValue(thana),
                  const TextSpan(text: ' जिला '),
                  _docValue(jila),
                  const TextSpan(text: ' '),
                  const TextSpan(
                    text:
                        'के मूल निवासी/निवासिनी हैं। मैं इनको भली भांति जानता/जानती पहचानता/पहचानती हूं '
                        'तथा इनकी जाति ',
                  ),
                  _docValue(jaati, emptyText: '******'),
                  const TextSpan(text: ' '),
                  const TextSpan(text: 'उपजाति '),
                  _docValue(upjaati, emptyText: '******'),
                  const TextSpan(text: ' '),
                  const TextSpan(
                    text:
                        'है। तथा इनके पिता/पति की समस्त श्रोतों से होने वाली कुल '
                        'मासिक आय मु0 ',
                  ),
                  _docValue(maasik, emptyText: '******'),
                  const TextSpan(text: ' '),
                  const TextSpan(text: 'तथा वार्षिक आय मु0 '),
                  _docValue(varsik, emptyText: '******'),
                  const TextSpan(text: ' '),
                  const TextSpan(text: 'है।'),
                ],
              ),
            ),
          ), // end SizedBox full-width

          SizedBox(height: fs * 2.5),

          // ── Footer: date left, signature right ──
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              RichText(
                text: TextSpan(
                  style: baseStyle,
                  children: [
                    const TextSpan(text: 'दिनांक – '),
                    TextSpan(
                      text: date.isEmpty ? '……………' : date,
                      style: date.isEmpty ? phStyle : null,
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 68), // shift 1" left
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text('प्रधान', style: boldBase),
                    Text('हस्ताक्षर व मुहर', style: boldBase),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 68), // 1 inch blank space for stamp/sign
        ],
      ),
    );
  }

  /// Small checkbox + label rendered inside the document.
  Widget _docCertChip(
    String label,
    bool checked,
    TextStyle base,
    TextStyle ph,
  ) {
    final size = (base.fontSize ?? 12) * 0.85;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFF212121), width: 0.8),
          ),
          child: Center(
            child: checked
                ? Icon(Icons.check, size: size * 0.8, color: Colors.black)
                : Text(
                    'X',
                    style: TextStyle(
                      fontFamily: 'NotoSansDevanagari',
                      fontSize: size * 0.72,
                      color: Colors.black,
                      fontWeight: FontWeight.w600,
                      height: 1,
                    ),
                  ),
          ),
        ),
        const SizedBox(width: 3),
        Text(label, style: base),
      ],
    );
  }
}
