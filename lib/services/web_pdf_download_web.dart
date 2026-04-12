// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

/// Triggers a silent browser download to the user's Downloads folder.
/// No "Save As" dialog — equivalent to a normal browser file download.
void downloadWebPdf(List<int> bytes, String fileName) {
  final blob = html.Blob([bytes], 'application/pdf');
  final url = html.Url.createObjectUrlFromBlob(blob);
  html.AnchorElement(href: url)
    ..setAttribute('download', fileName)
    ..click();
  html.Url.revokeObjectUrl(url);
}
