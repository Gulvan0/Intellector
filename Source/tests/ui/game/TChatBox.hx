package tests.ui.game;

import tests.ui.TestedComponent.ComponentGraphics;
import openfl.events.KeyboardEvent;
import gfx.common.ActionBar.ActionBtn;
import struct.ActualizationData;
import net.ServerEvent;
import gfx.game.Chatbox;
import openfl.display.Sprite;
import serialization.GameLogParser.GameLogParserOutput;
import serialization.GameLogParser.ChatEntry;

class AugmentedChatBox extends Chatbox
{
    private override function onKeyPress(e:KeyboardEvent) 
    {
        UITest.logHandledEvent('keypress|${e.keyCode}');
        super.onKeyPress(e);
    }

    public function _imitateEvent(encodedEvent:String)
    {
        var parts:Array<String> = encodedEvent.split('|');

        if (parts[0] != 'keypress')
            throw "Cant decode event: " + encodedEvent;

        var event = new KeyboardEvent(KeyboardEvent.KEY_DOWN);
        event.keyCode = Std.parseInt(parts[1]);
        super.onKeyPress(event);
    }

    public function new(ownerSpectator:Bool, ?data:ActualizationData)
    {
        super(ownerSpectator);
        actualizationData = data;
    }
}

enum InitType
{
    Playable;
    Spectation;
    Revisit;
    Reconnect;
}

class TChatbox extends TestedComponent
{
    private var chatbox:AugmentedChatBox;

    private var _initparam_type:InitType = Playable;

    private var _checks_netEvents:Array<String> = ["Message('player', 'insult'), SpectatorMessage('spec', 'opinion'), GameEnded('w', 'bre'), PlayerDisconnected('b'), PlayerReconnected('b'), NewSpectator('spec2'), SpectatorLeft('spec2'), DrawOffered, DrawCancelled, DrawAccepted, DrawDeclined, TakebackOffered, TakebackCancelled, TakebackAccepted, TakebackDeclined"];
    private var _checks_sideEvents:Array<String> = ['Offer/Cancel/Accept/Decline X Draw/Takeback'];
    private var _checks:Array<String> = ['Enter can be used to send message', 'Illegal chars are cut from the text', 'Chat autoscrolls on overflow', 'Messages can be sent'];

    @iterations(15)
    private function _seq_netEvents(i:Int) 
    {
        var event = switch i
        {
            case 0: Message('player', 'insult');
            case 1: SpectatorMessage('spec', 'opinion');
            case 2: GameEnded('w', 'bre');
            case 3: PlayerDisconnected('Black');
            case 4: PlayerReconnected('Black');
            case 5: NewSpectator('spec2');
            case 6: SpectatorLeft('spec2');
            case 7: DrawOffered;
            case 8: DrawCancelled;
            case 9: DrawAccepted;
            case 10: DrawDeclined;
            case 11: TakebackOffered;
            case 12: TakebackCancelled;
            case 13: TakebackAccepted;
            case 14: TakebackDeclined;
            default: throw 'Iteration not defined: $i';
        }
        chatbox.handleNetEvent(event);
    }

    @iterations(8)
    private function _seq_sideEvents(i:Int) 
    {
        var event = switch i
        {
            case 0: OfferDraw;
            case 1: CancelDraw;
            case 2: AcceptDraw;
            case 3: DeclineDraw;
            case 4: OfferTakeback;
            case 5: CancelTakeback;
            case 6: AcceptTakeback;
            case 7: DeclineTakeback;
            default: throw 'Iteration not defined: $i';
        }
        chatbox.reactToOwnAction(event);
    }
    
    private override function getComponent():ComponentGraphics
    {
		return Component(chatbox);
    }

    private override function rebuildComponent()
    {
        chatbox = new AugmentedChatBox(_initparam_type == Spectation || _initparam_type == Revisit);
        if (_initparam_type == Revisit)
        {
            var po:GameLogParserOutput = new GameLogParserOutput();
            po.whiteLogin = 'authorW';
            po.blackLogin = 'AuthorB';
            po.outcome = Breakthrough;
            po.winnerColor = White;

            var data:ActualizationData = new ActualizationData();
            data.logParserOutput = po;

            chatbox = new AugmentedChatBox(true, data);
        }
        else if (_initparam_type == Reconnect)
        {
            var po:GameLogParserOutput = new GameLogParserOutput();
            po.whiteLogin = 'authorW';
            po.blackLogin = 'AuthorB';
            po.chatEntries = [PlayerMessage(White, 'text1'), Log('Some random log'), PlayerMessage(Black, 'Veeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeery long text2')];
                
            var data:ActualizationData = new ActualizationData();
            data.logParserOutput = po;

            chatbox = new AugmentedChatBox(false, data);
        }
        else if (_initparam_type == Spectation)
            chatbox = new AugmentedChatBox(true);
        else
            chatbox = new AugmentedChatBox(false);
	}

    public override function _imitateEvent(encodedEvent:String)
    {
        chatbox._imitateEvent(encodedEvent);
    }
}