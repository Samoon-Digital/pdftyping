import 'dart:ui' as ui;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:firebase_analytics/firebase_analytics.dart';
import '../services/pdf_saver.dart';
import '../widgets/suggestible_input_field.dart';
import '../widgets/pdf_generation_widgets.dart';
import '../widgets/web_a4_layout.dart';

class ApplicationEditorScreen extends StatefulWidget {
  final VoidCallback? onPdfSaved;
  final String? editorTitle;
  const ApplicationEditorScreen({super.key, this.onPdfSaved, this.editorTitle});

  @override
  State<ApplicationEditorScreen> createState() =>
      _ApplicationEditorScreenState();
}

class _ApplicationEditorScreenState extends State<ApplicationEditorScreen> {
  final _branchNameCtrl = TextEditingController();
  final _branchAddressCtrl = TextEditingController();
  final _accountNumberCtrl = TextEditingController();
  final _accountHolderCtrl = TextEditingController();
  final _dateCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _mobileCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();

  final _formKey = GlobalKey<FormState>();

  // Track if user has manually edited the name field
  bool _nameManuallyEdited = false;
  int _step = 0;

  @override
  void initState() {
    super.initState();
    // Auto-fill name from account holder, unless user has manually edited name
    _accountHolderCtrl.addListener(() {
      if (!_nameManuallyEdited) {
        final val = _accountHolderCtrl.text;
        if (_nameCtrl.text != val) {
          _nameCtrl.text = val;
          setState(() {});
        }
      }
    });
    // Auto-fill date field with today's date on open
    final now = DateTime.now();
    _dateCtrl.text =
        '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}';
    // Analytics: log editor open with provided title (if any)
    if (!kIsWeb) {
      FirebaseAnalytics.instance.logEvent(
        name: 'editor_open',
        parameters: {
          'editor_title': widget.editorTitle ?? 'application_editor',
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

  // ── Build the main body text segments (footer handled separately) ──
  List<_TextSegment> _buildApplicationSegments() {
    final branch = _branchNameCtrl.text.trim();
    final address = _branchAddressCtrl.text.trim();
    final accNo = _accountNumberCtrl.text.trim();
    final accHolder = _accountHolderCtrl.text.trim();

    return [
      const _TextSegment('सेवा मैं', false),
      const _TextSegment('\nशाखा प्रबंधक महोदय,', false),
      const _TextSegment('\nशाखा प्रबंधक , ', false),
      _TextSegment(branch.isEmpty ? 'शाखा का नाम' : branch, branch.isEmpty),
      const _TextSegment('\n', false),
      _TextSegment(address.isEmpty ? 'शाखा का पता' : address, address.isEmpty),
      const _TextSegment('\n\n\n', false),
      const _TextSegment(
        'विषय : अपने बैंक खाते से बीमा योजनाओं को हटाने के संबंध में',
        false,
      ),
      const _TextSegment('\n\n\n', false),
      const _TextSegment(
        'सविनय , निवेदन यह है कि  मेरा बचत खाता आपकी शाखा मैं खुला हुआ जिसका नंबर ',
        false,
      ),
      _TextSegment(accNo.isEmpty ? 'खाता नंबर' : accNo, accNo.isEmpty),
      const _TextSegment(' है और यह खाता मेरे ', false),
      _TextSegment(
        accHolder.isEmpty ? 'खाताधारक का नाम' : accHolder,
        accHolder.isEmpty,
      ),
      const _TextSegment(
        ' नाम से है   मेरे बचत खाते से हर महीने  प्रधानमंत्री जीवन ज्योति बीमा योजना  / प्रधानमंत्री सुरक्षा बीमा योजना की प्रीमियम राशि कट रही है  जो अब मुझे जारी नहीं रखवानी है |',
        false,
      ),
      const _TextSegment('\n\n', false),
      const _TextSegment(
        'अत: श्रीमान जी से निवेदन है  मेरे बचत खाते से बीमा हटाने की कृपया करें और कटी हुई धनराशि वापस कराने की कृपा  करें  आपकी महान कृपा होगी | धन्यवाद।',
        false,
      ),
    ];
  }

  // ── Generate PDF by rendering at A4-width in an off-screen overlay ──
  // Avoids the "zoomed / content clipped" problem caused by capturing the
  // narrow phone-screen widget and scaling it to fill A4.
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
    // 1. Create a temporary GlobalKey for the off-screen render target.
    final pdfCaptureKey = GlobalKey();

    // 2. Insert an OverlayEntry positioned far off-screen (left: -2000).
    //    560 dp width ≈ A4 proportional width; gives full-line text without wrapping too much.
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

    // 3. Wait for Flutter to fully layout + paint the new overlay widget.
    await WidgetsBinding.instance.endOfFrame;

    // 4. Capture the off-screen widget at good quality.
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

    // 5. Remove the overlay immediately after capture.
    overlayEntry.remove();

    // 6. Standard A4 page — image width-fills the page and is anchored to the
    //    top. Remaining space below is white (correct A4 letter behaviour).
    //    SizedBox constrains the image to its natural proportional height so
    //    BoxFit.fitWidth works without distortion.  pw.Column is top-aligned by
    //    default, avoiding the vertical-centering that pw.Align would cause.
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
    final branch = _branchNameCtrl.text.trim();
    final name = _nameCtrl.text.trim();
    final now = DateTime.now();
    final stamp =
        '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}_'
        '${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}${now.second.toString().padLeft(2, '0')}';
    final safeName = name.replaceAll(RegExp(r'[^\w\u0900-\u097F ]'), '').trim();
    final safeBranch = branch
        .replaceAll(RegExp(r'[^\w\u0900-\u097F ]'), '')
        .trim();
    final fileName =
        '${safeName.isNotEmpty ? safeName : 'आवेदन'}_${safeBranch.isNotEmpty ? safeBranch : 'बैंक'}_$stamp.pdf';
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
    _branchNameCtrl.dispose();
    _branchAddressCtrl.dispose();
    _accountNumberCtrl.dispose();
    _accountHolderCtrl.dispose();
    _dateCtrl.dispose();
    _nameCtrl.dispose();
    _mobileCtrl.dispose();
    _addressCtrl.dispose();
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
          title: Text(_step == 0 ? 'आवेदन एडिटर' : 'आवेदन प्रीव्यू'),
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
              controller: _branchNameCtrl,
              fieldKey: 'bima_bank_name',
              label: 'बैंक का नाम',
              hint: 'जैसे : बैंक ऑफ बड़ोदा',
              onChanged: (_) => setState(() {}),
            ),
            SuggestibleInputField(
              controller: _branchAddressCtrl,
              fieldKey: 'bima_branch_address',
              label: 'शाखा का पता',
              hint: 'जैसे : नगला , लखीमपुर खीरी',
              onChanged: (_) => setState(() {}),
            ),
            SuggestibleInputField(
              controller: _accountNumberCtrl,
              fieldKey: 'bima_account_number',
              label: 'खाता नंबर',
              hint: 'जैसे : 1234567890',
              keyboardType: TextInputType.number,
              onChanged: (_) => setState(() {}),
            ),
            SuggestibleInputField(
              controller: _accountHolderCtrl,
              fieldKey: 'bima_account_holder',
              label: 'खाताधारक का नाम',
              hint: 'जैसे : सामून अली पुत्र अब्दुल वहाब',
              onChanged: (_) => setState(() {}),
            ),
            SuggestibleInputField(
              controller: _dateCtrl,
              fieldKey: 'bima_date',
              label: 'दिनांक',
              hint: 'जैसे : 12/03/2026',
              readOnly: true,
              onTap: _pickDate,
              suffixIcon: const Icon(Icons.calendar_today_rounded, size: 20),
            ),
            SuggestibleInputField(
              controller: _nameCtrl,
              fieldKey: 'bima_name',
              label: 'आपका नाम',
              hint: 'जैसे : राम प्रसाद',
              onChanged: (_) {
                _nameManuallyEdited = true;
                setState(() {});
              },
            ),
            SuggestibleInputField(
              controller: _mobileCtrl,
              fieldKey: 'bima_mobile',
              label: 'मोबाइल नंबर',
              hint: 'जैसे : 9876543210',
              keyboardType: TextInputType.phone,
              onChanged: (_) => setState(() {}),
            ),
            SuggestibleInputField(
              controller: _addressCtrl,
              fieldKey: 'bima_address',
              label: 'पता',
              hint: 'जैसे : ग्राम – नगला, जिला – लखीमपुर खीरी',
              onChanged: (_) => setState(() {}),
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

  // ── Live preview of the application ──
  Widget _buildApplicationPreview({double? fontSize}) {
    final segments = _buildApplicationSegments();
    final resolvedFontSize =
        fontSize ?? Theme.of(context).textTheme.bodyLarge?.fontSize ?? 16.0;

    final date = _dateCtrl.text.trim();
    final name = _nameCtrl.text.trim();
    final mobile = _mobileCtrl.text.trim();
    final address = _addressCtrl.text.trim();
    final branch = _branchNameCtrl.text.trim();
    final accNo = _accountNumberCtrl.text.trim();
    final isPdf = fontSize != null;

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

    // Returns a Text that shows placeholder styling when value is empty.
    Widget valueText(
      String value,
      String placeholder, {
      TextAlign align = TextAlign.left,
    }) {
      final empty = value.isEmpty;
      return Text(
        empty ? placeholder : value,
        style: empty ? baseStyle.merge(phStyle) : baseStyle,
        softWrap: true,
        textAlign: align,
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
                // For on-screen preview only, replace branch placeholder
                // with 'बैंक का नाम : बैंक ऑफ बड़ोदा' as requested.
                if (!isPdf && seg.text == 'शाखा का नाम') {
                  return const TextSpan(
                    text: 'बैंक का नाम : बैंक ऑफ बड़ोदा',
                    style: phStyle,
                  );
                }
                return TextSpan(text: seg.text, style: phStyle);
              }
              return TextSpan(text: seg.text);
            }).toList(),
          ),
        ),

        // Spacing before footer (≈ 2 blank lines)
        SizedBox(height: resolvedFontSize * 1.8 * 2),

        // ── Footer: भवदीय block right-aligned, then date + हस्ताक्षर row ──
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
                  Text('नाम – ', style: baseStyle),
                  Flexible(child: valueText(name, '……………')),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('पता – ', style: baseStyle),
                  Flexible(child: valueText(address, '……………')),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('मोबाइल नंबर – ', style: baseStyle),
                  Flexible(child: valueText(mobile, '……………')),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('खाता संख्या – ', style: baseStyle),
                  Flexible(child: valueText(accNo, '……………')),
                ],
              ),
            ],
          ),
        ),

        SizedBox(height: resolvedFontSize * 1.8),

        // ── Date left, हस्ताक्षर right ──
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
            Flexible(child: Text('हस्ताक्षर – ………………………', style: baseStyle)),
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
