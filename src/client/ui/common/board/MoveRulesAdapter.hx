package client.ui.common.board;

import intellectorboard.movement.rules.MoveDestinations;
import intellectorboard.movement.rules.PremoveDestinations;
import intellectorboard.movement.rules.CoreRules;

class MoveRulesAdapter
{
    public static final DEFAULT:MoveRules = {
        getLegalDestinations: (from, pieces) -> MoveDestinations.getPossibleDestinations(from, pieces),
        getPremoveDestinations: PremoveDestinations.getPossiblePremoveDestinations,
        isPromotionPossible: CoreRules.isPromotionEligible,
        isChameleonPossible: CoreRules.isChameleonEligible,
        isAuraActive: (coords, pieces) -> CoreRules.isHexAffectedByAura(pieces, coords)
    };
}
