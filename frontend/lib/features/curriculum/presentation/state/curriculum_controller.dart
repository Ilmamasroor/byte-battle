import 'package:flutter/foundation.dart';

/// CurriculumController — presentation-layer state holder for this feature.
/// Auto-scaffolded to match the project's target file structure.
class CurriculumController extends ChangeNotifier {
  bool isLoading = false;
  String? errorMessage;

  Future<void> load() async {
    isLoading = true;
    notifyListeners();
    debugPrint('⚠️ [CurriculumController.load] NO API YET — this feature has no repository call; screen is showing static/placeholder UI only.');
    // TODO: fetch data via the feature's repository.
    isLoading = false;
    notifyListeners();
  }
}
