// GENERATED from the approved Promo cover mockups (Promo Collection Banners
// canvas, 2026-10-25) - each category's cover is fixed, not random.
//
// A cover is three card images layered back to front: top-left, bottom-left
// and the wedge on the right. All numbers are fractions of the cover area
// (x of its width, y of its height), so the cover scales with the tile.
//   * left/top/width/height: where the card image sits (it overhangs the
//     cover; only the part inside shows).
//   * masks: soft edges of the layer's slice. Each fades from see-through at
//     (x0, y0) to solid at (x1, y1), across the line between those points;
//     several masks on one layer all apply (the wedge has two edges).
//   * fade: (position down the card, opacity) stops that fade out the card's
//     own name/HP header and rules text, so only artwork shows.
import '../widgets/promo_cover.dart';

const Map<String, List<CoverLayer>> promoCovers = {
  'basic': [
    // hBP02-032-P
    CoverLayer(cardId: 2417, left: -0.4742, top: -0.3461, width: 1.7, height: 1.8216, masks: [], fade: []),
    // hBP07-055-P
    CoverLayer(
      cardId: 2553,
      left: -0.5348,
      top: 0.3448,
      width: 1.55,
      height: 1.6608,
      masks: [CoverMask(0.4885, 0.3882, 0.5, 0.4999)],
      fade: [(0.13, 0), (0.17, 1)],
    ),
    // hBP06-018-P
    CoverLayer(
      cardId: 2517,
      left: -0.0753,
      top: 0.0849,
      width: 1.55,
      height: 1.6608,
      masks: [CoverMask(0.3684, 0.3909, 0.4447, 0.4542), CoverMask(0.3684, 0.6091, 0.4447, 0.5458)],
      fade: [(0.13, 0), (0.17, 1), (0.44, 1), (0.5, 0)],
    ),
  ],
  'super': [
    // hSD01-011-P
    CoverLayer(cardId: 2612, left: -0.6101, top: -0.3461, width: 1.7, height: 1.8216, masks: [], fade: []),
    // hBP01-013-P-03
    CoverLayer(
      cardId: 2334,
      left: -0.5348,
      top: 0.3944,
      width: 1.55,
      height: 1.6608,
      masks: [CoverMask(0.4885, 0.3882, 0.5, 0.4999)],
      fade: [(0.13, 0), (0.17, 1)],
    ),
    // hBP01-020-P
    CoverLayer(
      cardId: 2337,
      left: -0.0753,
      top: 0.0849,
      width: 1.55,
      height: 1.6608,
      masks: [CoverMask(0.3684, 0.3909, 0.4447, 0.4542), CoverMask(0.3684, 0.6091, 0.4447, 0.5458)],
      fade: [(0.13, 0), (0.17, 1), (0.44, 1), (0.5, 0)],
    ),
  ],
  'birthday': [
    // hBD24-042-P
    CoverLayer(cardId: 2300, left: -0.6101, top: -0.3461, width: 1.7, height: 1.8216, masks: [], fade: []),
    // hBD24-001-P
    CoverLayer(
      cardId: 2259,
      left: -0.4112,
      top: 0.3448,
      width: 1.55,
      height: 1.6608,
      masks: [CoverMask(0.4885, 0.3882, 0.5, 0.4999)],
      fade: [(0.13, 0), (0.17, 1)],
    ),
    // hBD24-005-P
    CoverLayer(
      cardId: 2263,
      left: -0.0753,
      top: 0.0849,
      width: 1.55,
      height: 1.6608,
      masks: [CoverMask(0.3684, 0.3909, 0.4447, 0.4542), CoverMask(0.3684, 0.6091, 0.4447, 0.5458)],
      fade: [(0.13, 0), (0.17, 1), (0.44, 1), (0.5, 0)],
    ),
  ],
  'tournament': [
    // hBP03-006-P
    CoverLayer(cardId: 2431, left: -0.6101, top: -0.3461, width: 1.7, height: 1.8216, masks: [], fade: []),
    // hBP04-002-P
    CoverLayer(
      cardId: 2467,
      left: -0.473,
      top: 0.4112,
      width: 1.55,
      height: 1.6608,
      masks: [CoverMask(0.4885, 0.3882, 0.5, 0.4999)],
      fade: [(0.13, 0), (0.17, 1)],
    ),
    // hBP01-004-P
    CoverLayer(
      cardId: 2326,
      left: -0.0753,
      top: 0.0849,
      width: 1.55,
      height: 1.6608,
      masks: [CoverMask(0.3684, 0.3909, 0.4447, 0.4542), CoverMask(0.3684, 0.6091, 0.4447, 0.5458)],
      fade: [(0.13, 0), (0.17, 1), (0.44, 1), (0.5, 0)],
    ),
  ],
  'music': [
    // hBP04-083-P-02
    CoverLayer(cardId: 2495, left: -0.632, top: -0.3461, width: 1.7, height: 1.8216, masks: [], fade: []),
    // hBP01-013-P-02
    CoverLayer(
      cardId: 2333,
      left: -0.4882,
      top: 0.1289,
      width: 1.55,
      height: 1.6608,
      masks: [CoverMask(0.4885, 0.3882, 0.5, 0.4999)],
      fade: [(0.13, 0), (0.17, 1)],
    ),
    // hBP03-051-P-02
    CoverLayer(
      cardId: 2448,
      left: -0.1522,
      top: -0.2474,
      width: 1.55,
      height: 1.6608,
      masks: [CoverMask(0.3684, 0.3909, 0.4447, 0.4542), CoverMask(0.3684, 0.6091, 0.4447, 0.5458)],
      fade: [(0.13, 0), (0.17, 1), (0.55, 1), (0.6, 0)],
    ),
  ],
  'vjump': [
    // hBP07-009-P
    CoverLayer(cardId: 2540, left: -0.632, top: -0.3461, width: 1.7, height: 1.8216, masks: [], fade: []),
    // hBP01-076-P-02
    CoverLayer(
      cardId: 2375,
      left: -0.3798,
      top: 0.2724,
      width: 1.55,
      height: 1.6608,
      masks: [CoverMask(0.4885, 0.3882, 0.5, 0.4999)],
      fade: [(0.16, 0), (0.21, 1)],
    ),
    // hBP04-009-P-02
    CoverLayer(
      cardId: 2470,
      left: -0.2298,
      top: 0.0017,
      width: 1.55,
      height: 1.6608,
      masks: [CoverMask(0.3684, 0.3909, 0.4447, 0.4542), CoverMask(0.3684, 0.6091, 0.4447, 0.5458)],
      fade: [(0.16, 0), (0.21, 1), (0.55, 1), (0.6, 0)],
    ),
  ],
  'collab': [
    // hBP07-073-P
    CoverLayer(cardId: 2561, left: -0.627, top: -0.3461, width: 1.7, height: 1.8216, masks: [], fade: []),
    // hSD09-007-P
    CoverLayer(
      cardId: 2649,
      left: -0.4882,
      top: 0.2724,
      width: 1.55,
      height: 1.6608,
      masks: [CoverMask(0.4885, 0.3882, 0.5, 0.4999)],
      fade: [(0.16, 0), (0.21, 1)],
    ),
    // hSD08-005-P
    CoverLayer(
      cardId: 2642,
      left: -0.1213,
      top: -0.131,
      width: 1.55,
      height: 1.6608,
      masks: [CoverMask(0.3684, 0.3909, 0.4447, 0.4542), CoverMask(0.3684, 0.6091, 0.4447, 0.5458)],
      fade: [(0.16, 0), (0.21, 1), (0.55, 1), (0.6, 0)],
    ),
  ],
  'dreams': [
    // hBP03-054-P
    CoverLayer(cardId: 2450, left: -0.4399, top: -0.3461, width: 1.7, height: 1.8216, masks: [], fade: []),
    // hBP03-036-P
    CoverLayer(
      cardId: 2442,
      left: -0.3337,
      top: 0.169,
      width: 1.55,
      height: 1.6608,
      masks: [CoverMask(0.4885, 0.3882, 0.5, 0.4999)],
      fade: [(0.16, 0), (0.21, 1)],
    ),
    // hBP07-010-P
    CoverLayer(
      cardId: 2541,
      left: 0.1888,
      top: -0.131,
      width: 1.55,
      height: 1.6608,
      masks: [CoverMask(0.3684, 0.3909, 0.4447, 0.4542), CoverMask(0.3684, 0.6091, 0.4447, 0.5458)],
      fade: [(0.16, 0), (0.21, 1), (0.42, 1), (0.47, 0)],
    ),
  ],
  'special': [
    // hBP02-026-SR
    CoverLayer(cardId: 3079, left: -0.5079, top: -0.3461, width: 1.7, height: 1.8216, masks: [], fade: []),
    // hBP01-071-SR
    CoverLayer(
      cardId: 3093,
      left: -0.3798,
      top: 0.2694,
      width: 1.55,
      height: 1.6608,
      masks: [CoverMask(0.4885, 0.3882, 0.5, 0.4999)],
      fade: [(0.13, 0), (0.17, 1)],
    ),
    // hBP07-066-SR
    CoverLayer(
      cardId: 3086,
      left: -0.0596,
      top: 0.1181,
      width: 1.55,
      height: 1.6608,
      masks: [CoverMask(0.3684, 0.3909, 0.4447, 0.4542), CoverMask(0.3684, 0.6091, 0.4447, 0.5458)],
      fade: [(0.13, 0), (0.17, 1), (0.44, 1), (0.5, 0)],
    ),
  ],
  'entry': [
    // hBP01-079-P
    CoverLayer(cardId: 2378, left: -0.6101, top: -0.3461, width: 1.7, height: 1.8216, masks: [], fade: []),
    // hBP01-062-P
    CoverLayer(
      cardId: 2366,
      left: -0.3646,
      top: 0.2724,
      width: 1.55,
      height: 1.6608,
      masks: [CoverMask(0.4885, 0.3882, 0.5, 0.4999)],
      fade: [(0.16, 0), (0.21, 1)],
    ),
    // hBP02-042-P
    CoverLayer(
      cardId: 2419,
      left: -0.0753,
      top: -0.0483,
      width: 1.55,
      height: 1.6608,
      masks: [CoverMask(0.3684, 0.3909, 0.4447, 0.4542), CoverMask(0.3684, 0.6091, 0.4447, 0.5458)],
      fade: [(0.16, 0), (0.21, 1), (0.55, 1), (0.6, 0)],
    ),
  ],
};
