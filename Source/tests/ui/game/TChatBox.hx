package tests.ui.game;

import gfx.game.Sidebox.SideboxEvent;
import net.ServerEvent;
import gfx.game.Chatbox;
import openfl.display.Sprite;
import serialization.GameLogParser.GameLogParserOutput;
import serialization.GameLogParser.ChatEntry;

class TChatBox extends Sprite
{
    private var chatbox:Chatbox;

    private function setBox(v:Chatbox)
    {
        removeChild(chatbox);
        chatbox = v;
        addChild(chatbox);
    }

    @steps(4)
    private function _seq_initTypes(i:Int) 
    {
        switch i
        {
            case 0:
                setBox(new Chatbox(false, false));
            case 1:
                setBox(new Chatbox(true, false));
            case 2:
                setBox(new Chatbox(true, true));
            case 3:
                var data:GameLogParserOutput = new GameLogParserOutput();
                data.whiteLogin = 'authorW';
                data.blackLogin = 'AuthorB';
                data.chatEntries = [PlayerMessage(White, 'text1'), Log('Some random log'), PlayerMessage(Black, 'Veeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeery long text2')];
                setBox(new Chatbox(false, false, data));
        }
    }

    private var _checks_initTypes:Map<Int, Array<String>> = [
        -1 => ['Enter can be used to send message', 'Illegal chars are cut from the text', 'Chat autoscrolls on overflow'],
        0 => ['Actual game (try typing)'],
        1 => ['Spectation (try typing)'],
        2 => ['Revisit'],
        3 => ['Actualized (try typing)']
    ];

    private var netEvents:Array<ServerEvent> = [Message('player', 'insult'), SpectatorMessage('spec', 'opinion'), GameEnded('w', 'bre'), PlayerDisconnected('b'), PlayerReconnected('b'), NewSpectator('spec2'), SpectatorLeft('spec2'), DrawOffered, DrawCancelled, DrawAccepted, DrawDeclined, TakebackOffered, TakebackCancelled, TakebackAccepted, TakebackDeclined];

    @interval(200)
    @iterations(15)
    private function _auto_netEvents(i:Int) 
    {
        chatbox.handleNetEvent(netEvents[i]);
    }

    private var _checks_netEvents:Array<String> = ["Message('player', 'insult'), SpectatorMessage('spec', 'opinion'), GameEnded('w', 'bre'), PlayerDisconnected('b'), PlayerReconnected('b'), NewSpectator('spec2'), SpectatorLeft('spec2'), DrawOffered, DrawCancelled, DrawAccepted, DrawDeclined, TakebackOffered, TakebackCancelled, TakebackAccepted, TakebackDeclined"];

    private var sideEvents:Array<SideboxEvent> = [OfferDrawPressed, CancelDrawPressed, AcceptDrawPressed, DeclineDrawPressed, OfferTakebackPressed, CancelTakebackPressed, AcceptTakebackPressed, DeclineTakebackPressed];

    @interval(200)
    @iterations(8)
    private function _auto_sideEvents(i:Int) 
    {
        chatbox.handleNetEvent(netEvents[i]);
    }

    private var _checks_sideEvents:Array<String> = ['Offer/Cancel/Accept/Decline X Draw/Takeback'];

    public function new() 
    {
        super();    
    }
}