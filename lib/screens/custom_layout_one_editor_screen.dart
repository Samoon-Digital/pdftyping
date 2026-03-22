import 'dart:ui' as ui;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../services/pdf_saver.dart';
import '../widgets/pdf_generation_widgets.dart';

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
  final _dateCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _classCtrl = TextEditingController();
  final _rollNoCtrl = TextEditingController();

  int _step = 0;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _dateCtrl.text =
        '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}';
  }

  @override
  void dispose() {
    _recipientCtrl.dispose();
    _subjectCtrl.dispose();
    _bodyCtrl.dispose();
    _gratitudeCtrl.dispose();
    _dateCtrl.dispose();
    _nameCtrl.dispose();
    _classCtrl.dispose();
    _rollNoCtrl.dispose();
    super.dispose();
  }

  int get _reviewStep => 5;

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

  bool _validateCurrentStep() {
    String? message;
    switch (_step) {
      case 0:
        if (_recipientCtrl.text.trim().isEmpty) {
          message = 'कृपया संबोधन और प्राप्तकर्ता का टेक्स्ट लिखें';
        }
        break;
      case 1:
        if (_subjectCtrl.text.trim().isEmpty) {
          message = 'कृपया विषय लिखें';
        }
        break;
      case 2:
        if (_bodyCtrl.text.trim().isEmpty) {
          message = 'कृपया आवेदन की मुख्य सामग्री लिखें';
        }
        break;
      case 3:
        if (_gratitudeCtrl.text.trim().isEmpty) {
          message = 'कृपया धन्यवाद या समापन पंक्ति लिखें';
        }
        break;
      case 4:
        if (_nameCtrl.text.trim().isEmpty ||
            _classCtrl.text.trim().isEmpty ||
            _rollNoCtrl.text.trim().isEmpty ||
            _dateCtrl.text.trim().isEmpty) {
          message = 'कृपया footer की सभी details भरें';
        }
        break;
      default:
        break;
    }

    if (message != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            message,
            style: const TextStyle(fontFamily: 'NotoSansDevanagari'),
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return false;
    }
    return true;
  }

  void _nextStep() {
    if (_step < _reviewStep && !_validateCurrentStep()) {
      return;
    }
    setState(() => _step = (_step + 1).clamp(0, _reviewStep));
  }

  void _previousStep() {
    if (_step == 0) {
      Navigator.of(context).maybePop();
      return;
    }
    setState(() => _step -= 1);
  }

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
    final safeName = _nameCtrl.text
        .trim()
        .replaceAll(RegExp(r'[^\w\u0900-\u097F ]'), '')
        .trim();
    final safeSubject = _subjectCtrl.text
        .trim()
        .replaceAll(RegExp(r'[^\w\u0900-\u097F ]'), '')
        .trim();
    final fileName =
        '${safeName.isNotEmpty ? safeName : 'आवेदन'}_${safeSubject.isNotEmpty ? safeSubject : 'लेआउट1'}_$stamp.pdf';
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
          final nav = Navigator.of(context);
          nav.pop();
          nav.pop();
          widget.onPdfSaved?.call();
        },
        onMakeAnother: () {
          Navigator.of(context).pop();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _step == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          setState(() => _step -= 1);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            _step == _reviewStep ? 'लेआउट 1 प्रीव्यू' : 'लेआउट 1 एडिटर',
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: _previousStep,
          ),
        ),
        body: _step == _reviewStep ? _buildReviewStep() : _buildStepBody(),
      ),
    );
  }

  Widget _buildStepBody() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildProgressCard(),
          const SizedBox(height: 16),
          _buildStepIntro(),
          const SizedBox(height: 16),
          _buildActiveStepCard(),
          const SizedBox(height: 18),
          Row(
            children: [
              if (_step > 0)
                Expanded(
                  child: OutlinedButton(
                    onPressed: _previousStep,
                    child: const Text('पिछला स्टेप'),
                  ),
                ),
              if (_step > 0) const SizedBox(width: 12),
              Expanded(
                flex: _step > 0 ? 1 : 2,
                child: SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _nextStep,
                    child: Text(_step == 4 ? 'प्रीव्यू देखें' : 'अगला स्टेप'),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProgressCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'स्टेप ${_step + 1} / 6',
            style: const TextStyle(
              fontFamily: 'NotoSansDevanagari',
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1565C0),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: List.generate(6, (index) {
              final isDone = index <= _step;
              return Expanded(
                child: Container(
                  height: 6,
                  margin: EdgeInsets.only(right: index == 5 ? 0 : 6),
                  decoration: BoxDecoration(
                    color: isDone
                        ? const Color(0xFF1565C0)
                        : const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildStepIntro() {
    final config = _stepConfig();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFBFDBFE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            config.title,
            style: const TextStyle(
              fontFamily: 'NotoSansDevanagari',
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            config.description,
            style: const TextStyle(
              fontFamily: 'NotoSansDevanagari',
              fontSize: 13,
              height: 1.45,
              color: Color(0xFF334155),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveStepCard() {
    switch (_step) {
      case 0:
        return _buildEditorCard(
          child: _MultilineStepField(
            controller: _recipientCtrl,
            label: 'संबोधन और प्राप्तकर्ता',
            hint: _recipientHint,
            minLines: 5,
            maxLines: 7,
            onChanged: (_) => setState(() {}),
          ),
        );
      case 1:
        return _buildEditorCard(
          child: Column(
            children: [
              _SingleLineStepField(
                controller: _subjectCtrl,
                label: 'विषय',
                hint: _subjectHint,
                prefix: 'विषय: ',
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 12),
              _FixedLinePreview(
                label: 'स्वतः जुड़ने वाला टेक्स्ट',
                value: 'महोदय,',
              ),
            ],
          ),
        );
      case 2:
        return _buildEditorCard(
          child: _MultilineStepField(
            controller: _bodyCtrl,
            label: 'मुख्य आवेदन सामग्री',
            hint: _bodyHint,
            minLines: 7,
            maxLines: 10,
            onChanged: (_) => setState(() {}),
          ),
        );
      case 3:
        return _buildEditorCard(
          child: _MultilineStepField(
            controller: _gratitudeCtrl,
            label: 'समापन पंक्ति',
            hint: _gratitudeHint,
            minLines: 3,
            maxLines: 5,
            onChanged: (_) => setState(() {}),
          ),
        );
      case 4:
        return _buildEditorCard(
          child: Column(
            children: [
              _SingleLineStepField(
                controller: _dateCtrl,
                label: 'दिनांक',
                hint: '22/03/2026',
                readOnly: true,
                onTap: _pickDate,
                suffixIcon: const Icon(Icons.calendar_today_rounded, size: 20),
              ),
              const SizedBox(height: 12),
              _SingleLineStepField(
                controller: _nameCtrl,
                label: 'नाम',
                hint: 'राहुल कुमार',
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 12),
              _SingleLineStepField(
                controller: _classCtrl,
                label: 'कक्षा',
                hint: '10',
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 12),
              _SingleLineStepField(
                controller: _rollNoCtrl,
                label: 'अनुक्रमांक',
                hint: '15',
                keyboardType: TextInputType.number,
                onChanged: (_) => setState(() {}),
              ),
            ],
          ),
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildEditorCard({required Widget child}) {
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
      child: child,
    );
  }

  Widget _buildReviewStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFBFDBFE)),
            ),
            child: const Text(
              'यह final preview है। इसी format में PDF generate होगी।',
              style: TextStyle(
                fontFamily: 'NotoSansDevanagari',
                fontSize: 13,
                height: 1.4,
                color: Color(0xFF334155),
              ),
            ),
          ),
          const SizedBox(height: 16),
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
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _previousStep,
                  child: const Text('संपादन करें'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SizedBox(
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: _generatePdf,
                    icon: const Icon(Icons.picture_as_pdf_rounded),
                    label: const Text('पीडीएफ बनाएं'),
                  ),
                ),
              ),
            ],
          ),
        ],
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
    final date = _dateCtrl.text.trim();
    final name = _nameCtrl.text.trim();
    final className = _classCtrl.text.trim();
    final rollNo = _rollNoCtrl.text.trim();

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
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: RichText(
                text: TextSpan(
                  style: baseStyle,
                  children: [
                    const TextSpan(text: 'दिनांक: '),
                    TextSpan(
                      text: date.isEmpty ? '22/03/2026' : date,
                      style: date.isEmpty ? placeholderStyle : null,
                    ),
                  ],
                ),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('भवदीय,', style: baseStyle),
                block(name, 'राहुल कुमार'),
                RichText(
                  text: TextSpan(
                    style: baseStyle,
                    children: [
                      const TextSpan(text: 'कक्षा – '),
                      TextSpan(
                        text: className.isEmpty ? '10' : className,
                        style: className.isEmpty ? placeholderStyle : null,
                      ),
                    ],
                  ),
                ),
                RichText(
                  text: TextSpan(
                    style: baseStyle,
                    children: [
                      const TextSpan(text: 'अनुक्रमांक – '),
                      TextSpan(
                        text: rollNo.isEmpty ? '15' : rollNo,
                        style: rollNo.isEmpty ? placeholderStyle : null,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  _StepConfig _stepConfig() {
    switch (_step) {
      case 0:
        return const _StepConfig(
          title: 'स्टेप 1: प्रारंभिक संबोधन',
          description:
              'यही टेक्स्ट PDF के सबसे ऊपर वैसा ही सेट होगा जैसा आप यहाँ लिखेंगे।',
        );
      case 1:
        return const _StepConfig(
          title: 'स्टेप 2: विषय',
          description:
              'विषय: prefix fixed रहेगा। उसके बाद का विषय आप अपने हिसाब से लिखें। “महोदय,” अपने आप जुड़ेगा।',
        );
      case 2:
        return const _StepConfig(
          title: 'स्टेप 3: मुख्य आवेदन सामग्री',
          description:
              'यह आवेदन का मुख्य body section है। जो लिखेंगे वही paragraph preview और PDF में जाएगा।',
        );
      case 3:
        return const _StepConfig(
          title: 'स्टेप 4: धन्यवाद / समापन',
          description: 'इस हिस्से में अंतिम निवेदन या धन्यवाद की पंक्ति लिखें।',
        );
      case 4:
        return const _StepConfig(
          title: 'स्टेप 5: Footer details',
          description:
              'दिनांक, नाम, कक्षा और अनुक्रमांक भरें। Footer preview में नीचे दिखाई देगा।',
        );
      default:
        return const _StepConfig(title: '', description: '');
    }
  }
}

class _StepConfig {
  final String title;
  final String description;

  const _StepConfig({required this.title, required this.description});
}

class _MultilineStepField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final int minLines;
  final int maxLines;
  final ValueChanged<String>? onChanged;

  const _MultilineStepField({
    required this.controller,
    required this.label,
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
      style: const TextStyle(
        fontFamily: 'NotoSansDevanagari',
        fontSize: 16,
        height: 1.45,
      ),
      decoration: InputDecoration(
        labelText: label,
        alignLabelWithHint: true,
        hintText: hint,
        labelStyle: const TextStyle(fontFamily: 'NotoSansDevanagari'),
        hintStyle: TextStyle(
          fontFamily: 'NotoSansDevanagari',
          color: Colors.grey.shade500,
          height: 1.45,
        ),
      ),
    );
  }
}

class _SingleLineStepField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final String? prefix;
  final TextInputType keyboardType;
  final bool readOnly;
  final VoidCallback? onTap;
  final Widget? suffixIcon;
  final ValueChanged<String>? onChanged;

  const _SingleLineStepField({
    required this.controller,
    required this.label,
    required this.hint,
    this.prefix,
    this.keyboardType = TextInputType.text,
    this.readOnly = false,
    this.onTap,
    this.suffixIcon,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      readOnly: readOnly,
      onTap: onTap,
      onChanged: onChanged,
      style: const TextStyle(fontFamily: 'NotoSansDevanagari', fontSize: 16),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixText: prefix,
        prefixStyle: const TextStyle(
          fontFamily: 'NotoSansDevanagari',
          fontSize: 16,
          color: Color(0xFF212121),
        ),
        labelStyle: const TextStyle(fontFamily: 'NotoSansDevanagari'),
        hintStyle: TextStyle(
          fontFamily: 'NotoSansDevanagari',
          color: Colors.grey.shade500,
        ),
        suffixIcon: suffixIcon == null
            ? null
            : GestureDetector(onTap: onTap, child: suffixIcon),
      ),
    );
  }
}

class _FixedLinePreview extends StatelessWidget {
  final String label;
  final String value;

  const _FixedLinePreview({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'NotoSansDevanagari',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontFamily: 'NotoSansDevanagari',
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF111827),
            ),
          ),
        ],
      ),
    );
  }
}
