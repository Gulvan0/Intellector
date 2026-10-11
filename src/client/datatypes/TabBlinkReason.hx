package client.datatypes;

import client.datatypes.challenge.IncomingChallenge;

/** Why the browser tab blinks; a later constructor outranks an earlier one **/
enum TabBlinkReason
{
    IncomingChallenge;
    GameStarted;
}
