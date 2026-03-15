import 'dart:io';
import 'package:path_provider/path_provider.dart';

Future<void> savePdfToDocuments({
  required List<int> bytes,
  required String fileName,
}) async {
  final docsDir = await getApplicationDocumentsDirectory();
  final file = File('${docsDir.path}/$fileName');
  await file.writeAsBytes(bytes);
}
