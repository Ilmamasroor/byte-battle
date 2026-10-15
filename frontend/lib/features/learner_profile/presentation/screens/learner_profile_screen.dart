import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_dimensions.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../data/models/learner_profile_model.dart';
import '../state/learner_profile_controller.dart';

/// Learner profile settings screen — backed by `GET`/`POST`/`PUT
/// /api/learner-profile`.
///
/// On load: if the learner already has a saved profile, shows it with an
/// "EDIT" form (`PUT`, partial update). If they don't have one yet (`GET`
/// comes back 404), shows a "create" form instead (`POST`).
class LearnerProfileScreen extends StatefulWidget {
  const LearnerProfileScreen({super.key});

  @override
  State<LearnerProfileScreen> createState() => _LearnerProfileScreenState();
}

class _LearnerProfileScreenState extends State<LearnerProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _languageController;
  late final TextEditingController _goalController;
  ExperienceLevel _selectedLevel = ExperienceLevel.beginner;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _languageController = TextEditingController();
    _goalController = TextEditingController();
    _load();
  }

  @override
  void dispose() {
    _languageController.dispose();
    _goalController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    await LearnerProfileController.instance.load();
    if (!mounted) return;
    final controller = LearnerProfileController.instance;
    setState(() {
      // No saved profile yet -> go straight into the create form.
      _isEditing = controller.profileMissing;
      _populateFieldsFromProfile(controller.profile);
    });
  }

  void _populateFieldsFromProfile(LearnerProfileModel? profile) {
    if (profile == null) return;
    _selectedLevel = profile.experienceLevel;
    _languageController.text = profile.preferredLanguage;
    _goalController.text = profile.dailyGoalMinutes.toString();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final controller = LearnerProfileController.instance;
    final language = _languageController.text.trim();
    final goalMinutes = int.tryParse(_goalController.text.trim()) ?? 0;

    final bool success;
    if (controller.profileMissing || controller.profile == null) {
      // `POST /api/learner-profile` — first save.
      success = await controller.create(
        experienceLevel: _selectedLevel,
        preferredLanguage: language,
        dailyGoalMinutes: goalMinutes,
      );
    } else {
      // `PUT /api/learner-profile` — only send fields that changed.
      final existing = controller.profile!;
      success = await controller.update(
        experienceLevel: _selectedLevel != existing.experienceLevel ? _selectedLevel : null,
        preferredLanguage: language != existing.preferredLanguage ? language : null,
        dailyGoalMinutes: goalMinutes != existing.dailyGoalMinutes ? goalMinutes : null,
      );
    }

    if (!mounted) return;
    if (success) {
      setState(() => _isEditing = false);
      AppSnackBar.success(context, 'Learner profile saved.');
    } else {
      AppSnackBar.error(
        context,
        controller.errorMessage ?? 'Could not save learner profile.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: LearnerProfileController.instance,
      builder: (context, _) {
        final controller = LearnerProfileController.instance;

        return Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
              onPressed: () => Navigator.of(context).maybePop(),
            ),
            title: const Text('Learner Profile', style: AppTextStyles.heading2),
          ),
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(AppDimensions.screenPadding),
              child: _buildBody(controller),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBody(LearnerProfileController controller) {
    if (controller.isLoading && controller.profile == null && !controller.profileMissing) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    // A real error (not "no profile yet") and nothing to show/edit.
    if (controller.errorMessage != null &&
        controller.profile == null &&
        !controller.profileMissing) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              controller.errorMessage!,
              style: AppTextStyles.body,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppDimensions.spacingLg),
            AppButton(label: 'RETRY', outlined: true, onPressed: _load),
          ],
        ),
      );
    }

    if (!_isEditing && controller.profile != null) {
      return _buildSummary(controller.profile!);
    }

    return _buildForm(controller);
  }

  Widget _buildSummary(LearnerProfileModel profile) {
    return ListView(
      children: [
        const SizedBox(height: AppDimensions.spacingLg),
        const Text('Learner Profile', style: AppTextStyles.heading1),
        const SizedBox(height: AppDimensions.spacingSm),
        Text(
          'How Byte Battle tailors lessons and daily goals for you.',
          style: AppTextStyles.body,
        ),
        const SizedBox(height: AppDimensions.spacingXl),
        _summaryRow('Experience level', profile.experienceLevel.label),
        const SizedBox(height: AppDimensions.spacingMd),
        _summaryRow('Preferred language', profile.preferredLanguage),
        const SizedBox(height: AppDimensions.spacingMd),
        _summaryRow('Daily goal', '${profile.dailyGoalMinutes} minutes'),
        const SizedBox(height: AppDimensions.spacingXl),
        AppButton(
          label: 'EDIT',
          icon: Icons.edit_outlined,
          onPressed: () => setState(() {
            _populateFieldsFromProfile(profile);
            _isEditing = true;
          }),
        ),
      ],
    );
  }

  Widget _summaryRow(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.spacingMd),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTextStyles.body),
          Text(value, style: AppTextStyles.bodyBold),
        ],
      ),
    );
  }

  Widget _buildForm(LearnerProfileController controller) {
    final isCreating = controller.profileMissing || controller.profile == null;

    return ListView(
      children: [
        Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppDimensions.spacingLg),
              Text(
                isCreating ? 'Set Up Learner Profile' : 'Edit Learner Profile',
                style: AppTextStyles.heading1,
              ),
              const SizedBox(height: AppDimensions.spacingSm),
              Text(
                'This shapes the difficulty and pace of what you see.',
                style: AppTextStyles.body,
              ),
              const SizedBox(height: AppDimensions.spacingXl),
              Text('Experience Level', style: AppTextStyles.bodyBold),
              const SizedBox(height: AppDimensions.spacingSm),
              DropdownButtonFormField<ExperienceLevel>(
                value: _selectedLevel,
                dropdownColor: AppColors.surface,
                style: AppTextStyles.bodyBold,
                items: ExperienceLevel.values
                    .map((level) => DropdownMenuItem(
                          value: level,
                          child: Text(level.label),
                        ))
                    .toList(),
                onChanged: (level) {
                  if (level != null) setState(() => _selectedLevel = level);
                },
              ),
              const SizedBox(height: AppDimensions.spacingMd),
              AppTextField(
                controller: _languageController,
                label: 'Preferred Language',
                hint: 'e.g. Python',
                prefixIcon: Icons.code_rounded,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Enter a preferred language' : null,
              ),
              const SizedBox(height: AppDimensions.spacingMd),
              AppTextField(
                controller: _goalController,
                label: 'Daily Goal (minutes)',
                hint: 'e.g. 30',
                prefixIcon: Icons.timer_outlined,
                keyboardType: TextInputType.number,
                validator: (v) {
                  final minutes = int.tryParse((v ?? '').trim());
                  if (minutes == null || minutes <= 0) {
                    return 'Enter a daily goal greater than 0';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppDimensions.spacingXl),
              AppButton(
                label: isCreating ? 'SAVE' : 'SAVE CHANGES',
                isLoading: controller.isSaving,
                onPressed: _submit,
              ),
              if (!isCreating) ...[
                const SizedBox(height: AppDimensions.spacingMd),
                AppButton(
                  label: 'CANCEL',
                  outlined: true,
                  onPressed: controller.isSaving
                      ? null
                      : () => setState(() {
                            _populateFieldsFromProfile(controller.profile);
                            _isEditing = false;
                          }),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
