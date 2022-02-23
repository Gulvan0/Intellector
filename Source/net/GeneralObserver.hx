package net;

import net.EventProcessingQueue.INetObserver;
import openfl.Assets;
import dict.Utils;
import dict.Dictionary;
import gfx.components.Dialogs;

class GeneralObserver implements INetObserver
{
    public static var acceptsDirectChallenges:Bool = true;

    private function onReconnectionForbidden() 
    {
        Networker.doNotReconnect = true;
        Dialogs.alert("Session closed", "Alert");
    }

    private static function challengeReceiver(caller:String, startSecs:Int, bonusSecs:Int, color:String) 
    {
        Assets.getSound("sounds/social.mp3").play();

        var onConfirmed = Networker.emitEvent.bind(AcceptDirectChallenge(caller));
        var onDeclined = Networker.emitEvent.bind(DeclineDirectChallenge(caller));

        var detailsStr = Utils.challengeDetails(startSecs, bonusSecs, color);
        var title = Dictionary.getPhrase(INCOMING_CHALLENGE_TITLE);
        var text = Dictionary.getPhrase(INCOMING_CHALLENGE_TEXT, [caller, detailsStr]);

        Dialogs.confirm(text, title, onConfirmed, onDeclined);
    }

    public function handleNetEvent(event:ServerEvent)
    {
        switch event 
        {
            case IncomingDirectChallenge(enemy, colour, startSecs, bonusSecs):
                if (acceptsDirectChallenges)
                    challengeReceiver(enemy, startSecs, bonusSecs, colour);
            case DontReconnect:
                onReconnectionForbidden();
            default:
        }
    }

    public function new()
    {

    }
}