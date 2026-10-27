import 'package:flutter/foundation.dart';
import '../../../app/router/route_names.dart';
import '../../../core/network/backend_api.dart';

/// Decides where an authenticated learner goes next: the dashboard, or the onboarding questionnaire when
/// they have not finished it yet (the backend answers 403 ONBOARDING_REQUIRED on learning endpoints until then).
class OnboardingGate {
  OnboardingGate._();

  static Future<String> nextRoute() async {
    try {
      final status = await BackendApi.instance.onboardingStatus();
      return status.completed ? RouteNames.dashboard : RouteNames.byteDnaSetup;
    } catch (e) {
      // Cannot tell (offline, backend restarting). Go to the dashboard: if onboarding is in fact missing,
      // the first guarded call triggers the global ONBOARDING_REQUIRED redirect (see main.dart).
      debugPrint('🧭 [OnboardingGate] status check failed ($e); defaulting to the dashboard');
      return RouteNames.dashboard;
    }
  }
}
