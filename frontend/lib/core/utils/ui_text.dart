/// Small text helpers shared by the design system.
class UiText {
  UiText._();

  /// Words that stay upper-case when a SHOUTING label is softened.
  static const _acronyms = {'AI', 'XP', 'DNA', 'API', 'UI', 'UX', 'SQL', 'OS', 'DSA', 'JVM', 'HTTP', 'DBMS', 'OOP'};

  /// "NEXT: RELATE" -> "Next: relate". Only touches labels that are entirely upper-case, so deliberate
  /// mixed-case copy ("Try again", "iOS") is left alone. All-caps buttons read as shouting; sentence case is
  /// calmer and easier to scan.
  static String sentence(String label) {
    final letters = label.replaceAll(RegExp(r'[^A-Za-z]'), '');
    if (letters.length < 2 || label != label.toUpperCase()) return label;

    final lower = label.toLowerCase().replaceAllMapped(
          RegExp(r'[a-z]+'),
          (m) => _acronyms.contains(m[0]!.toUpperCase()) ? m[0]!.toUpperCase() : m[0]!,
        );
    final i = lower.indexOf(RegExp(r'[A-Za-z]'));
    return i < 0 ? lower : lower.replaceRange(i, i + 1, lower[i].toUpperCase());
  }
}
