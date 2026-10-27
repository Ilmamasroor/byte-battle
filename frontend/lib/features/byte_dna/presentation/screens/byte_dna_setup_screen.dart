import 'package:flutter/material.dart';
import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_dimensions.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/models/backend_models.dart';
import '../../../../core/network/backend_api.dart';
import '../../../../core/network/network_exception.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../widgets/preference_chip.dart';

/// The one-time post-signup questionnaire that seeds the learner's baseline Byte DNA and profile.
///
/// The questions (and their allowed values) come from `GET /api/onboarding/questions`, so the app can never
/// offer an answer the backend rejects. The answers are posted in one call to `POST /api/onboarding`, which
/// saves the learner profile and Byte DNA together; until that succeeds the learning endpoints answer 403.
class ByteDnaSetupScreen extends StatefulWidget {
  const ByteDnaSetupScreen({super.key});

  @override
  State<ByteDnaSetupScreen> createState() => _ByteDnaSetupScreenState();
}

class _ByteDnaSetupScreenState extends State<ByteDnaSetupScreen> {
  final _api = BackendApi.instance;
  final Map<String, TextEditingController> _custom = {};

  List<OnboardingQuestionModel>? _questions;
  String? _loadError;
  bool _submitting = false;

  /// question id -> chosen value (single / number choice) or set of values (multi select)
  final Map<String, Object> _answers = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    for (final c in _custom.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loadError = null;
      _questions = null;
    });
    try {
      final questions = await _api.onboardingQuestions();
      if (!mounted) return;
      setState(() => _questions = questions);
    } on NetworkException catch (e) {
      if (!mounted) return;
      setState(() => _loadError = e.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadError = 'Could not load the questions. Please try again.');
    }
  }

  Set<String> _multi(String id) => (_answers[id] ??= <String>{}) as Set<String>;

  String? _validate() {
    for (final q in _questions ?? const <OnboardingQuestionModel>[]) {
      if (!q.required) continue;
      final a = _answers[q.id];
      final empty = a == null || (a is String && a.trim().isEmpty) || (a is Set && a.isEmpty);
      if (empty) return 'Please answer: ${q.prompt}';
    }
    return null;
  }

  Map<String, dynamic> _payload() {
    final body = <String, dynamic>{};
    for (final q in _questions!) {
      final a = _answers[q.id];
      if (q.isMulti) {
        body[q.id] = (a as Set<String>? ?? <String>{}).toList();
      } else if (a is String && a.trim().isNotEmpty) {
        body[q.id] = q.type == 'NUMBER_CHOICE' ? (int.tryParse(a) ?? a) : a.trim();
      }
    }
    return body;
  }

  Future<void> _submit() async {
    final problem = _validate();
    if (problem != null) {
      AppSnackBar.error(context, problem);
      return;
    }
    setState(() => _submitting = true);
    try {
      await _api.submitOnboarding(_payload());
      if (!mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil(RouteNames.dashboard, (route) => false);
    } on NetworkException catch (e) {
      if (!mounted) return;
      AppSnackBar.error(context, e.message);
    } catch (_) {
      if (!mounted) return;
      AppSnackBar.error(context, 'Something went wrong. Please try again.');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Mandatory step: block the Android back button / edge swipe (the route stack is cleared on arrival).
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          automaticallyImplyLeading: false,
          title: const Text('ByteDNA Setup', style: AppTextStyles.heading2),
        ),
        body: SafeArea(child: _body()),
      ),
    );
  }

  Widget _body() {
    if (_loadError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.screenPadding),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_loadError!, style: AppTextStyles.body, textAlign: TextAlign.center),
              const SizedBox(height: AppDimensions.spacingMd),
              AppButton(label: 'TRY AGAIN', onPressed: _load),
            ],
          ),
        ),
      );
    }
    final questions = _questions;
    if (questions == null) return const Center(child: CircularProgressIndicator());

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppDimensions.screenPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RichText(
            text: const TextSpan(
              style: AppTextStyles.heading1,
              children: [
                TextSpan(text: 'Build your '),
                TextSpan(text: 'Byte DNA', style: TextStyle(color: AppColors.accentCyan)),
              ],
            ),
          ),
          const SizedBox(height: AppDimensions.spacingSm),
          Text('A few quick questions so we can personalize your lessons.', style: AppTextStyles.body),
          const SizedBox(height: AppDimensions.spacingXl),
          for (final q in questions) ...[
            _question(q),
            const SizedBox(height: AppDimensions.spacingXl),
          ],
          AppButton(
            label: 'CONTINUE',
            icon: Icons.arrow_forward_rounded,
            isLoading: _submitting,
            onPressed: _submitting ? null : _submit,
          ),
          const SizedBox(height: AppDimensions.spacingLg),
        ],
      ),
    );
  }

  Widget _question(OnboardingQuestionModel q) {
    final selectedSingle = _answers[q.id] is String ? _answers[q.id] as String : null;
    final selectedMulti = q.isMulti ? _multi(q.id) : const <String>{};

    // Values typed by the learner that are not among the offered options (shown as extra chips).
    final offered = q.options.map((o) => o.value).toSet();
    final extras = q.isMulti
        ? selectedMulti.where((v) => !offered.contains(v)).toList()
        : (selectedSingle != null && !offered.contains(selectedSingle) ? [selectedSingle] : <String>[]);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(q.required ? q.prompt : '${q.prompt} (optional)', style: AppTextStyles.bodyBold),
        const SizedBox(height: AppDimensions.spacingSm),
        Wrap(
          spacing: AppDimensions.spacingSm,
          runSpacing: AppDimensions.spacingSm,
          children: [
            for (final o in q.options)
              PreferenceChip(
                label: o.label,
                selected: q.isMulti ? selectedMulti.contains(o.value) : selectedSingle == o.value,
                onTap: () => setState(() => _toggle(q, o.value)),
              ),
            for (final v in extras)
              PreferenceChip(label: v, selected: true, onTap: () => setState(() => _toggle(q, v))),
          ],
        ),
        if (q.allowCustom) ...[
          const SizedBox(height: AppDimensions.spacingSm),
          TextField(
            controller: _custom.putIfAbsent(q.id, () => TextEditingController()),
            style: AppTextStyles.body,
            textInputAction: TextInputAction.done,
            decoration: InputDecoration(
              hintText: q.isMulti ? 'Add your own and press enter' : 'Or type your own',
              prefixIcon: const Icon(Icons.edit_rounded, color: AppColors.textHint, size: 18),
            ),
            onSubmitted: (text) => setState(() {
              final t = text.trim();
              if (t.isEmpty) return;
              if (q.isMulti) {
                _addIfRoom(q, t);
              } else {
                _answers[q.id] = t;
              }
              _custom[q.id]!.clear();
            }),
            onChanged: q.isMulti
                ? null
                : (text) => setState(() {
                      if (text.trim().isNotEmpty) _answers[q.id] = text.trim();
                    }),
          ),
        ],
        if (q.isMulti && q.maxSelections != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text('Up to ${q.maxSelections}', style: AppTextStyles.caption),
          ),
      ],
    );
  }

  void _toggle(OnboardingQuestionModel q, String value) {
    if (q.isMulti) {
      final set = _multi(q.id);
      if (!set.remove(value)) _addIfRoom(q, value);
    } else {
      _answers[q.id] = value;
      _custom[q.id]?.clear();
    }
  }

  void _addIfRoom(OnboardingQuestionModel q, String value) {
    final set = _multi(q.id);
    final max = q.maxSelections;
    if (max != null && set.length >= max) {
      AppSnackBar.error(context, 'You can pick up to $max.');
      return;
    }
    set.add(value);
  }
}
