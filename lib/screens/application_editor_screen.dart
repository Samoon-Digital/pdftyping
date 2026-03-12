import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../l10n/app_localizations.dart';

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

  // Key for capturing the preview widget as image for PDF
  final _previewKey = GlobalKey();

  // ── Build the application text with filled-in values ──
  List<_TextSegment> _buildApplicationSegments() {
    final branch = _branchNameCtrl.text.trim();
    final address = _branchAddressCtrl.text.trim();
    final accNo = _accountNumberCtrl.text.trim();
    final accHolder = _accountHolderCtrl.text.trim();
    final date = _dateCtrl.text.trim();
    final name = _nameCtrl.text.trim();
    final mobile = _mobileCtrl.text.trim();

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
      const _TextSegment('\n\n\n\n', false),
      const _TextSegment('दिनांक : ', false),
      _TextSegment(date.isEmpty ? 'दिनांक' : date, date.isEmpty),
      const _TextSegment(
        '                                                   नाम       : ',
        false,
      ),
      _TextSegment(name.isEmpty ? 'आपका नाम' : name, name.isEmpty),
      const _TextSegment(
        '\n                                                                         मोबाईल : ',
        false,
      ),
      _TextSegment(mobile.isEmpty ? 'मोबाइल नंबर' : mobile, mobile.isEmpty),
    ];
  }

  // ── Generate A4 PDF by capturing the Flutter preview widget as image ──
  // This guarantees correct Devanagari rendering (Flutter uses HarfBuzz shaping)
  // instead of relying on the pdf package's basic glyph lookup.
  Future<void> _generatePdf() async {
    if (!_formKey.currentState!.validate()) return;

    // Capture the preview widget (Flutter renders Hindi correctly)
    final boundary =
        _previewKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
    final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    final pngBytes = byteData!.buffer.asUint8List();

    // Build a minimal PDF that embeds the captured image
    final pdf = pw.Document();
    final pdfImage = pw.MemoryImage(pngBytes);

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context ctx) => pw.Image(pdfImage, fit: pw.BoxFit.contain),
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
    final loc = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(loc.editorTitle)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Application Preview (captured as image for PDF) ──
              RepaintBoundary(
                key: _previewKey,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
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
                  child: _buildApplicationPreview(),
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
                label: loc.branchName,
                hint: 'जैसे: स्टेट बैंक ऑफ इंडिया',
                onChanged: (_) => setState(() {}),
              ),
              _InputField(
                controller: _branchAddressCtrl,
                label: loc.branchAddress,
                hint: 'जैसे: मुख्य शाखा, जिला मुख्यालय',
                onChanged: (_) => setState(() {}),
              ),
              _InputField(
                controller: _accountNumberCtrl,
                label: loc.accountNumber,
                hint: 'जैसे: 1234567890',
                keyboardType: TextInputType.number,
                onChanged: (_) => setState(() {}),
              ),
              _InputField(
                controller: _accountHolderCtrl,
                label: loc.accountHolderName,
                hint: 'जैसे: राम प्रसाद',
                onChanged: (_) => setState(() {}),
              ),
              _InputField(
                controller: _dateCtrl,
                label: loc.date,
                hint: 'जैसे: 12/03/2026',
                onChanged: (_) => setState(() {}),
              ),
              _InputField(
                controller: _nameCtrl,
                label: loc.applicantName,
                hint: 'जैसे: राम प्रसाद',
                onChanged: (_) => setState(() {}),
              ),
              _InputField(
                controller: _mobileCtrl,
                label: loc.mobileNumber,
                hint: 'जैसे: 9876543210',
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
                  label: Text(loc.generatePdf),
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
  Widget _buildApplicationPreview() {
    final segments = _buildApplicationSegments();

    return RichText(
      text: TextSpan(
        style: const TextStyle(
          fontFamily: 'NotoSansDevanagari',
          fontSize: 15,
          color: Color(0xFF212121),
          height: 1.8,
        ),
        children: segments.map((seg) {
          if (seg.isPlaceholder) {
            return TextSpan(
              text: seg.text,
              style: const TextStyle(
                color: Color(0xFF1565C0),
                fontWeight: FontWeight.w600,
                decoration: TextDecoration.underline,
                decorationColor: Color(0xFF1565C0),
                decorationStyle: TextDecorationStyle.dashed,
              ),
            );
          }
          return TextSpan(text: seg.text);
        }).toList(),
      ),
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

  const _InputField({
    required this.controller,
    required this.label,
    required this.hint,
    this.keyboardType = TextInputType.text,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        onChanged: onChanged,
        style: const TextStyle(fontFamily: 'NotoSansDevanagari', fontSize: 15),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          labelStyle: const TextStyle(fontFamily: 'NotoSansDevanagari'),
          hintStyle: TextStyle(
            fontFamily: 'NotoSansDevanagari',
            color: Colors.grey.shade400,
          ),
        ),
        validator: (v) {
          if (v == null || v.trim().isEmpty) {
            return AppLocalizations.of(context)!.fillAllFields;
          }
          return null;
        },
      ),
    );
  }
}
