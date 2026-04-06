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

class MobileUpdateEditorScreen extends StatefulWidget {
  final VoidCallback? onPdfSaved;
  final String? editorTitle;
  const MobileUpdateEditorScreen({
    super.key,
    this.onPdfSaved,
    this.editorTitle,
  });

  @override
  State<MobileUpdateEditorScreen> createState() =>
      _MobileUpdateEditorScreenState();
}

class _MobileUpdateEditorScreenState extends State<MobileUpdateEditorScreen> {
  final _bankNameCtrl = TextEditingController();
  final _branchNameCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _accountNumberCtrl = TextEditingController();
  final _oldMobileCtrl = TextEditingController();
  final _newMobileCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _dateCtrl = TextEditingController();

  final _formKey = GlobalKey<FormState>();
  int _step = 0;

  @override
  void initState() {
    super.initState();
    // Auto-fill date with today's date
    final now = DateTime.now();
    _dateCtrl.text =
        '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}';

    if (!kIsWeb) {
      FirebaseAnalytics.instance.logEvent(
        name: 'editor_open',
        parameters: {
          'editor_title': widget.editorTitle ?? 'mobile_update_editor',
        },
      );
    }
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
      final formatted =
          '${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}';
      _dateCtrl.text = formatted;
      setState(() {});
    }
  }

  // ── Build the main body text segments ──
  List<_TextSegment> _buildApplicationSegments() {
    final bankName = _bankNameCtrl.text.trim();
    final branchName = _branchNameCtrl.text.trim();
    final name = _nameCtrl.text.trim();
    final accNo = _accountNumberCtrl.text.trim();
    final oldMobile = _oldMobileCtrl.text.trim();
    final newMobile = _newMobileCtrl.text.trim();

    return [
      const _TextSegment('सेवा में,', false),
      const _TextSegment('\nशाखा प्रबंधक महोदय,', false),
      const _TextSegment('\n', false),
      _TextSegment(bankName.isEmpty ? '…………' : bankName, bankName.isEmpty),
      const _TextSegment('\nशाखा – ', false),
      _TextSegment(
        branchName.isEmpty ? '…………' : branchName,
        branchName.isEmpty,
      ),
      const _TextSegment('\n\n', false),
      const _TextSegment(
        'विषय: बचत खाते में मोबाइल नंबर परिवर्तन हेतु आवेदन।',
        false,
      ),
      const _TextSegment('\n\n', false),
      const _TextSegment('महोदय,', false),
      const _TextSegment('\n\n', false),
      const _TextSegment('सविनय निवेदन है कि मेरा नाम ', false),
      _TextSegment(name.isEmpty ? '……………' : name, name.isEmpty),
      const _TextSegment(' है। मेरा आपके बैंक की शाखा ', false),
      _TextSegment(
        branchName.isEmpty ? '……………' : branchName,
        branchName.isEmpty,
      ),
      const _TextSegment(' में एक बचत खाता है, जिसका खाता संख्या ', false),
      _TextSegment(accNo.isEmpty ? '……………' : accNo, accNo.isEmpty),
      const _TextSegment(' है।', false),
      const _TextSegment('\n\n', false),
      const _TextSegment(
        'किसी कारणवश मेरे खाते में पंजीकृत (Registered) मोबाइल नंबर अब उपयोग में नहीं है। अतः आपसे निवेदन है कि मेरे खाते में दर्ज पुराने मोबाइल नंबर ',
        false,
      ),
      _TextSegment(oldMobile.isEmpty ? '……………' : oldMobile, oldMobile.isEmpty),
      const _TextSegment(' को हटाकर नया मोबाइल नंबर ', false),
      _TextSegment(newMobile.isEmpty ? '……………' : newMobile, newMobile.isEmpty),
      const _TextSegment(
        ' अपडेट करने की कृपा करें। जिससे मुझे बैंक से संबंधित सभी सूचनाएँ प्राप्त होती रहें।',
        false,
      ),
      const _TextSegment('\n\n\n', false),
      const _TextSegment('धन्यवाद।', false),
    ];
  }

  // ── Generate PDF ──
  Future<void> _generatePdf() async {
    // Show loading dialog while rendering
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
      if (mounted) Navigator.of(context).pop(); // dismiss loading dialog
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
    // Crop bottom 8px to remove the anti-aliasing artifact line.
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
    final bank = _bankNameCtrl.text.trim();
    final now = DateTime.now();
    final stamp =
        '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}_'
        '${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}${now.second.toString().padLeft(2, '0')}';
    final safeName = name.replaceAll(RegExp(r'[^\w\u0900-\u097F ]'), '').trim();
    final safeBank = bank.replaceAll(RegExp(r'[^\w\u0900-\u097F ]'), '').trim();
    final fileName =
        'मोबाइल_${safeName.isNotEmpty ? safeName : 'आवेदन'}_${safeBank.isNotEmpty ? safeBank : 'बैंक'}_$stamp.pdf';
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

    // Mobile: save to app documents directory
    await savePdfToDocuments(bytes: pdfBytes, fileName: fileName);

    if (!mounted) return;

    // Dismiss loading dialog
    Navigator.of(context).pop();

    if (!mounted) return;

    // Show success sheet — user explicitly chooses what to do next
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
          Navigator.of(context).pop(); // dismiss sheet, stay on editor
        },
      ),
    );
  }

  @override
  void dispose() {
    _bankNameCtrl.dispose();
    _branchNameCtrl.dispose();
    _nameCtrl.dispose();
    _accountNumberCtrl.dispose();
    _oldMobileCtrl.dispose();
    _newMobileCtrl.dispose();
    _addressCtrl.dispose();
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
            _step == 0 ? 'मोबाइल नंबर अपडेट आवेदन' : 'आवेदन प्रीव्यू',
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
              fieldKey: 'mob_bank_name',
              label: 'बैंक का नाम',
              hint: 'जैसे : बैंक ऑफ बड़ोदा',
              onChanged: (_) => setState(() {}),
            ),
            SuggestibleInputField(
              controller: _branchNameCtrl,
              fieldKey: 'mob_branch_name',
              label: 'शाखा का नाम',
              hint: 'जैसे : नगला , लखीमपुर खीरी',
              onChanged: (_) => setState(() {}),
            ),
            SuggestibleInputField(
              controller: _nameCtrl,
              fieldKey: 'mob_name',
              label: 'आपका नाम',
              hint: 'जैसे : राम प्रसाद',
              onChanged: (_) => setState(() {}),
            ),
            SuggestibleInputField(
              controller: _accountNumberCtrl,
              fieldKey: 'mob_account_number',
              label: 'खाता संख्या',
              hint: 'जैसे : 1234567890',
              keyboardType: TextInputType.number,
              onChanged: (_) => setState(() {}),
            ),
            SuggestibleInputField(
              controller: _oldMobileCtrl,
              fieldKey: 'mob_old_mobile',
              label: 'पुराना मोबाइल नंबर',
              hint: 'जैसे : 9876543210',
              keyboardType: TextInputType.phone,
              onChanged: (_) => setState(() {}),
            ),
            SuggestibleInputField(
              controller: _newMobileCtrl,
              fieldKey: 'mob_new_mobile',
              label: 'नया मोबाइल नंबर',
              hint: 'जैसे : 9123456789',
              keyboardType: TextInputType.phone,
              onChanged: (_) => setState(() {}),
            ),
            SuggestibleInputField(
              controller: _addressCtrl,
              fieldKey: 'mob_address',
              label: 'पता',
              hint: 'जैसे : ग्राम – नगला, जिला – लखीमपुर खीरी',
              onChanged: (_) => setState(() {}),
            ),
            SuggestibleInputField(
              controller: _dateCtrl,
              fieldKey: 'mob_date',
              label: 'दिनांक',
              hint: 'जैसे : 13/03/2026',
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

  // ── Live preview ──
  Widget _buildApplicationPreview({double? fontSize}) {
    final segments = _buildApplicationSegments();
    final resolvedFontSize =
        fontSize ?? Theme.of(context).textTheme.bodyLarge?.fontSize ?? 16.0;

    final date = _dateCtrl.text.trim();
    final name = _nameCtrl.text.trim();
    final address = _addressCtrl.text.trim();
    final mobile = _newMobileCtrl.text.trim();
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

        // ── Footer: date bottom-left, भवदीय+signature bottom-right ──
        // crossAxisAlignment.end ensures date and हस्ताक्षर are on the same
        // horizontal line; signature naturally aligns with भवदीय block above it.
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Date — bottom-left
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
            // Spacer pushes right block to right edge
            const SizedBox(width: 16),
            // भवदीय block + signature (same column → perfect alignment)
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('भवदीय,', style: baseStyle),
                  SizedBox(height: resolvedFontSize * 0.5),
                  Row(
                    children: [
                      Text('नाम – ', style: baseStyle),
                      Expanded(child: valueText(name, '……………')),
                    ],
                  ),
                  Row(
                    children: [
                      Text('पता – ', style: baseStyle),
                      Expanded(child: valueText(address, '……………')),
                    ],
                  ),
                  Row(
                    children: [
                      Text('मोबाइल नंबर – ', style: baseStyle),
                      Expanded(child: valueText(mobile, '……………')),
                    ],
                  ),
                  Row(
                    children: [
                      Text('खाता संख्या – ', style: baseStyle),
                      Expanded(child: valueText(accNo, '……………')),
                    ],
                  ),
                  SizedBox(height: resolvedFontSize * 1.8),
                  Text('हस्ताक्षर – ………………………………………', style: baseStyle),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ── Text segment ──
class _TextSegment {
  final String text;
  final bool isPlaceholder;
  const _TextSegment(this.text, this.isPlaceholder);
}
