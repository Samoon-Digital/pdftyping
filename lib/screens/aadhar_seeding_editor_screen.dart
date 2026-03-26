import 'dart:ui' as ui;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../services/pdf_saver.dart';
import '../widgets/pdf_generation_widgets.dart';
import '../widgets/suggestible_input_field.dart';

class AadharSeedingEditorScreen extends StatefulWidget {
  final VoidCallback? onPdfSaved;
  const AadharSeedingEditorScreen({super.key, this.onPdfSaved});

  @override
  State<AadharSeedingEditorScreen> createState() =>
      _AadharSeedingEditorScreenState();
}

class _AadharSeedingEditorScreenState extends State<AadharSeedingEditorScreen> {
  final _bankNameCtrl = TextEditingController();
  final _branchCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _accountNumberCtrl = TextEditingController();
  final _aadharNoCtrl = TextEditingController();
  final _aadharCardNameCtrl = TextEditingController();
  final _mobileCtrl = TextEditingController();
  final _dateCtrl = TextEditingController();

  final _formKey = GlobalKey<FormState>();

  int _step = 0;

  @override
  void initState() {
    super.initState();
    // Auto-fill today's date
    final now = DateTime.now();
    _dateCtrl.text =
        '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}';

    // Always mirror applicant name → aadhar card name
    _nameCtrl.addListener(() {
      final val = _nameCtrl.text;
      if (_aadharCardNameCtrl.text != val) {
        _aadharCardNameCtrl.text = val;
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _bankNameCtrl.dispose();
    _branchCtrl.dispose();
    _nameCtrl.dispose();
    _addressCtrl.dispose();
    _accountNumberCtrl.dispose();
    _aadharNoCtrl.dispose();
    _aadharCardNameCtrl.dispose();
    _mobileCtrl.dispose();
    _dateCtrl.dispose();
    super.dispose();
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

  // ── Build the main body text segments ──
  List<_TextSegment> _buildBodySegments() {
    final bankName = _bankNameCtrl.text.trim();
    final branch = _branchCtrl.text.trim();
    final name = _nameCtrl.text.trim();
    final address = _addressCtrl.text.trim();
    final accNo = _accountNumberCtrl.text.trim();
    final aadharNo = _aadharNoCtrl.text.trim();
    final aadharCardName = _aadharCardNameCtrl.text.trim();

    return [
      const _TextSegment('सेवा में,', false),
      const _TextSegment('\nशाखा प्रबंधक महोदय/महोदया', false),
      const _TextSegment('\n', false),
      _TextSegment(bankName.isEmpty ? '…………' : bankName, bankName.isEmpty),
      const _TextSegment('\n', false),
      _TextSegment(branch.isEmpty ? '…………' : branch, branch.isEmpty),
      const _TextSegment('\n\n', false),
      const _TextSegment(
        'विषय: बैंक खाते से आधार संख्या लिंक (सीडिंग) कराने हेतु आवेदन',
        false,
      ),
      const _TextSegment('\n\n', false),
      const _TextSegment('महोदय/महोदया,', false),
      const _TextSegment('\n\n', false),
      const _TextSegment('सविनय निवेदन है कि मैं, ', false),
      _TextSegment(name.isEmpty ? '……………………' : name, name.isEmpty),
      const _TextSegment(', निवासी ', false),
      _TextSegment(address.isEmpty ? '……………………' : address, address.isEmpty),
      const _TextSegment(',', false),
      const _TextSegment('\nआपके बैंक की शाखा में मेरा खाता संख्या ', false),
      _TextSegment(accNo.isEmpty ? '……………………' : accNo, accNo.isEmpty),
      const _TextSegment(' संचालित है।', false),
      const _TextSegment('\n\n', false),
      const _TextSegment('मैं अपना आधार संख्या ', false),
      _TextSegment(
        aadharNo.isEmpty ? '________________' : aadharNo,
        aadharNo.isEmpty,
      ),
      const _TextSegment(' जो कि आधार कार्ड के अनुसार नाम ', false),
      _TextSegment(
        aadharCardName.isEmpty ? '……………………' : aadharCardName,
        aadharCardName.isEmpty,
      ),
      const _TextSegment(' पर जारी है,', false),
      const _TextSegment(
        '\nअपने उपरोक्त बैंक खाते से लिंक (सीडिंग) कराना चाहता/चाहती हूँ।',
        false,
      ),
      const _TextSegment('\n\n', false),
      const _TextSegment(
        'मैं अपनी स्वेच्छा से यह सहमति देता/देती हूँ कि मेरे आधार नंबर का उपयोग बैंक द्वारा पहचान सत्यापन एवं बैंकिंग सेवाओं तथा प्रत्यक्ष लाभ अंतरण (DBT) के लिए किया जा सकता है।',
        false,
      ),
      const _TextSegment('\n\n', false),
      const _TextSegment(
        'अतः आपसे निवेदन है कि कृपया मेरे बैंक खाते को आधार से लिंक करने की कृपा करें। आपकी महान कृपया होगी |धन्यवाद',
        false,
      ),
    ];
  }

  // ── PDF generation ──
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
              padding: const EdgeInsets.fromLTRB(45, 50, 45, 50),
              child: _buildApplicationPreview(fontSize: 11.3),
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
        build: (_) => pw.Column(
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

    final name = _nameCtrl.text.trim();
    final bank = _bankNameCtrl.text.trim();
    final now = DateTime.now();
    final stamp =
        '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}_'
        '${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}${now.second.toString().padLeft(2, '0')}';
    final safeName = name.replaceAll(RegExp(r'[^\w\u0900-\u097F ]'), '').trim();
    final safeBank = bank.replaceAll(RegExp(r'[^\w\u0900-\u097F ]'), '').trim();
    final fileName =
        'आधार_सीडिंग_${safeName.isNotEmpty ? safeName : 'आवेदन'}_${safeBank.isNotEmpty ? safeBank : 'बैंक'}_$stamp.pdf';
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

  // ── Widget tree ──
  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _step == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) setState(() => _step = 0);
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(_step == 0 ? 'आधार सीडिंग आवेदन' : 'आवेदन प्रीव्यू'),
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
                      'खाताधारक या जिसके लिए आवेदन किया जा रहा है उनकी details भरें',
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
            const SizedBox(height: 16),

            SuggestibleInputField(
              controller: _bankNameCtrl,
              fieldKey: 'aadhar_bank_name',
              label: 'बैंक का नाम',
              hint: 'जैसे : बैंक ऑफ बड़ोदा',
              onChanged: (_) => setState(() {}),
            ),
            SuggestibleInputField(
              controller: _branchCtrl,
              fieldKey: 'aadhar_branch',
              label: 'शाखा का नाम',
              hint: 'जैसे : नगला , लखीमपुर खीरी',
              onChanged: (_) => setState(() {}),
            ),
            SuggestibleInputField(
              controller: _nameCtrl,
              fieldKey: 'aadhar_name',
              label: 'आवेदक का नाम',
              hint: 'जैसे : सामून अली पुत्र अब्दुल वहाब इस तरह लिखें',
              onChanged: (_) => setState(() {}),
            ),
            SuggestibleInputField(
              controller: _addressCtrl,
              fieldKey: 'aadhar_address',
              label: 'पता',
              hint: 'जैसे : ग्राम – नगला, जिला – लखीमपुर खीरी',
              onChanged: (_) => setState(() {}),
            ),
            SuggestibleInputField(
              controller: _accountNumberCtrl,
              fieldKey: 'aadhar_account_number',
              label: 'खाता संख्या',
              hint: 'जैसे : 1234567890',
              keyboardType: TextInputType.number,
              onChanged: (_) => setState(() {}),
            ),
            SuggestibleInputField(
              controller: _aadharNoCtrl,
              fieldKey: 'aadhar_number',
              label: 'आधार संख्या',
              hint: 'जैसे : 1234 5678 9012',
              keyboardType: TextInputType.number,
              onChanged: (_) => setState(() {}),
            ),
            SuggestibleInputField(
              controller: _mobileCtrl,
              fieldKey: 'aadhar_mobile',
              label: 'मोबाइल नंबर',
              hint: 'जैसे : 9876543210',
              keyboardType: TextInputType.phone,
              onChanged: (_) => setState(() {}),
            ),
            SuggestibleInputField(
              controller: _dateCtrl,
              fieldKey: 'aadhar_date',
              label: 'दिनांक',
              hint: 'जैसे : 12/03/2026',
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
                label: const Text('आवेदन देखें'),
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
                padding: const EdgeInsets.all(20),
                child: _buildApplicationPreview(),
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

  // ── Live / off-screen preview ──
  Widget _buildApplicationPreview({double? fontSize}) {
    final segments = _buildBodySegments();
    final resolvedFontSize =
        fontSize ?? Theme.of(context).textTheme.bodyLarge?.fontSize ?? 16.0;

    final date = _dateCtrl.text.trim();
    final name = _nameCtrl.text.trim();
    final mobile = _mobileCtrl.text.trim();
    final address = _addressCtrl.text.trim();
    final accNo = _accountNumberCtrl.text.trim();

    final baseStyle = TextStyle(
      fontFamily: 'NotoSansDevanagari',
      fontSize: resolvedFontSize,
      color: const Color(0xFF212121),
      height: 1.8,
    );

    const TextStyle phStyle = TextStyle(
      color: Color(0xFF1565C0),
      fontWeight: FontWeight.w600,
      decoration: TextDecoration.underline,
      decorationColor: Color(0xFF1565C0),
      decorationStyle: TextDecorationStyle.dashed,
    );

    Widget valueText(String value, String placeholder) {
      final empty = value.isEmpty;
      return Text(
        empty ? placeholder : value,
        style: empty ? baseStyle.merge(phStyle) : baseStyle,
        softWrap: true,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Main body ──
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

        SizedBox(height: resolvedFontSize * 1.8 * 2),

        // ── Footer ──
        Align(
          alignment: Alignment.centerRight,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('भवदीय,', style: baseStyle),
              SizedBox(height: resolvedFontSize * 0.5),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('नाम: ', style: baseStyle),
                  Flexible(child: valueText(name, '……………')),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('मोबाईल: ', style: baseStyle),
                  Flexible(child: valueText(mobile, '……………')),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('पता: ', style: baseStyle),
                  Flexible(child: valueText(address, '……………')),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('खाता संख्या: ', style: baseStyle),
                  Flexible(child: valueText(accNo, '……………')),
                ],
              ),
              SizedBox(height: resolvedFontSize * 1.8),
              Text('हस्ताक्षर / अंगूठा – ………………………', style: baseStyle),
            ],
          ),
        ),

        SizedBox(height: resolvedFontSize * 1.8),

        // ── Date bottom-left ──
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
      ],
    );
  }
}

class _TextSegment {
  final String text;
  final bool isPlaceholder;
  const _TextSegment(this.text, this.isPlaceholder);
}
