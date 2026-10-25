// The categories promo events are grouped into for Portfolio → Promos.
// Each promo event's category is set in the catalogue DB (sets.promo_category,
// filled by tool/build_catalogue_db.py); the keys here must match it.
class PromoCategory {
  final String key;
  final String name;
  // What one event in this category is called, singular and plural:
  // "13 packs", "10 issues", "1 set".
  final String unit;
  final String units;

  const PromoCategory(this.key, this.name, this.unit, this.units);

  String countLabel(int events) => '$events ${events == 1 ? unit : units}';
}

// Display order: the PR pack series first, then the rest.
const promoCategories = [
  PromoCategory('basic', 'Basic PR Packs', 'pack', 'packs'),
  PromoCategory('super', 'Super PR Packs', 'pack', 'packs'),
  PromoCategory('entry', 'Entry PR Packs', 'pack', 'packs'),
  PromoCategory('dreams', 'Hololive Dreams', 'pack', 'packs'),
  PromoCategory('birthday', 'Birthday', 'set', 'sets'),
  PromoCategory('special', 'Special Event Packs', 'set', 'sets'),
  PromoCategory('tournament', 'Tournaments', 'event', 'events'),
  PromoCategory('collab', 'Collabs & events', 'event', 'events'),
  PromoCategory('music', 'Music releases', 'release', 'releases'),
  PromoCategory('vjump', 'V Jump', 'issue', 'issues'),
];

PromoCategory? promoCategoryByKey(String key) {
  for (final c in promoCategories) {
    if (c.key == key) return c;
  }
  return null;
}
