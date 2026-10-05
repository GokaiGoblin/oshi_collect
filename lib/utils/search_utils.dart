/// Normalizes a search query to tolerate missing leading zeros in card numbers.
///
/// Card numbers follow the format {prefix}{2digits}-{3digits}, e.g. hBP06-010.
/// This pads any `digits-digits` substring in the query so that:
///   - the segment before the hyphen is at least 2 digits
///   - the segment after the hyphen is at least 3 digits
///
/// Segments that already meet or exceed the expected length are left alone,
/// so "06-010" → "06-010" (no change) and "6-10" → "06-010".
String normalizeCardNumberQuery(String query) {
  return query.replaceAllMapped(
    RegExp(r'(\d+)-(\d+)'),
    (match) {
      var pre = match.group(1)!;
      var post = match.group(2)!;
      if (pre.length < 2) pre = pre.padLeft(2, '0');
      if (post.length < 3) post = post.padLeft(3, '0');
      return '$pre-$post';
    },
  );
}
