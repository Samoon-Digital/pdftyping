/// Stub for web — savePdfToDocuments is never called on web
/// because editors use Printing.sharePdf() directly.
Future<void> savePdfToDocuments({
  required List<int> bytes,
  required String fileName,
}) async {
  throw UnsupportedError('File save not supported on web');
}
