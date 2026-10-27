import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';

/// A "lens": the world the learner likes, used to explain ideas (analogy, mnemonic) and to dress the page. The id
/// is what the backend accepts (an allow-list there mirrors this list), the rest is look and wording.
class Lens {
  final String id;
  final String label;
  final IconData icon;
  final Color color;
  final String pictureTitle; // the everyday scene
  final String mapTitle; // what maps to what
  final String tipTitle; // the memory tip
  final String loading;
  const Lens(this.id, this.label, this.icon, this.color, this.pictureTitle, this.mapTitle, this.tipTitle, this.loading);

  static const all = <Lens>[
    Lens('movies', 'Movies', Icons.movie_filter_rounded, AppColors.orchid, 'ROLL CAMERA', 'THE CAST LIST', 'THE PLOT TWIST', 'Writing your screenplay...'),
    Lens('cricket', 'Cricket', Icons.sports_cricket_rounded, AppColors.success, 'ON THE PITCH', 'THE LINE-UP', "COACH'S TIP", 'Setting the field...'),
    Lens('gaming', 'Gaming', Icons.sports_esports_rounded, AppColors.accentCyan, 'LEVEL START', 'YOUR LOADOUT', 'CHEAT CODE', 'Loading the next level...'),
    Lens('food', 'Food', Icons.restaurant_rounded, AppColors.primary, 'IN THE KITCHEN', 'THE INGREDIENTS', "CHEF'S SECRET", 'Heating the pan...'),
    Lens('music', 'Music', Icons.music_note_rounded, AppColors.xp, 'ON STAGE', 'THE BAND', 'THE HOOK', 'Tuning the instruments...'),
    Lens('football', 'Football', Icons.sports_soccer_rounded, AppColors.success, 'MATCH DAY', 'THE SQUAD', 'HALF-TIME TIP', 'Lining up the team...'),
    Lens('space', 'Space', Icons.rocket_launch_rounded, AppColors.accentCyan, 'MISSION CONTROL', 'THE CREW', 'FLIGHT NOTE', 'Counting down...'),
    Lens('anime', 'Anime', Icons.auto_awesome_rounded, AppColors.orchid, 'EPISODE ONE', 'CHARACTER SHEET', 'POWER-UP', 'Drawing the next episode...'),
    Lens('travel', 'Travel', Icons.flight_takeoff_rounded, AppColors.primary, 'THE JOURNEY', 'THE ITINERARY', 'TRAVEL HACK', 'Booking your tickets...'),
  ];

  static Lens? byId(String? id) {
    for (final l in all) {
      if (l.id == id) return l;
    }
    return null;
  }
}
