import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class MobileUpdateEditorScreen extends StatefulWidget {
  final VoidCallback? onPdfSaved;
  const MobileUpdateEditorScreen({super.key, this.onPdfSaved});

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

  @override
  void initState() {
    super.initState();
    // Auto-fill date with today's date
    final now = DateTime.now();
    _dateCtrl.text =
        '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}';
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
      _TextSegment(
        bankName.isEmpty ? '………… बैंक' : '$bankName बैंक',
        bankName.isEmpty,
      ),
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
    if (!_formKey.currentState!.validate()) return;

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
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    final pngBytes = byteData!.buffer.asUint8List();

    overlayEntry.remove();

    final pdf = pw.Document();
    final pdfImage = pw.MemoryImage(pngBytes);
    final a4Width = PdfPageFormat.a4.width;
    final renderHeight = a4Width * image.height / image.width;

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
    final file = File('${docsDir.path}/$fileName');
    await file.writeAsBytes(pdfBytes);

    if (!mounted) return;
    widget.onPdfSaved?.call();
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text(
          'PDF सेव हो गई! Saved में देखें।',
          style: TextStyle(fontFamily: 'NotoSansDevanagari'),
        ),
        backgroundColor: const Color(0xFF1565C0),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 3),
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
    return Scaffold(
      appBar: AppBar(title: const Text('मोबाइल नंबर अपडेट आवेदन')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Application Preview ──
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

              Text(
                'विवरण भरें',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontFamily: 'NotoSansDevanagari',
                ),
              ),
              const SizedBox(height: 12),

              _InputField(
                controller: _bankNameCtrl,
                label: 'बैंक का नाम',
                hint: 'जैसे : बैंक ऑफ बड़ोदा',
                onChanged: (_) => setState(() {}),
              ),
              _InputField(
                controller: _branchNameCtrl,
                label: 'शाखा का नाम',
                hint: 'जैसे : नगला , लखीमपुर खीरी',
                onChanged: (_) => setState(() {}),
              ),
              _InputField(
                controller: _nameCtrl,
                label: 'आपका नाम',
                hint: 'जैसे : राम प्रसाद',
                onChanged: (_) => setState(() {}),
              ),
              _InputField(
                controller: _accountNumberCtrl,
                label: 'खाता संख्या',
                hint: 'जैसे : 1234567890',
                keyboardType: TextInputType.number,
                onChanged: (_) => setState(() {}),
              ),
              _InputField(
                controller: _oldMobileCtrl,
                label: 'पुराना मोबाइल नंबर',
                hint: 'जैसे : 9876543210',
                keyboardType: TextInputType.phone,
                onChanged: (_) => setState(() {}),
              ),
              _InputField(
                controller: _newMobileCtrl,
                label: 'नया मोबाइल नंबर',
                hint: 'जैसे : 9123456789',
                keyboardType: TextInputType.phone,
                onChanged: (_) => setState(() {}),
              ),
              _InputField(
                controller: _addressCtrl,
                label: 'पता',
                hint: 'जैसे : ग्राम – नगला, जिला – लखीमपुर खीरी',
                onChanged: (_) => setState(() {}),
              ),
              _InputField(
                controller: _dateCtrl,
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

        // ── Footer: right-aligned भवदीय block ──
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
                  valueText(name, '……………'),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('पता – ', style: baseStyle),
                  valueText(address, '……………'),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('मोबाइल नंबर – ', style: baseStyle),
                  valueText(mobile, '……………'),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('खाता संख्या – ', style: baseStyle),
                  valueText(accNo, '……………'),
                ],
              ),
              SizedBox(height: resolvedFontSize * 1.8),
              Text('हस्ताक्षर – ……………', style: baseStyle),
            ],
          ),
        ),

        SizedBox(height: resolvedFontSize * 1.8),

        // ── Date (left-aligned) ──
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

// ── Text segment ──
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
          suffixIcon: suffixIcon == null
              ? null
              : GestureDetector(onTap: onTap, child: suffixIcon),
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
