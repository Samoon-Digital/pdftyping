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
import '../widgets/suggestible_input_field.dart';
import '../widgets/web_a4_layout.dart';

class MaykeKiJatiGramPradhanEditorScreen extends StatefulWidget {
  final VoidCallback? onPdfSaved;
  final String? editorTitle;

  const MaykeKiJatiGramPradhanEditorScreen({
    super.key,
    this.onPdfSaved,
    this.editorTitle,
  });

  @override
  State<MaykeKiJatiGramPradhanEditorScreen> createState() =>
      _MaykeKiJatiGramPradhanEditorScreenState();
}

class _MaykeKiJatiGramPradhanEditorScreenState
    extends State<MaykeKiJatiGramPradhanEditorScreen> {
  static const List<String> _vargOptions = [
    'अन्य पिछड़ा वर्ग',
    'अनुसूचित जाति',
    'अनुसूचित जनजाति',
    'सामान्य',
  ];

  final _girlNameCtrl = TextEditingController();
  final _maikaAddressCtrl = TextEditingController();
  final _shadiYearsCtrl = TextEditingController();
  final _husbandNameCtrl = TextEditingController();
  final _sasuralAddressCtrl = TextEditingController();
  final _vargCtrl = TextEditingController();
  final _upjaatiCtrl = TextEditingController();
  final _dateCtrl = TextEditingController();

  final _formKey = GlobalKey<FormState>();
  int _step = 0;
  bool _showVargOptions = false;

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
          'editor_title':
              widget.editorTitle ?? 'mayke_ki_jati_gram_pradhan_editor',
        },
      );
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

  List<_TextSegment> _buildDocumentSegments() {
    final girlName = _girlNameCtrl.text.trim();
    final maikaAddress = _maikaAddressCtrl.text.trim();
    final shadiYears = _shadiYearsCtrl.text.trim();
    final husbandName = _husbandNameCtrl.text.trim();
    final sasuralAddress = _sasuralAddressCtrl.text.trim();
    final varg = _vargCtrl.text.trim();
    final upjaati = _upjaatiCtrl.text.trim();

    return [
      const _TextSegment('प्रमाणित किया जाता है कि ', false),
      _TextSegment(
        girlName.isEmpty ? 'लड़की का नाम पिता समेत' : girlName,
        girlName.isEmpty,
      ),
      const _TextSegment(' निवासी ', false),
      _TextSegment(
        maikaAddress.isEmpty ? 'मायके का पूरा पता' : maikaAddress,
        maikaAddress.isEmpty,
      ),
      const _TextSegment(' की निवासनी थी जिनकी शादी ', false),
      _TextSegment(
        shadiYears.isEmpty ? 'शादी के वर्ष' : shadiYears,
        shadiYears.isEmpty,
      ),
      const _TextSegment(' वर्ष पूर्व ', false),
      _TextSegment(
        husbandName.isEmpty ? 'पति का नाम पिता समेत' : husbandName,
        husbandName.isEmpty,
      ),
      const _TextSegment(' निवासी ', false),
      _TextSegment(
        sasuralAddress.isEmpty ? 'ससुराल का पूरा पता' : sasuralAddress,
        sasuralAddress.isEmpty,
      ),
      const _TextSegment(' से हुई है तथा इनकी ', false),
      _TextSegment(varg.isEmpty ? 'वर्ग' : varg, varg.isEmpty),
      const _TextSegment(' वर्ग और उपजाति ', false),
      _TextSegment(upjaati.isEmpty ? 'उपजाति' : upjaati, upjaati.isEmpty),
      const _TextSegment(
        ' हैं। मैं इनको भली भांति जानता / जानती व पहचानता / पहचानती हूँ।',
        false,
      ),
    ];
  }

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

    final girlName = _girlNameCtrl.text.trim();
    final now = DateTime.now();
    final stamp =
        '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}_'
        '${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}${now.second.toString().padLeft(2, '0')}';
    final safeName = girlName
        .replaceAll(RegExp(r'[^\w\u0900-\u097F ]'), '')
        .trim();
    final fileName =
        'मायका_जाति_प्रमाण_${safeName.isNotEmpty ? safeName : 'प्रमाण'}_$stamp.pdf';
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
        onMakeAnother: () {
          Navigator.of(context).pop();
        },
      ),
    );
  }

  @override
  void dispose() {
    _girlNameCtrl.dispose();
    _maikaAddressCtrl.dispose();
    _shadiYearsCtrl.dispose();
    _husbandNameCtrl.dispose();
    _sasuralAddressCtrl.dispose();
    _vargCtrl.dispose();
    _upjaatiCtrl.dispose();
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
            _step == 0 ? 'मायके का जाति प्रमाण पत्र' : 'प्रमाण पत्र प्रीव्यू',
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
              controller: _girlNameCtrl,
              fieldKey: 'mayke_jati_girl_name',
              label: 'लड़की का नाम पिता समेत',
              hint: 'राजकुमारी पुत्री अशोक कुमार',
              onChanged: (_) => setState(() {}),
            ),
            SuggestibleInputField(
              controller: _maikaAddressCtrl,
              fieldKey: 'mayke_jati_maika_address',
              label: 'पूरा पता डालें - ग्रामीण व शहरी',
              hint:
                  'जैसे : ग्राम गदनिया पोस्ट त्रिकोलिया, पलिया कलाँ लखीमपुर खीरी',
              onChanged: (_) => setState(() {}),
            ),
            SuggestibleInputField(
              controller: _shadiYearsCtrl,
              fieldKey: 'mayke_jati_shadi_years',
              label: 'शादी के वर्ष',
              hint: 'शादी के साल नंबर में डालें',
              keyboardType: TextInputType.number,
              onChanged: (_) => setState(() {}),
            ),
            SuggestibleInputField(
              controller: _husbandNameCtrl,
              fieldKey: 'mayke_jati_husband_name',
              label: 'पति का नाम पिता समेत',
              hint: 'राहुल कुमार पुत्र प्रमोद कुमार',
              onChanged: (_) => setState(() {}),
            ),
            SuggestibleInputField(
              controller: _sasuralAddressCtrl,
              fieldKey: 'mayke_jati_sasural_address',
              label: 'पूरा पता डालें - ग्रामीण व शहरी',
              hint:
                  'जैसे : मकान संख्या 102 मोहल्ला पठान, पलिया कलाँ जिला लखीमपुर खीरी',
              onChanged: (_) => setState(() {}),
            ),
            SuggestibleInputField(
              controller: _vargCtrl,
              fieldKey: 'mayke_jati_varg',
              label: 'वर्ग',
              hint: 'जैसे : अनुसूचित जाति / अन्य पिछड़ा वर्ग',
              enableSuggestions: false,
              onTap: () => setState(() => _showVargOptions = true),
              onChanged: (_) => setState(() => _showVargOptions = true),
            ),
            if (_showVargOptions)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _vargOptions.map((option) {
                    final selected = _vargCtrl.text.trim() == option;
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
                        _vargCtrl.text = option;
                        _vargCtrl.selection = TextSelection.collapsed(
                          offset: option.length,
                        );
                        setState(() => _showVargOptions = false);
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
              fieldKey: 'mayke_jati_upjaati',
              label: 'उपजाति',
              hint: 'जैसे : पासी / यादव / कुर्मी',
              onChanged: (_) => setState(() {}),
            ),
            SuggestibleInputField(
              controller: _dateCtrl,
              fieldKey: 'mayke_jati_cert_date',
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
                onPressed: () {
                  if (_formKey.currentState?.validate() ?? false) {
                    setState(() => _step = 1);
                  }
                },
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
        Align(
          alignment: Alignment.center,
          child: Text(
            'प्रधान द्वारा प्रमाणित मायके का जाति प्रमाण पत्र',
            style: headingStyle,
            textAlign: TextAlign.center,
          ),
        ),
        SizedBox(height: resolvedFontSize * 2.0),
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
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            RichText(
              text: TextSpan(
                style: baseStyle,
                children: [
                  const TextSpan(text: 'दिनांक : '),
                  TextSpan(
                    text: date.isEmpty ? '……………' : date,
                    style: date.isEmpty ? phStyle : null,
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 23),
              child: Text(
                'प्रधान हस्ताक्षर\nव मोहर',
                style: baseStyle,
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _TextSegment {
  final String text;
  final bool isPlaceholder;

  const _TextSegment(this.text, this.isPlaceholder);
}
