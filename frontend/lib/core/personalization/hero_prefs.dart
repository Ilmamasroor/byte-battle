import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../app/theme/app_colors.dart';

/// Per-learner personalisation, stored on the device: the avatar's colours and glyph, and what the learner calls
/// their companion. It is purely cosmetic (no backend field exists for it), so it lives in SharedPreferences.
class HeroPrefs extends ChangeNotifier {
  HeroPrefs._();
  static final HeroPrefs instance = HeroPrefs._();

  static const palettes = <(String, List<Color>)>[
    ('Ember', [Color(0xFFFFB05C), Color(0xFFF0501F)]),
    ('Lagoon', [Color(0xFF8BE3F7), Color(0xFF3FA9E8)]),
    ('Orchid', [Color(0xFFD2C4FF), Color(0xFF8A6BF0)]),
    ('Meadow', [Color(0xFF9CF0C8), Color(0xFF24B07A)]),
    ('Sunbeam', [Color(0xFFFFE29A), Color(0xFFF2A81D)]),
    ('Blossom', [Color(0xFFFFB3C7), Color(0xFFE5557E)]),
  ];

  static const glyphs = <(String, IconData)>[
    ('Initials', Icons.abc_rounded),
    ('Rocket', Icons.rocket_launch_rounded),
    ('Bolt', Icons.bolt_rounded),
    ('Bug', Icons.bug_report_rounded),
    ('Brain', Icons.psychology_rounded),
    ('Shield', Icons.shield_rounded),
    ('Terminal', Icons.terminal_rounded),
    ('Star', Icons.auto_awesome_rounded),
  ];

  int paletteIndex = 0;
  int glyphIndex = 0;
  String companionName = 'Bit';

  /// The learner's chosen explanation lens (a [Lens.id]), or null to follow their Byte DNA interests.
  String? lens;
  bool _loaded = false;

  List<Color> get colors => palettes[paletteIndex].$2;
  IconData? get glyph => glyphIndex == 0 ? null : glyphs[glyphIndex].$2;

  Future<void> load() async {
    if (_loaded) return;
    try {
      final p = await SharedPreferences.getInstance();
      paletteIndex = (p.getInt('hero_palette') ?? 0).clamp(0, palettes.length - 1);
      glyphIndex = (p.getInt('hero_glyph') ?? 0).clamp(0, glyphs.length - 1);
      companionName = p.getString('hero_companion') ?? 'Bit';
      lens = p.getString('hero_lens');
    } catch (e) {
      debugPrint('HeroPrefs: could not read preferences: $e');
    }
    _loaded = true;
    notifyListeners();
  }

  Future<void> setLens(String? id) async {
    lens = id;
    notifyListeners();
    try {
      final p = await SharedPreferences.getInstance();
      id == null ? await p.remove('hero_lens') : await p.setString('hero_lens', id);
    } catch (e) {
      debugPrint('HeroPrefs: could not save lens: $e');
    }
  }

  Future<void> update({int? palette, int? glyph, String? companion}) async {
    if (palette != null) paletteIndex = palette;
    if (glyph != null) glyphIndex = glyph;
    if (companion != null) companionName = companion.trim().isEmpty ? 'Bit' : companion.trim();
    notifyListeners();
    try {
      final p = await SharedPreferences.getInstance();
      await p.setInt('hero_palette', paletteIndex);
      await p.setInt('hero_glyph', glyphIndex);
      await p.setString('hero_companion', companionName);
    } catch (e) {
      debugPrint('HeroPrefs: could not save preferences: $e');
    }
  }

  /// Titles that grow with the learner's level: the fun layer on top of a plain number.
  static String titleForLevel(int level) {
    const titles = [
      'Byte Rookie',
      'Bit Wrangler',
      'Loop Runner',
      'Thread Tamer',
      'Stack Surfer',
      'Bug Hunter',
      'Race Slayer',
      'Code Knight',
      'Byte Master',
    ];
    return titles[(level - 1).clamp(0, titles.length - 1)];
  }
}

/// Round avatar using the learner's chosen palette and glyph (initials by default).
class HeroAvatar extends StatelessWidget {
  final String initials;
  final double size;
  const HeroAvatar({super.key, required this.initials, this.size = 44});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: HeroPrefs.instance,
      builder: (context, _) {
        final prefs = HeroPrefs.instance;
        return Container(
          width: size,
          height: size,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: prefs.colors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(color: Colors.white.withOpacity(0.25), width: 1.5),
          ),
          child: prefs.glyph != null
              ? Icon(prefs.glyph, color: AppColors.onAccent, size: size * 0.52)
              : Text(
                  initials,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: size * 0.38,
                    color: AppColors.onAccent,
                  ),
                ),
        );
      },
    );
  }
}
