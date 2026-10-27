import 'dart:ui';
import '../../../../app/theme/app_colors.dart';

/// Colours shared by the topic modules so every scene speaks the same visual language: the same state means the
/// same colour in a sorting array, a graph, a scheduler and a thread diagram.
class VizPalette {
  VizPalette._();

  /// Thread identities: orange then cyan (the app's two voices), then orchid and gold for further threads.
  static const threads = [AppColors.primary, AppColors.accentCyan, AppColors.orchid, AppColors.xp];

  static const board = Color(0xFF1A1823);
  static const plate = Color(0xFF242130);
  static const idle = Color(0xFF3B3850);
  static const dim = Color(0xFF23202E);
  static const text = AppColors.textPrimary;
  static const muted = AppColors.textSecondary;

  /// The scene-document state vocabulary (`idle`, `cur`, `compare`, `swap`, `done`, `found`, `dim`, `bad`).
  static Color state(String? s) {
    switch (s) {
      case 'cur':
        return AppColors.primary;
      case 'compare':
        return AppColors.accentCyan;
      case 'swap':
        return AppColors.orchid;
      case 'done':
        return AppColors.success;
      case 'found':
        return AppColors.xp;
      case 'bad':
        return AppColors.error;
      case 'dim':
        return dim;
      default:
        return idle;
    }
  }

  /// How strongly a state glows. Settled and idle things stay calm so the active ones read at a glance.
  static double glow(String? s) {
    switch (s) {
      case 'cur':
      case 'compare':
      case 'swap':
      case 'found':
      case 'bad':
        return 0.8;
      case 'done':
        return 0.22;
      default:
        return 0;
    }
  }

  static Color thread(int i) => threads[i % threads.length];
}
