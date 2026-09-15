import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_dimensions.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/storage/local_storage_service.dart';
import '../../../../core/widgets/app_bottom_nav.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../auth/presentation/state/auth_controller.dart';

/// The single "Profile" screen — this is the real destination for the
/// Profile tab in [AppBottomNav] everywhere in the app. It shows the
/// logged-in user (refreshed via `GET /api/users/{id}`) and lets them
/// edit their username/email directly on this page (`PUT /api/users/me`).
///
/// Previously this feature had two overlapping screens — a "view" screen
/// (buttons only) and a separate "edit" screen with the actual form —
/// and the bottom nav's Profile tab didn't even point at either of them,
/// it pointed at [ScoreScreen] instead. All of that has been collapsed
/// into this one screen so there's a single source of truth for what
/// "Profile" looks like and where it lives.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  static const int _navIndex = 4;

  final _formKey = GlobalKey<FormState>();
  final _nameFocusNode = FocusNode();
  late final TextEditingController _usernameController;
  late final TextEditingController _emailController;
  final _passwordController = TextEditingController(text: '••••••••');

  final _localStorage = const LocalStorageService();

  bool _isRefreshing = false;
  bool _isSaving = false;

  // Local-only profile photo — there is no upload API yet, so this is a
  // hardcoded-to-device preview picked from the gallery, cached in
  // SharedPreferences and auto-expired after 24 hours (see
  // LocalStorageService.profilePhotoTtl).
  File? _profilePhoto;
  bool _isPickingPhoto = false;

  @override
  void initState() {
    super.initState();
    final user = AuthController.instance.currentUser;
    _usernameController = TextEditingController(text: user?.username ?? '');
    _emailController = TextEditingController(text: user?.email ?? '');
    _loadProfilePhoto();
    _refresh();
  }

  Future<void> _loadProfilePhoto() async {
    final path = await _localStorage.getProfilePhotoPath();
    if (!mounted) return;
    if (path != null && File(path).existsSync()) {
      setState(() => _profilePhoto = File(path));
    } else {
      setState(() => _profilePhoto = null);
    }
  }

  Future<void> _pickProfilePhoto() async {
    if (_isPickingPhoto) return;
    setState(() => _isPickingPhoto = true);
    try {
      final picked = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        imageQuality: 85,
      );
      if (picked == null) return; // user cancelled the picker
      await _localStorage.saveProfilePhotoPath(picked.path);
      if (!mounted) return;
      setState(() => _profilePhoto = File(picked.path));
      AppSnackBar.success(context, 'Profile photo updated');
    } catch (e) {
      if (!mounted) return;
      AppSnackBar.error(
        context,
        'Could not open gallery. Check photo permission and try again.',
      );
    } finally {
      if (mounted) setState(() => _isPickingPhoto = false);
    }
  }

  @override
  void dispose() {
    _nameFocusNode.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    setState(() => _isRefreshing = true);
    await AuthController.instance.refreshProfile();
    if (!mounted) return;
    final user = AuthController.instance.currentUser;
    if (user != null) {
      _usernameController.text = user.username;
      _emailController.text = user.email;
    }
    setState(() => _isRefreshing = false);
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    final user = AuthController.instance.currentUser;
    final newUsername = _usernameController.text.trim();
    final newEmail = _emailController.text.trim();

    // Only send the field(s) that actually changed.
    final username = (user == null || newUsername != user.username) ? newUsername : null;
    final email = (user == null || newEmail != user.email) ? newEmail : null;

    if (username == null && email == null) return;

    setState(() => _isSaving = true);
    final success = await AuthController.instance.updateProfile(
      username: username,
      email: email,
    );
    if (!mounted) return;
    setState(() => _isSaving = false);

    if (success) {
      AppSnackBar.success(context, 'Profile updated.');
    } else {
      AppSnackBar.error(
        context,
        AuthController.instance.errorMessage ?? 'Could not update profile.',
      );
    }
  }

  Future<void> _confirmLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Log out?', style: AppTextStyles.bodyBold),
        content: const Text(
          'You will need to sign in again to continue your progress.',
          style: AppTextStyles.body,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Log out', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    await AuthController.instance.logout();
    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil(RouteNames.login, (route) => false);
  }

  Future<void> _confirmDeleteAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Delete Account', style: AppTextStyles.heading2),
        content: const Text(
          'This permanently deletes your account and all its data. '
          'This cannot be undone.',
          style: AppTextStyles.body,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('DELETE', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final success = await AuthController.instance.deleteAccount();
    if (!mounted) return;

    if (success) {
      Navigator.of(context).pushNamedAndRemoveUntil(RouteNames.login, (route) => false);
    } else {
      AppSnackBar.error(
        context,
        AuthController.instance.errorMessage ?? 'Could not delete account.',
      );
    }
  }

  void _onNavTap(int index) {
    if (index == _navIndex) return;
    switch (index) {
      case 0:
        Navigator.of(context).pushReplacementNamed(RouteNames.dashboard);
        break;
      case 1:
        Navigator.of(context).pushReplacementNamed(RouteNames.conceptList);
        break;
      case 2:
        Navigator.of(context).pushReplacementNamed(RouteNames.bossBattleIntro);
        break;
      case 3:
        Navigator.of(context).pushReplacementNamed(RouteNames.coding);
        break;
      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthController.instance.currentUser;
    final initials =
        (user?.username.isNotEmpty ?? false) ? user!.username[0].toUpperCase() : '?';

    return Scaffold(
      backgroundColor: Colors.transparent,
      bottomNavigationBar: AppBottomNav(currentIndex: _navIndex, onTap: _onNavTap),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refresh,
          color: AppColors.primary,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(AppDimensions.screenPadding),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Header: back button · brand mark · Edit Profile ──
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _RoundIconButton(
                        icon: Icons.arrow_back_rounded,
                        onTap: () => Navigator.of(context).maybePop(),
                      ),
                      Expanded(
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: 26,
                                  height: 26,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    gradient: AppColors.primaryGradient,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Text('B',
                                      style: TextStyle(
                                        color: AppColors.white,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 15,
                                      )),
                                ),
                                const SizedBox(width: 8),
                                const Text('BYTE BATTLE',
                                    style: TextStyle(
                                      color: AppColors.textPrimary,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 14,
                                      letterSpacing: 0.5,
                                    )),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text('Think Deeper. Code Better.',
                                style: AppTextStyles.caption),
                          ],
                        ),
                      ),
                      _EditProfilePill(
                        onTap: () => FocusScope.of(context).requestFocus(_nameFocusNode),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppDimensions.spacingXl),

                  // ── Title ──
                  const Text('Profile', style: AppTextStyles.heading1),
                  const SizedBox(height: 6),
                  Container(width: 36, height: 3, color: AppColors.accentCyan),
                  const SizedBox(height: AppDimensions.spacingSm),
                  const Text(
                    'Your journey. Your progress. Your next level.',
                    style: AppTextStyles.body,
                  ),
                  const SizedBox(height: AppDimensions.spacingXl),

                  // ── Avatar + quote ──
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          InkWell(
                            onTap: _isPickingPhoto ? null : _pickProfilePhoto,
                            borderRadius: BorderRadius.circular(48),
                            child: Container(
                              width: 96,
                              height: 96,
                              padding: const EdgeInsets.all(3),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: AppColors.btnPrimaryGradient,
                              ),
                              child: Container(
                                alignment: Alignment.center,
                                clipBehavior: Clip.antiAlias,
                                decoration: const BoxDecoration(
                                  color: AppColors.backgroundSecondary,
                                  shape: BoxShape.circle,
                                ),
                                child: _profilePhoto != null
                                    ? Image.file(
                                        _profilePhoto!,
                                        width: 90,
                                        height: 90,
                                        fit: BoxFit.cover,
                                      )
                                    : (_isPickingPhoto
                                        ? const SizedBox(
                                            width: 24,
                                            height: 24,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: AppColors.primary,
                                            ),
                                          )
                                        : Text(initials, style: AppTextStyles.heading1)),
                              ),
                            ),
                          ),
                          Positioned(
                            right: 0,
                            bottom: 0,
                            child: InkWell(
                              onTap: _isPickingPhoto ? null : _pickProfilePhoto,
                              child: Container(
                                width: 30,
                                height: 30,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: AppColors.surface,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: AppColors.accentCyan, width: 1.5),
                                ),
                                child: const Icon(Icons.camera_alt_rounded,
                                    size: 14, color: AppColors.accentCyan),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: AppDimensions.spacingLg),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(AppDimensions.spacingMd),
                          decoration: BoxDecoration(
                            color: AppColors.surface.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                            border: Border.all(color: AppColors.borderLight.withOpacity(0.4)),
                          ),
                          child: const Text(
                            '"Same learner.\nHigher version."',
                            style: TextStyle(
                              fontStyle: FontStyle.italic,
                              color: AppColors.primaryLight,
                              fontSize: 14,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppDimensions.spacingMd),

                  if (_isRefreshing && user == null)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: CircularProgressIndicator(color: AppColors.primary),
                      ),
                    )
                  else if (user == null)
                    Center(
                      child: Text(
                        AuthController.instance.errorMessage ?? 'Not logged in.',
                        style: AppTextStyles.body,
                        textAlign: TextAlign.center,
                      ),
                    )
                  else ...[
                    Center(
                      child: Text(user.username, style: AppTextStyles.heading2),
                    ),
                    const SizedBox(height: 2),
                    const Center(
                      child: Text('Learning today. Building tomorrow.',
                          style: AppTextStyles.body),
                    ),
                  ],
                  const SizedBox(height: AppDimensions.spacingXl),

                  // ── Editable fields ──
                  AppTextField(
                    controller: _usernameController,
                    label: 'Name',
                    hint: 'Enter your name',
                    prefixIcon: Icons.person_outline_rounded,
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Enter a name' : null,
                  ),
                  const SizedBox(height: AppDimensions.spacingMd),
                  AppTextField(
                    controller: _emailController,
                    label: 'Email',
                    hint: 'Enter your email address',
                    prefixIcon: Icons.mail_outline_rounded,
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) =>
                        (v == null || !v.contains('@')) ? 'Enter a valid email' : null,
                  ),
                  const SizedBox(height: AppDimensions.spacingMd),

                  // Password: changing it needs the current password too
                  // (`PUT /api/users/me/password`), so this field opens the
                  // dedicated Change Password screen instead of accepting
                  // free text directly here.
                  Text('Password', style: AppTextStyles.bodyBold),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: () => Navigator.of(context).pushNamed(RouteNames.changePassword),
                    borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                    child: IgnorePointer(
                      child: AppTextField(
                        controller: _passwordController,
                        hint: '••••••••',
                        prefixIcon: Icons.lock_outline_rounded,
                        isPassword: true,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppDimensions.spacingMd),

                  // Role: server-managed, shown read-only.
                  Text('Role', style: AppTextStyles.bodyBold),
                  const SizedBox(height: 8),
                  InkWell(
                    borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                    onTap: () {
                      AppSnackBar.show(context, 'Under Admin Control');
                    },
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        prefixIcon:
                            Icon(Icons.school_outlined, color: AppColors.textHint, size: 20),
                        suffixIcon:
                            Icon(Icons.expand_more_rounded, color: AppColors.textHint),
                      ),
                      child: Text(user?.role ?? 'Learner', style: AppTextStyles.bodyBold),
                    ),
                  ),
                  const SizedBox(height: AppDimensions.spacingXl),

                  AppButton(
                    label: 'Save Changes',
                    icon: Icons.arrow_forward_rounded,
                    isLoading: _isSaving,
                    onPressed: _saveChanges,
                  ),
                  const SizedBox(height: AppDimensions.spacingLg),

                  // Account actions that don't fit the main form: kept as
                  // lightweight text links instead of a second screen.
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pushNamed(RouteNames.learnerProfile),
                        child: const Text('Learner Settings', style: AppTextStyles.link),
                      ),
                      const Text('·', style: AppTextStyles.caption),
                      TextButton(
                        onPressed: _confirmLogout,
                        child: const Text('Log Out', style: AppTextStyles.link),
                      ),
                      const Text('·', style: AppTextStyles.caption),
                      TextButton(
                        onPressed: _confirmDeleteAccount,
                        child: const Text('Delete Account',
                            style: TextStyle(
                              color: AppColors.error,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            )),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _RoundIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
      child: Container(
        width: 40,
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          border: Border.all(color: AppColors.borderLight.withOpacity(0.4)),
        ),
        child: Icon(icon, color: AppColors.textPrimary, size: 18),
      ),
    );
  }
}

class _EditProfilePill extends StatelessWidget {
  final VoidCallback onTap;

  const _EditProfilePill({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppDimensions.radiusPill),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppDimensions.radiusPill),
          border: Border.all(color: AppColors.accentCyan.withOpacity(0.6)),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.edit_rounded, size: 14, color: AppColors.accentCyan),
            SizedBox(width: 6),
            Text('Edit Profile',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                )),
          ],
        ),
      ),
    );
  }
}
