/// Central place for the backend base URL and every route path.
///
/// Matches "Byte Battle Backend — API Reference (Developer 1)".
class ApiEndpoints {
  ApiEndpoints._();

  // ---------------------------------------------------------------------
  // Base URL
  // ---------------------------------------------------------------------
  // Toggle this one flag to switch every request between your local
  // backend and the ngrok tunnel — nothing else in the app needs to
  // change.
  static const bool _useNgrok = true;

  static const String _localBaseUrl = 'http://localhost:8080';

  // NOTE: free ngrok URLs are NOT permanent — every time the tunnel is
  // restarted on the backend machine, ngrok issues a new random URL and
  // this constant has to be updated to match it.
  static const String _ngrokBaseUrl =
      'https://48a3-2409-40c4-168-1969-c727-b83f-9175-2e87.ngrok-free.app';

  static const String baseUrl = _useNgrok ? _ngrokBaseUrl : _localBaseUrl;

  // ---- Auth (public, no token required) ----
  static const String register = '/api/auth/register';
  static const String login = '/api/auth/login';

  // ---- Users (protected, requires Authorization: Bearer <token>) ----
  // Everything about "the currently logged-in user" — no id needed, the
  // backend resolves it from the bearer token itself.
  // GET/PUT/DELETE all hit the same path (`me`); the HTTP verb decides
  // whether it's a read, a partial update, or an account deletion.
  static const String me = '/api/users/me';
  static const String changePassword = '/api/users/me/password';

  // ---- Learner profile (protected, requires Authorization: Bearer <token>) ----
  // GET reads it, POST creates it (first time only), PUT partially
  // updates it — same `/api/learner-profile` path for all three, the
  // backend again resolves "whose" from the bearer token.
  static const String learnerProfile = '/api/learner-profile';

  // ---- AI (protected, requires Authorization: Bearer <token>) ----
  // All three take `?conceptId=<uuid>` as a query param and no JSON body.
  // Unlike every other endpoint in this file, these do NOT come back
  // wrapped in the usual `{success, message, data, timestamp}` envelope —
  // the response body IS the payload directly. See ApiClient.postRaw.
  static const String aiCanonicalKnowledge = '/api/ai/canonical-knowledge';
  static const String aiAnalogy = '/api/ai/analogy';
  static const String aiMnemonic = '/api/ai/mnemonic';

  // ---- AI — Battle / Coding / Debugging (protected, requires
  // Authorization: Bearer <token>) ----
  // Unlike the three above, these four take a JSON *body* (concept,
  // question, canonicalKnowledge, diagnosis, hintLevel — see each
  // datasource) instead of a `conceptId` query param. Their responses are
  // also NOT wrapped in `{success, message, data, timestamp}` — the
  // response body IS the payload directly, so callers use
  // ApiClient.postRaw just like the three endpoints above.
  static const String aiBattleHint = '/api/ai/battle-hint';
  static const String aiCodingFeedback = '/api/ai/coding-feedback';
  static const String aiDebuggingHint = '/api/ai/debugging-hint';
  static const String aiBossBattle = '/api/ai/boss-battle';

  // ---- AI — Interview (protected, requires Authorization: Bearer <token>) ----
  // Same JSON-body / not-wrapped-in-{success,data} shape as the four
  // endpoints above — {concept, canonicalKnowledge, ...} in, raw payload
  // back out, so callers use ApiClient.postRaw.
  static const String aiInterviewQuestion = '/api/ai/interview/question';
  static const String aiInterviewEvaluate = '/api/ai/interview/evaluate';

  // ---- AI — Personalization (protected, requires Authorization: Bearer
  // <token>) ----
  // Same JSON-body / not-wrapped-in-{success,data} shape as the AI
  // endpoints above — request body in, raw payload back out, so callers
  // use ApiClient.postRaw. aiDiagnoseSummary takes a userId + list of the
  // same activity shape aiDiagnose uses per-activity.
  static const String aiOnboarding = '/api/ai/onboarding';
  static const String aiDiagnose = '/api/ai/diagnose';
  static const String aiDiagnoseSummary = '/api/ai/diagnose/summary';
  static const String aiRecommend = '/api/ai/recommend';
}
