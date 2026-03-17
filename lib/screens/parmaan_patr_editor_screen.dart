import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../services/pdf_saver.dart';
import '../widgets/pdf_generation_widgets.dart';
import '../widgets/suggestible_input_field.dart';

/// Two-step editor for "प्रधान द्वारा प्रमाणित प्रमाण पत्र".
/// Step 0 → input form (with optional photo picker + crop)
/// Step 1 → preview → generate PDF
class ParmaanPatrEditorScreen extends StatefulWidget {
  final VoidCallback? onPdfSaved;
  const ParmaanPatrEditorScreen({super.key, this.onPdfSaved});

  @override
  State<ParmaanPatrEditorScreen> createState() =>
      _ParmaanPatrEditorScreenState();
}

class _ParmaanPatrEditorScreenState extends State<ParmaanPatrEditorScreen> {
  // ── Photo ──
  Uint8List? _photoBytes;
  final _picker = ImagePicker();

  // ── Form controllers ──
  final _nameCtrl = TextEditingController();
  final _relationNameCtrl = TextEditingController();
  final _gramCtrl = TextEditingController();
  final _majraCtrl = TextEditingController();
  final _postCtrl = TextEditingController();
  final _thanaCtrl = TextEditingController();
  final _jilaCtrl = TextEditingController();
  final _jaatiCtrl = TextEditingController();
  final _upjaatiCtrl = TextEditingController();
  final _maasikAayCtrl = TextEditingController();
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

  // ── Photo box size: 1.2" × 1.5" at the document render scale ──
  // Off-screen render is 560dp wide → inner content ~512dp → 512/8.5 ≈ 60dp/"
  static const _photoBoxW = 72.0; // ≈ 1.2"
  static const _photoBoxH = 90.0; // ≈ 1.5"

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _dateCtrl.text =
        '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}';
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _relationNameCtrl.dispose();
    _gramCtrl.dispose();
    _majraCtrl.dispose();
    _postCtrl.dispose();
    _thanaCtrl.dispose();
    _jilaCtrl.dispose();
    _jaatiCtrl.dispose();
    _upjaatiCtrl.dispose();
    _maasikAayCtrl.dispose();
    _varsikAayCtrl.dispose();
    _dateCtrl.dispose();
    super.dispose();
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

  // ── Photo options bottom sheet ──
  Future<void> _showPhotoOptions() async {
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 14),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Text(
                'फोटो विकल्प',
                style: TextStyle(
                  fontFamily: 'NotoSansDevanagari',
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              const Text(
                'केवल सिर का हिस्सा – 1.2" × 1.5" (300 DPI)',
                style: TextStyle(
                  fontFamily: 'NotoSansDevanagari',
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 8),
              // Camera — only on non-web platforms
              if (!kIsWeb)
                ListTile(
                  leading: const Icon(
                    Icons.camera_alt_rounded,
                    color: Color(0xFF1565C0),
                  ),
                  title: const Text(
                    'कैमरे से लें',
                    style: TextStyle(fontFamily: 'NotoSansDevanagari'),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    _pickPhoto(ImageSource.camera);
                  },
                ),
              // Gallery
              ListTile(
                leading: const Icon(
                  Icons.photo_library_rounded,
                  color: Color(0xFF00838F),
                ),
                title: const Text(
                  'गैलरी से चुनें',
                  style: TextStyle(fontFamily: 'NotoSansDevanagari'),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickPhoto(ImageSource.gallery);
                },
              ),
              // Remove photo (shown only if already set)
              if (_photoBytes != null)
                ListTile(
                  leading: const Icon(
                    Icons.delete_outline_rounded,
                    color: Colors.red,
                  ),
                  title: const Text(
                    'फोटो हटाएं',
                    style: TextStyle(fontFamily: 'NotoSansDevanagari'),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    setState(() => _photoBytes = null);
                  },
                ),
              // Skip / no photo
              ListTile(
                leading: const Icon(
                  Icons.not_interested_rounded,
                  color: Colors.grey,
                ),
                title: const Text(
                  'बिना फोटो के बनाएं',
                  style: TextStyle(fontFamily: 'NotoSansDevanagari'),
                ),
                onTap: () => Navigator.pop(ctx),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Pick and crop photo ──
  Future<void> _pickPhoto(ImageSource source) async {
    try {
      final XFile? picked = await _picker.pickImage(
        source: source,
        maxWidth: 1080,
        maxHeight: 1350,
        imageQuality: 95,
      );
      if (picked == null || !mounted) return;

      // Crop to 4:5 aspect ratio (= 1.2" : 1.5")
      final cropped = await ImageCropper().cropImage(
        sourcePath: picked.path,
        aspectRatio: const CropAspectRatio(ratioX: 4, ratioY: 5),
        compressFormat: ImageCompressFormat.jpg,
        compressQuality: 95,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'फोटो क्रॉप करें',
            toolbarColor: const Color(0xFF1565C0),
            toolbarWidgetColor: Colors.white,
            lockAspectRatio: true,
            hideBottomControls: false,
            showCropGrid: true,
          ),
          IOSUiSettings(
            title: 'फोटो क्रॉप करें',
            aspectRatioLockEnabled: true,
            resetAspectRatioEnabled: false,
          ),
          WebUiSettings(context: context),
        ],
      );

      if (cropped == null || !mounted) return;
      final bytes = await cropped.readAsBytes();
      setState(() => _photoBytes = bytes);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'फोटो लोड करने में त्रुटि हुई।',
              style: TextStyle(fontFamily: 'NotoSansDevanagari'),
            ),
          ),
        );
      }
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
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 28),
              child: _buildDocumentWidget(
                fontSize: 10.2,
                photoBytes: _photoBytes,
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
      await Printing.sharePdf(bytes: pdfBytes, filename: fileName);
      if (!mounted) return;
      Navigator.of(context).pop();
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
        body: _step == 0 ? _buildInputStep() : _buildReviewStep(),
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
                    'जिसके लिए प्रमाण पत्र बनाना है उनकी details भरें',
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

          // ── Photo picker ──
          _buildPhotoCard(),
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
            hint: 'जैसे : नगला',
            onChanged: (_) => setState(() {}),
          ),
          SuggestibleInputField(
            controller: _majraCtrl,
            fieldKey: 'parmaan_majra',
            label: 'मजरा (वैकल्पिक)',
            hint: 'जैसे : बड़ा मजरा',
            onChanged: (_) => setState(() {}),
          ),
          SuggestibleInputField(
            controller: _postCtrl,
            fieldKey: 'parmaan_post',
            label: 'पोस्ट',
            hint: 'जैसे : लखीमपुर',
            onChanged: (_) => setState(() {}),
          ),
          SuggestibleInputField(
            controller: _thanaCtrl,
            fieldKey: 'parmaan_thana',
            label: 'थाना',
            hint: 'जैसे : कोतवाली',
            onChanged: (_) => setState(() {}),
          ),
          SuggestibleInputField(
            controller: _jilaCtrl,
            fieldKey: 'parmaan_jila',
            label: 'जिला',
            hint: 'जैसे : लखीमपुर खीरी',
            onChanged: (_) => setState(() {}),
          ),

          // ── Caste ──
          _sectionLabel('जाति की जानकारी'),
          SuggestibleInputField(
            controller: _jaatiCtrl,
            fieldKey: 'parmaan_jaati',
            label: 'जाति',
            hint: 'जैसे : ओबीसी',
            onChanged: (_) => setState(() {}),
          ),
          SuggestibleInputField(
            controller: _upjaatiCtrl,
            fieldKey: 'parmaan_upjaati',
            label: 'उपजाति',
            hint: 'जैसे : कुर्मी',
            onChanged: (_) => setState(() {}),
          ),

          // ── Income (only when आय is selected) ──
          if (_certAay) ...[
            _sectionLabel('आय की जानकारी'),
            SuggestibleInputField(
              controller: _maasikAayCtrl,
              fieldKey: 'parmaan_maasik_aay',
              label: 'मासिक आय (रु०)',
              hint: 'जैसे : 5000',
              keyboardType: TextInputType.number,
              onChanged: (_) => setState(() {}),
            ),
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
                setState(() => _certJaati = v);
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

  Widget _buildPhotoCard() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE0E0E0)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Photo preview / placeholder
          GestureDetector(
            onTap: _showPhotoOptions,
            child: Container(
              width: _photoBoxW,
              height: _photoBoxH,
              decoration: BoxDecoration(
                border: Border.all(
                  color: _photoBytes != null
                      ? const Color(0xFF1565C0)
                      : const Color(0xFFCCCCCC),
                  width: 1.5,
                ),
                borderRadius: BorderRadius.circular(6),
                color: const Color(0xFFF5F5F5),
              ),
              clipBehavior: Clip.antiAlias,
              child: _photoBytes != null
                  ? Image.memory(_photoBytes!, fit: BoxFit.cover)
                  : const _PhotoPlaceholder(),
            ),
          ),
          const SizedBox(width: 14),

          // Info + button
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'पासपोर्ट साइज फोटो',
                  style: TextStyle(
                    fontFamily: 'NotoSansDevanagari',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF212121),
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  '1.2" × 1.5"  •  300 DPI\n'
                  'केवल सिर का हिस्सा चुनें\n'
                  'फोटो लेने के बाद क्रॉप करें',
                  style: TextStyle(
                    fontFamily: 'NotoSansDevanagari',
                    fontSize: 11,
                    color: Color(0xFF888888),
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    OutlinedButton.icon(
                      onPressed: _showPhotoOptions,
                      icon: Icon(
                        _photoBytes != null
                            ? Icons.edit_rounded
                            : Icons.add_photo_alternate_rounded,
                        size: 15,
                      ),
                      label: Text(
                        _photoBytes != null ? 'बदलें' : 'फोटो चुनें',
                        style: const TextStyle(
                          fontFamily: 'NotoSansDevanagari',
                          fontSize: 12,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                    if (_photoBytes != null) ...[
                      const SizedBox(width: 8),
                      TextButton(
                        onPressed: () => setState(() => _photoBytes = null),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 6,
                          ),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          foregroundColor: Colors.red,
                        ),
                        child: const Text(
                          'हटाएं',
                          style: TextStyle(
                            fontFamily: 'NotoSansDevanagari',
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
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
                child: _buildDocumentWidget(photoBytes: _photoBytes),
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
  /// [photoBytes] — the cropped photo bytes, or null for blank box.
  Widget _buildDocumentWidget({double? fontSize, Uint8List? photoBytes}) {
    final fs =
        fontSize ?? Theme.of(context).textTheme.bodyMedium?.fontSize ?? 14.0;

    final baseStyle = TextStyle(
      fontFamily: 'NotoSansDevanagari',
      fontSize: fs,
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
    final majra = _majraCtrl.text.trim();
    final post = _postCtrl.text.trim();
    final thana = _thanaCtrl.text.trim();
    final jila = _jilaCtrl.text.trim();
    final jaati = _jaatiCtrl.text.trim();
    final upjaati = _upjaatiCtrl.text.trim();
    final maasik = _maasikAayCtrl.text.trim();
    final varsik = _varsikAayCtrl.text.trim();
    final date = _dateCtrl.text.trim();

    // Helper: colored placeholder when empty
    TextSpan val(String v, String ph) =>
        TextSpan(text: v.isEmpty ? ph : v, style: v.isEmpty ? phStyle : null);

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFF212121), width: 0.9),
      ),
      padding: EdgeInsets.fromLTRB(fs * 1.1, fs * 1.2, fs * 1.1, fs * 1.2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Title ──
          Center(
            child: Text(
              'प्रधान द्वारा प्रमाणित प्रमाण पत्र',
              style: TextStyle(
                fontFamily: 'NotoSansDevanagari',
                fontSize: fs * 1.25,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF212121),
              ),
              textAlign: TextAlign.center,
            ),
          ),
          SizedBox(height: fs * 0.3),
          const Divider(color: Color(0xFF212121), thickness: 0.8),
          SizedBox(height: fs * 0.4),

          // ── Cert-type checkboxes (left) + photo box (right) ──
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _docCertChip('आय', _certAay, baseStyle, phStyle),
                        SizedBox(width: fs * 1.0),
                        _docCertChip('जाति', _certJaati, baseStyle, phStyle),
                        SizedBox(width: fs * 1.0),
                        _docCertChip('निवास', _certNiwas, baseStyle, phStyle),
                      ],
                    ),
                  ],
                ),
              ),
              // Photo box — fixed 1.2" × 1.5" (scaled to render width)
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
                child: photoBytes != null
                    ? Image.memory(photoBytes, fit: BoxFit.cover)
                    : Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.person_rounded,
                              size: fs * 2.0,
                              color: Colors.grey[400],
                            ),
                            Text(
                              'फोटो',
                              style: TextStyle(
                                fontFamily: 'NotoSansDevanagari',
                                fontSize: fs * 0.75,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      ),
              ),
            ],
          ),

          SizedBox(height: fs * 0.8),

          // ── Main body ──
          RichText(
            text: TextSpan(
              style: baseStyle,
              children: [
                const TextSpan(
                  text: 'प्रमाणित किया जाता है कि श्री/श्रीमती/कु0 ',
                ),
                val(name, 'व्यक्ति का नाम'),
                TextSpan(text: ' $_relationType '),
                val(relName, 'पिता/पति का नाम'),
                const TextSpan(text: '\nग्राम '),
                val(gram, 'ग्राम'),
                if (majra.isNotEmpty) ...[
                  const TextSpan(text: ' मजरा '),
                  TextSpan(text: majra),
                ],
                const TextSpan(text: ' पोस्ट '),
                val(post, 'पोस्ट'),
                const TextSpan(text: ' थाना '),
                val(thana, 'थाना'),
                const TextSpan(text: '\nजिला '),
                val(jila, 'जिला'),
                const TextSpan(
                  text:
                      ' के मूल निवासी/निवासिनी हैं। मैं इनको भली भांति जानता/जानती पहचानता/पहचानती हूं '
                      'तथा इनकी जाति ',
                ),
                val(jaati, 'जाति'),
                const TextSpan(text: ' उपजाति '),
                val(upjaati, 'उपजाति'),
                const TextSpan(
                  text:
                      ' है। तथा इनके पिता/पति की समस्त श्रोतों से होने वाली कुल\n'
                      'मासिक आय मु0 ',
                ),
                val(maasik, '…………………'),
                const TextSpan(text: ' तथा वार्षिक आय मु0 '),
                val(varsik, '…………………'),
                const TextSpan(text: ' है।'),
              ],
            ),
          ),

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
              Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text('प्रधान', style: baseStyle),
                  Text('हस्ताक्षर व मुहर', style: baseStyle),
                ],
              ),
            ],
          ),
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
          child: checked
              ? Icon(Icons.check, size: size * 0.8, color: Colors.black)
              : null,
        ),
        const SizedBox(width: 3),
        Text(label, style: base),
      ],
    );
  }
}

// ── Photo box placeholder ──
class _PhotoPlaceholder extends StatelessWidget {
  const _PhotoPlaceholder();

  @override
  Widget build(BuildContext context) {
    return const Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.person_rounded, size: 30, color: Color(0xFFBBBBBB)),
        SizedBox(height: 4),
        Text(
          'फोटो',
          style: TextStyle(
            fontFamily: 'NotoSansDevanagari',
            fontSize: 11,
            color: Color(0xFFAAAAAA),
          ),
        ),
      ],
    );
  }
}
