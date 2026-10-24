package client.ui.common.overlays.challenge;

import client.datatypes.challenge.creation.ChallengeDraft;

/**
    Opens the challenge creation overlay for the current user, from places that know nothing about
    the identity or the networking behind it. The app assigns `launch` on startup.
**/
class ChallengeCreationLauncher
{
    /** `prefill` adjusts the remembered values the form opens with **/
    public static var launch:Null<ChallengeDraft->Void>->Void = _ -> {};
}
