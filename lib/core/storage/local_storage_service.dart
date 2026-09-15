import 'package:shared_preferences/shared_preferences.dart';

/// Plain (unencrypted) on-device key/value storage — for things that are
/// NOT auth/credentials (those live in [SecureStorageService] instead).
///
/// Right now this only holds the locally-picked profile photo. There is
/// no `POST /api/users/me/photo` (or similar) endpoint yet, so the photo
/// is never uploaded anywhere — it's purely a local, on-device preview
/// that expires after 24 hours so it doesn't silently go stale forever
/// while we wait on a real upload API.
class LocalStorageService {
  const LocalStorageService();

  static const _profilePhotoPathKey = 'profile_photo_path';
  static const _profilePhotoSavedAtKey = 'profile_photo_saved_at';
  static const Duration profilePhotoTtl = Duration(hours: 24);

  /// Saves the picked image's local file path, stamped with "now" so it
  /// can be expired later.
  Future<void> saveProfilePhotoPath(String path) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_profilePhotoPathKey, path);
    await prefs.setInt(
      _profilePhotoSavedAtKey,
      DateTime.now().millisecondsSinceEpoch,
    );
  }

  /// Returns the stored photo path, or `null` if none is saved or the
  /// saved one is older than [profilePhotoTtl] (in which case it's
  /// cleared automatically — the caller doesn't need to do that itself).
  Future<String?> getProfilePhotoPath() async {
    final prefs = await SharedPreferences.getInstance();
    final path = prefs.getString(_profilePhotoPathKey);
    final savedAtMs = prefs.getInt(_profilePhotoSavedAtKey);
    if (path == null || savedAtMs == null) return null;

    final savedAt = DateTime.fromMillisecondsSinceEpoch(savedAtMs);
    if (DateTime.now().difference(savedAt) > profilePhotoTtl) {
      await clearProfilePhoto();
      return null;
    }
    return path;
  }

  Future<void> clearProfilePhoto() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_profilePhotoPathKey);
    await prefs.remove(_profilePhotoSavedAtKey);
  }
}
