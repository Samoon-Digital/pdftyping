import 'package:flutter/foundation.dart';
import 'package:in_app_review/in_app_review.dart';

class InAppReviewService {
  InAppReviewService._();

  static final InAppReviewService instance = InAppReviewService._();

  final InAppReview _review = InAppReview.instance;

  Future<void> requestReviewIfAvailable() async {
    try {
      final available = await _review.isAvailable();
      if (available) {
        await _review.requestReview();
      }
    } catch (error, stackTrace) {
      debugPrint('In-app review skipped: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }
}
