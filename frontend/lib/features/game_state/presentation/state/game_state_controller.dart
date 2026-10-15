import 'package:flutter/foundation.dart';

/// GameStateController — presentation-layer state holder for this feature.
/// Auto-scaffolded to match the project's target file structure.
class GameStateController extends ChangeNotifier {
  bool isLoading = false;
  String? errorMessage;

  Future<void> load() async {
    isLoading = true;
    notifyListeners();
    debugPrint('⚠️ [GameStateController.load] NO API YET — this feature has no repository call; screen is showing static/placeholder UI only.');
    // TODO: fetch data via the feature's repository.
    isLoading = false;
    notifyListeners();
  }
}
