package client.ui.common.challenges.widget;

/** What `ChallengesWidget` reports; the ids are the challenges' **/
typedef ChallengesWidgetHandlers =
{
    onAccept:Int->Void,
    onDecline:Int->Void,
    onCancel:Int->Void,
    onPreviewOpened:Void->Void
}
