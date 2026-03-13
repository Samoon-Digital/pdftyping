import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class ApplicationEditorScreen extends StatefulWidget {
  const ApplicationEditorScreen({super.key});

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

  final _formKey = GlobalKey<FormState>();

  // Track if user has manually edited the name field
  bool _nameManuallyEdited = false;

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
      const _TextSegment('\nश्रीमान ,', false),
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
        'अत: श्रीमान जी से निवेदन है  मेरे बचत खाते से बीमा हटाने की कृपया करें और कटी हुई धनराशि वापस कराने की कृपा  करें  आपकी महान कृपा होगी |',
        false,
      ),
    ];
  }

  // ── Generate PDF by rendering at A4-width in an off-screen overlay ──
  // Avoids the "zoomed / content clipped" problem caused by capturing the
  // narrow phone-screen widget and scaling it to fill A4.
  Future<void> _generatePdf() async {
    if (!_formKey.currentState!.validate()) return;

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
    final ui.Image image = await boundary.toImage(pixelRatio: 2.0);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    final pngBytes = byteData!.buffer.asUint8List();

    // 5. Remove the overlay immediately after capture.
    overlayEntry.remove();

    // 6. Build a PDF page with A4 width and height proportional to the
    //    captured image — so pw.BoxFit.fill maps pixels 1:1, no distortion,
    //    no clipping, full width used.
    final pdf = pw.Document();
    final pdfImage = pw.MemoryImage(pngBytes);
    final a4Width = PdfPageFormat.a4.width;
    final pageHeight = a4Width * image.height / image.width;

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat(a4Width, pageHeight),
        margin: pw.EdgeInsets.zero,
        build: (pw.Context ctx) => pw.Image(pdfImage, fit: pw.BoxFit.fill),
      ),
    );

    if (!mounted) return;
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('आवेदन एडिटर')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Application Preview (on-screen display only) ──
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

              const SizedBox(height: 24),

              // ── Input Fields ──
              Text(
                'विवरण भरें',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontFamily: 'NotoSansDevanagari',
                ),
              ),
              const SizedBox(height: 12),

              _InputField(
                controller: _branchNameCtrl,
                label: 'बैंक का नाम',
                hint: 'जैसे : बैंक ऑफ बड़ोदा',
                onChanged: (_) => setState(() {}),
              ),
              _InputField(
                controller: _branchAddressCtrl,
                label: 'शाखा का पता',
                hint: 'जैसे : नगला , लखीमपुर खीरी',
                onChanged: (_) => setState(() {}),
              ),
              _InputField(
                controller: _accountNumberCtrl,
                label: 'खाता नंबर',
                hint: 'जैसे : 1234567890',
                keyboardType: TextInputType.number,
                onChanged: (_) => setState(() {}),
              ),
              _InputField(
                controller: _accountHolderCtrl,
                label: 'खाताधारक का नाम',
                hint: 'जैसे : सामून अली पुत्र अब्दुल वहाब',
                onChanged: (_) => setState(() {}),
              ),
              // Date field — opens calendar picker on tap
              _InputField(
                controller: _dateCtrl,
                label: 'दिनांक',
                hint: 'जैसे : 12/03/2026',
                readOnly: true,
                onTap: _pickDate,
                suffixIcon: const Icon(Icons.calendar_today_rounded, size: 20),
              ),
              // Name auto-filled from account holder, remains editable
              _InputField(
                controller: _nameCtrl,
                label: 'आपका नाम',
                hint: 'जैसे : राम प्रसाद',
                onChanged: (_) {
                  _nameManuallyEdited = true;
                  setState(() {});
                },
              ),
              _InputField(
                controller: _mobileCtrl,
                label: 'मोबाइल नंबर',
                hint: 'जैसे : 9876543210',
                keyboardType: TextInputType.phone,
                onChanged: (_) => setState(() {}),
              ),

              const SizedBox(height: 20),

              // ── Generate PDF Button ──
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
        ),
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
    final branch = _branchNameCtrl.text.trim();
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

        // Spacing before footer (≈ 3 blank lines)
        SizedBox(height: resolvedFontSize * 1.8 * 3),

        // ── Footer: date left, name+mobile right with aligned values ──
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date (left side — takes its natural width)
            RichText(
              text: TextSpan(
                style: baseStyle,
                children: [
                  const TextSpan(text: 'दिनांक : '),
                  TextSpan(
                    text: date.isEmpty ? 'दिनांक' : date,
                    style: date.isEmpty ? phStyle : null,
                  ),
                ],
              ),
            ),

            const Spacer(),

            // Name + Mobile — IntrinsicWidth shrinks Table to content,
            // Spacer above pushes the whole block to the right edge.
            IntrinsicWidth(
              child: Table(
                defaultVerticalAlignment: TableCellVerticalAlignment.top,
                columnWidths: const {
                  0: IntrinsicColumnWidth(), // label — auto-sizes to widest label
                  1: IntrinsicColumnWidth(), // value — sizes to content (no flex needed)
                },
                children: [
                  TableRow(
                    children: [
                      Text('नाम : ', style: baseStyle),
                      valueText(name, 'आपका नाम'),
                    ],
                  ),
                  TableRow(
                    children: [
                      Text('मोबाईल : ', style: baseStyle),
                      valueText(mobile, 'मोबाइल नंबर'),
                    ],
                  ),
                ],
              ),
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

// ── Reusable input field ──
class _InputField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final TextInputType keyboardType;
  final ValueChanged<String>? onChanged;
  final bool readOnly;
  final VoidCallback? onTap;
  final Widget? suffixIcon;

  const _InputField({
    required this.controller,
    required this.label,
    required this.hint,
    this.keyboardType = TextInputType.text,
    this.onChanged,
    this.readOnly = false,
    this.onTap,
    this.suffixIcon,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        onChanged: onChanged,
        readOnly: readOnly,
        onTap: onTap,
        style: const TextStyle(fontFamily: 'NotoSansDevanagari', fontSize: 16),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          labelStyle: const TextStyle(fontFamily: 'NotoSansDevanagari'),
          hintStyle: TextStyle(
            fontFamily: 'NotoSansDevanagari',
            color: Colors.grey.shade400,
          ),
          suffixIcon: suffixIcon,
        ),
        validator: (v) {
          if (v == null || v.trim().isEmpty) {
            return 'कृपया सभी फ़ील्ड भरें';
          }
          return null;
        },
      ),
    );
  }
}
