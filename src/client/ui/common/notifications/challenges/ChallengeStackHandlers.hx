package client.ui.common.notifications.challenges;

/** What `ChallengeNotificationStack` reports; the card's handlers concern the active challenge **/
typedef ChallengeStackHandlers =
{
    onRowPressed:Int->Void,
    onCardClose:Void->Void,
    onCardDecline:Void->Void,
    onCardAccept:Void->Void,
    onDeclineAll:Void->Void,
    onHideAll:Void->Void
}
