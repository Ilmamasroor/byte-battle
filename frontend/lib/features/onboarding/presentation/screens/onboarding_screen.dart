import 'package:flutter/material.dart';
import '../../../../app/constants/app_constants.dart';
import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_dimensions.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/buttons/app_text_button.dart';
import '../../data/models/onboarding_model.dart';
import '../widgets/onboarding_page.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingModel> _pages = OnboardingModel.pages;

  void _next() {
    if (_currentPage == _pages.length - 1) {
      Navigator.of(context).pushReplacementNamed(RouteNames.login);
    } else {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _skip() {
    Navigator.of(context).pushReplacementNamed(RouteNames.login);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLast = _currentPage == _pages.length - 1;

    return Scaffold(
      body: Stack(
        children: [
          // Full-screen onboarding artwork — the only background shown on
          // this screen (sits on top of the app-wide background painted by
          // BytlBattleApp.builder).
          Positioned.fill(
            child: Image.asset(
              AppConstants.onboardingBackground,
              fit: BoxFit.cover,
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                Align(
                  alignment: Alignment.topRight,
                  child: Padding(
                    padding: const EdgeInsets.all(AppDimensions.spacingMd),
                    child: AppTextButton(
                      label: 'Skip',
                      onPressed: _skip,
                    ),
                  ),
                ),
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: _pages.length,
                    onPageChanged: (i) => setState(() => _currentPage = i),
                    itemBuilder: (context, index) =>
                        OnboardingPage(data: _pages[index]),
                  ),
                ),
                const SizedBox(height: 30),
                _DotIndicator(count: _pages.length, activeIndex: _currentPage),
                const SizedBox(height: AppDimensions.spacingXl),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.screenPadding,
                  ),
                  child: AppButton(
                    label: isLast ? 'GET STARTED' : 'NEXT',
                    onPressed: _next,
                  ),
                ),
                const SizedBox(height: AppDimensions.spacingXl),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DotIndicator extends StatelessWidget {
  final int count;
  final int activeIndex;

  const _DotIndicator({required this.count, required this.activeIndex});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (index) {
        final isActive = index == activeIndex;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: isActive
              ? AppDimensions.dotSizeActive
              : AppDimensions.dotSize,
          height: AppDimensions.dotSize,
          decoration: BoxDecoration(
            color: isActive ? AppColors.primary : AppColors.border,
            borderRadius: BorderRadius.circular(AppDimensions.radiusPill),
          ),
        );
      }),
    );
  }
}
