import 'dart:ui' as ui;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../services/pdf_saver.dart';
import '../widgets/pdf_generation_widgets.dart';
import '../widgets/web_a4_layout.dart';

class CustomLayoutOneEditorScreen extends StatefulWidget {
  final VoidCallback? onPdfSaved;

  const CustomLayoutOneEditorScreen({super.key, this.onPdfSaved});

  @override
  State<CustomLayoutOneEditorScreen> createState() =>
      _CustomLayoutOneEditorScreenState();
}

class _CustomLayoutOneEditorScreenState
    extends State<CustomLayoutOneEditorScreen> {
  static const _recipientHint =
      'सेवा में,\nश्रीमान प्रधानाचार्य महोदय,\nसरस्वती इंटर कॉलेज,\nकानपुर (उत्तर प्रदेश)';
  static const _subjectHint = 'अवकाश के लिए आवेदन पत्र';
  static const _bodyHint =
      'सविनय निवेदन है कि मैं कक्षा 10 का छात्र हूँ। मुझे कल से तेज बुखार है, जिसके कारण मैं विद्यालय आने में असमर्थ हूँ। अतः आपसे निवेदन है कि मुझे दिनांक 23/03/2026 से 25/03/2026 तक अवकाश प्रदान करने की कृपा करें।';
  static const _gratitudeHint =
      'मैं आपके इस उपकार के लिए सदा आभारी रहूँगा। धन्यवाद';

  final _recipientCtrl = TextEditingController();
  final _subjectCtrl = TextEditingController();
  final _bodyCtrl = TextEditingController();
  final _gratitudeCtrl = TextEditingController();
  final _footerCtrl = TextEditingController();

  late final String _footerHint;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    final formattedDate =
        '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}';
    _footerHint =
        'भवदीय,\nआपका आज्ञाकारी शिष्य,\nराहुल कुमार\nकक्षा - 10\nअनुक्रमांक - 15\nदिनांक - $formattedDate';
  }

  @override
  void dispose() {
    _recipientCtrl.dispose();
    _subjectCtrl.dispose();
    _bodyCtrl.dispose();
    _gratitudeCtrl.dispose();
    _footerCtrl.dispose();
    super.dispose();
  }

  bool _validateInputs() {
    final sections = <(TextEditingController, String)>[
      (_recipientCtrl, 'संबोधन और प्राप्तकर्ता'),
      (_subjectCtrl, 'विषय'),
      (_bodyCtrl, 'मुख्य आवेदन सामग्री'),
      (_gratitudeCtrl, 'समापन पंक्ति'),
      (_footerCtrl, 'फुटर'),
    ];

    for (final section in sections) {
      if (section.$1.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'कृपया ${section.$2} भरें',
              style: const TextStyle(fontFamily: 'NotoSansDevanagari'),
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return false;
      }
    }

    return true;
  }

  Future<void> _generatePdf() async {
    if (!_validateInputs()) {
      return;
    }

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
      if (mounted) {
        Navigator.of(context).pop();
      }
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
    final image = await boundary.toImage(pixelRatio: 4.0);

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

    final now = DateTime.now();
    final stamp =
        '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}_'
        '${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}${now.second.toString().padLeft(2, '0')}';
    final safeSubject = _subjectCtrl.text
        .trim()
        .replaceAll(RegExp(r'[^\w\u0900-\u097F ]'), '')
        .trim();
    final fileName =
        '${safeSubject.isNotEmpty ? safeSubject : 'आवेदन'}_लेआउट1_$stamp.pdf';
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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('लेआउट 1 एडिटर')),
      body: WebA4Layout(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildInfoCard(),
              const SizedBox(height: 16),
              _buildSectionCard(
                title: '1. संबोधन और प्राप्तकर्ता',
                description:
                    'पत्र की शुरुआत और receiver details एक box में लिखें।',
                child: _EditorSectionField(
                  controller: _recipientCtrl,
                  hint: _recipientHint,
                  minLines: 5,
                  maxLines: 7,
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(height: 14),
              _buildSectionCard(
                title: '2. विषय',
                description: 'यह box केवल subject line के लिए है।',
                child: _EditorSectionField(
                  controller: _subjectCtrl,
                  hint: _subjectHint,
                  minLines: 1,
                  maxLines: 2,
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(height: 14),
              _buildSectionCard(
                title: '3. मुख्य आवेदन',
                description: 'जो paragraph PDF में दिखाना है, वह यहां लिखें।',
                child: _EditorSectionField(
                  controller: _bodyCtrl,
                  hint: _bodyHint,
                  minLines: 7,
                  maxLines: 10,
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(height: 14),
              _buildSectionCard(
                title: '4. समापन पंक्ति',
                description: 'धन्यवाद या अंतिम निवेदन वाली line यहां लिखें।',
                child: _EditorSectionField(
                  controller: _gratitudeCtrl,
                  hint: _gratitudeHint,
                  minLines: 3,
                  maxLines: 5,
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(height: 14),
              _buildSectionCard(
                title: '5. फुटर',
                description:
                    'नीचे की पूरी signature/details block एक ही Hindi box में लिखें।',
                child: _EditorSectionField(
                  controller: _footerCtrl,
                  hint: _footerHint,
                  minLines: 6,
                  maxLines: 8,
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(height: 20),
              _buildPreviewCard(),
              const SizedBox(height: 20),
              SizedBox(
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _generatePdf,
                  icon: const Icon(Icons.picture_as_pdf_rounded),
                  label: const Text('पीडीएफ बनाएं'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFCF7E8),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF1D08A)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFE7B0),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.keyboard_voice_outlined,
                  color: Color(0xFF8A5300),
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'हिंदी voice typing के लिए native keyboard इस्तेमाल करें',
                  style: TextStyle(
                    fontFamily: 'NotoSansDevanagari',
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF4A3310),
                    height: 1.3,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'किसी भी box पर tap करें, keyboard खोलें, फिर Gboard या iPhone keyboard के mic button से सीधे Hindi में बोलें। इससे user ko sabse native, fast aur accurate typing experience milega.',
            style: TextStyle(
              fontFamily: 'NotoSansDevanagari',
              fontSize: 13,
              height: 1.5,
              color: Color(0xFF6C4B16),
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: const <Widget>[
              _NativeTipChip(label: '1. Box par tap karein'),
              _NativeTipChip(label: '2. Keyboard ka mic dabayein'),
              _NativeTipChip(label: '3. Hindi me bolte jaiye'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required String description,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontFamily: 'NotoSansDevanagari',
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: const TextStyle(
              fontFamily: 'NotoSansDevanagari',
              fontSize: 12.5,
              height: 1.45,
              color: Color(0xFF475569),
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _buildPreviewCard() {
    return Container(
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'लाइव प्रीव्यू',
                style: TextStyle(
                  fontFamily: 'NotoSansDevanagari',
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 14),
              _buildApplicationPreview(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildApplicationPreview({double? fontSize}) {
    final resolvedFontSize =
        fontSize ?? Theme.of(context).textTheme.bodyLarge?.fontSize ?? 16.0;

    final baseStyle = TextStyle(
      fontFamily: 'NotoSansDevanagari',
      fontSize: resolvedFontSize,
      color: const Color(0xFF212121),
      height: 1.8,
    );

    const placeholderStyle = TextStyle(
      color: Color(0xFF1565C0),
      fontWeight: FontWeight.w600,
      decoration: TextDecoration.underline,
      decorationColor: Color(0xFF1565C0),
      decorationStyle: TextDecorationStyle.dashed,
    );

    Widget block(String value, String placeholder, {TextAlign? textAlign}) {
      final empty = value.trim().isEmpty;
      return Text(
        empty ? placeholder : value.trim(),
        textAlign: textAlign,
        style: empty ? baseStyle.merge(placeholderStyle) : baseStyle,
      );
    }

    final recipient = _recipientCtrl.text.trim();
    final subject = _subjectCtrl.text.trim();
    final body = _bodyCtrl.text.trim();
    final gratitude = _gratitudeCtrl.text.trim();
    final footer = _footerCtrl.text.trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        block(recipient, _recipientHint),
        SizedBox(height: resolvedFontSize * 1.4),
        RichText(
          text: TextSpan(
            style: baseStyle,
            children: [
              const TextSpan(text: 'विषय: '),
              TextSpan(
                text: subject.isEmpty ? _subjectHint : subject,
                style: subject.isEmpty ? placeholderStyle : null,
              ),
            ],
          ),
        ),
        SizedBox(height: resolvedFontSize * 1.2),
        Text('महोदय,', style: baseStyle),
        SizedBox(height: resolvedFontSize * 1.2),
        block(body, _bodyHint),
        SizedBox(height: resolvedFontSize * 1.2),
        block(gratitude, _gratitudeHint),
        SizedBox(height: resolvedFontSize * 2.0),
        block(footer, _footerHint),
      ],
    );
  }
}

class _EditorSectionField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final int minLines;
  final int maxLines;
  final ValueChanged<String>? onChanged;

  const _EditorSectionField({
    required this.controller,
    required this.hint,
    required this.minLines,
    required this.maxLines,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      minLines: minLines,
      maxLines: maxLines,
      onChanged: onChanged,
      textCapitalization: TextCapitalization.sentences,
      keyboardType: maxLines == 1
          ? TextInputType.text
          : TextInputType.multiline,
      textInputAction: maxLines == 1
          ? TextInputAction.next
          : TextInputAction.newline,
      style: const TextStyle(
        fontFamily: 'NotoSansDevanagari',
        fontSize: 16,
        height: 1.45,
      ),
      decoration: InputDecoration(
        hintText: hint,
        alignLabelWithHint: true,
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        contentPadding: const EdgeInsets.all(16),
        hintStyle: TextStyle(
          fontFamily: 'NotoSansDevanagari',
          color: Colors.grey.shade500,
          height: 1.45,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFD7DEE7)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFD7DEE7)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFB7791F), width: 1.6),
        ),
      ),
    );
  }
}

class _NativeTipChip extends StatelessWidget {
  final String label;

  const _NativeTipChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFE8C979)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontFamily: 'NotoSansDevanagari',
          fontSize: 12.5,
          fontWeight: FontWeight.w600,
          color: Color(0xFF7A520F),
        ),
      ),
    );
  }
}
