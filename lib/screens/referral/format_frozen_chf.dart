/// Formats the CHF amount frozen at credit for history and dashboard rows.
/// The ARB string already prefixes `CHF`, so this is the numeric part only.
String formatFrozenChfAmount(String raw) {
  final n = num.tryParse(raw);
  if (n == null) return raw;
  return n.toStringAsFixed(2);
}
