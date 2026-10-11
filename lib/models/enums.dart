enum GridSize { two, three }

// Values match the rarity strings stored in holo_catalogue.db exactly
enum Rarity { c, u, r, rr, sr, osr, ur, our, sec, s, sy }

enum Archetype { white, green, red, blue, purple, yellow, support }

enum CardSet { hBP01, hBP02, hBP03, hBP04, hBP05, hBP06, hBP07, hBP08, sy }

// Filter sheet selections — shared between the provider/page state that owns
// the filter and the bottom sheet that edits it.
enum OwnedFilter { all, owned, notOwned }

enum FoilFilter { all, foilOnly, nonFoilOnly }

enum InventorySort { cardNumber, mostDuplicates, highestTotalValue, highestSingleValue }

/// Card order for Catalogue and Portfolio set detail. Cards always stay
/// grouped in their sets; this orders them within each set.
enum ValueSort { cardNumber, valueHighToLow, valueLowToHigh }
