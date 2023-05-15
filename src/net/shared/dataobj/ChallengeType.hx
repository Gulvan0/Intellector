package net.shared.dataobj;

import net.shared.utils.PlayerRef;

enum ChallengeType
{
    Public;
    ByLink;
    Direct(calleeRef:PlayerRef);
}