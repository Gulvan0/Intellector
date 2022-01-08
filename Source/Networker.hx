package;

import gfx.components.Dialogs;
import gfx.ScreenManager;
import struct.PieceColor;
import url.Utils;
import dict.Dictionary;
import struct.PieceType;
import openfl.utils.Assets;
import js.Browser;
import haxe.Json;
import hx.ws.WebSocket;
import gfx.components.gamefield.GameCompound;

using utils.CallbackTools;
using StringTools;
using Lambda;

enum OutgoingEvent
{
    //TODO: Fill
}

enum IncomingEvent
{
    //TODO: Fill
    Message(text:String);
}

typedef RawNetEvent =
{
    var name:String;
    var data:Dynamic;
}

typedef BattleData =
{
    var match_id:Int;
    var enemy:String;
    var colour:String;
    var startSecs:Int;
    var bonusSecs:Int;
}

typedef MoveData =
{
    var issuer_login:String;
    var fromI:Int;
    var toI:Int;
    var fromJ:Int;
    var toJ:Int;
    var morphInto:Null<String>;
}

typedef GameOverData =
{
    var winner_color:String;
    var reason:String;
}

typedef TimeData =
{
    var whiteSeconds:Float;
    var blackSeconds:Float;
    var timestamp:Float;
    var pingSubtractionSide:String;
}

typedef OpenChallengeData = 
{
    var challenger:String;
    var startSecs:Int;
    var bonusSecs:Int;
    var color:Null<String>;
}

typedef MessageData =
{
    var issuer_login:String;
    var message:String;
}

typedef OngoingBattleData =
{
    var match_id:Int;
    var requestedColor:String;
    var whiteLogin:String;
    var blackLogin:String;
    var whiteSeconds:Float;
    var blackSeconds:Float;
    var timestamp:Float;
    var pingSubtractionSide:String;
    var position:String;
    var currentLog:String;
}

interface INetObserver 
{
    public function handleNetEvent(event:IncomingEvent):Void;
}

class Networker
{
    private static var allIncomingEventNames:Array<String>;

    private static var _ws:WebSocket;
    public static var login:String;

    private static var eventMap:Map<String, Dynamic->Void> = [];
    private static var observers:Array<INetObserver> = [];

    public static var suppressAlert:Bool;
    public static var doNotReconnect:Bool = false;

    private static function eventConstructorByName(name:String):String
    {
        var constr:String = name.charAt(0).toUpperCase();
        var i:Int = 1;
        while (i < name.length)
        {
            var char = name.charAt(i);
            if (char == "_")
            {
                i++;
                constr += name.charAt(i).toUpperCase();
            }
            else
                constr += name.charAt(i);

            i++;
        }

        return constr;
    }

    private static function eventNameByConstructor(constr:String):String
    {
        var name:String = constr.charAt(0).toLowerCase();
        var i:Int = 1;
        while (i < constr.length)
        {
            var char = constr.charAt(i);
            if (char.toLowerCase() != char)
                name += "_" + char.toLowerCase();
            else
                name += char;

            i++;
        }

        return name;
    }

    public static function connect(onConnected:Void->Void) 
    {
        allIncomingEventNames = IncomingEvent.getConstructors().map(eventNameByConstructor);

        #if prod
        _ws = new WebSocket("wss://play-intellector.ru:5000");
        #else
        _ws = new WebSocket("ws://localhost:5000");
        #end
        _ws.onopen = onConnectionOpen;
        _ws.onmessage = onMessageRecieved;
        _ws.onclose = onConnectionClosed;
        _ws.onerror = onConnectionError;
    }
    
    public static function dropConnection() 
    {
        if (_ws != null)
        {
            suppressAlert = true;
            _ws.close();
            _ws = null;
        }
    }

    private static function onConnectionOpen()
    {
        suppressAlert = false;
        on("dont_reconnect", onReconnectionForbidden);
        onConnected();
    }

    private static function onMessageRecieved(msg)
    {
        var str:String = msg.toString();
        var rawEvent:RawNetEvent = Json.parse(str.substring(11, str.length - 1));
        var callback = eventMap.get(rawEvent.name);

        if (callback != null)
            callback(rawEvent.data);

        if (allIncomingEventNames.has(rawEvent.name))
        {
            var event:IncomingEvent = IncomingEvent.createByName(eventConstructorByName(rawEvent.name), rawEvent.data);
            for (obs in observers)
                obs.handleNetEvent(event);
        }
        else if (callback == null)
            trace("Unexpected event: " + rawEvent.name);
    }

    private static function onConnectionClosed()
    {
        _ws = null;
        ScreenManager.instance.toEmpty();
        if (suppressAlert)
            trace("Connection closed");
        else
        {
            Dialogs.alert(Dictionary.getPhrase(CONNECTION_LOST_ERROR), "Alert");
            suppressAlert = true;
        }
        if (!doNotReconnect)
            connect(onConnected);
    }

    private static function onConnectionError(err:js.html.Event)
    {
        if (suppressAlert)
            trace("Connection abrupted");
        else
        {
            Dialogs.alert(Dictionary.getPhrase(CONNECTION_ERROR_OCCURED) + err.type, "Error");
            suppressAlert = true;
        }
    }

    private static function onReconnectionForbidden(e) 
    {
        doNotReconnect = true;
        Dialogs.alert("Session closed", "Alert");
    }

    //------------------------------------------------------------------------------------------------------------------------------------------------------

    //TODO: Remove remaining

    public static function signin(login:String, password:String, onPlainAnswer:String->Void, onOngoingGame:OngoingBattleData->Void) 
    {
        Networker.login = login;
        onceOneOf([
            'login_result' => onPlainAnswer,
            'ongoing_game' => onOngoingGame
        ]);
        emit('login', {login: login, password: password});
    }

    public static function register(login:String, password:String, onAnswer:String->Void) 
    {
        Networker.login = login;
        once('register_result', onAnswer);
        emit('register', {login: login, password: password});
    }

    public static function acceptOpen(caller:String) 
    {
        if (Networker.login == null)
            Networker.login = "guest_" + Math.ceil(Math.random() * 100000);
        once("one_time_login_details", (data) ->
        {
            Utils.saveLoginDetails(login, data.password);
        });
        emit('accept_open_challenge', {caller_login: caller, callee_login: Networker.login});
    }

    private static function challengeReceiver(data:{caller:String, startSecs:Int, bonusSecs:Int, color:String}) 
    {
        var onConfirmed = () -> {emit('accept_challenge', {caller_login: data.caller, callee_login: Networker.login});};
        var onDeclined = () -> {emit('decline_challenge', {caller_login: data.caller, callee_login: Networker.login});};

        Assets.getSound("sounds/social.mp3").play();
        Dialogs.confirm(Dictionary.getIncomingChallengeText(data), Dictionary.getPhrase(INCOMING_CHALLENGE_TITLE), onConfirmed, onDeclined);
    }

    public static function sendChallenge(callee:String, secsStart:Int, secsBonus:Int, color:Null<PieceColor>) 
    {
        var onSuccess = (d) -> {
            Assets.getSound("sounds/challenge_sent.mp3").play();
            Dialogs.info(Dictionary.getPhrase(SEND_CHALLENGE_RESULT_SUCCESS) + '${d.callee}!', Dictionary.getPhrase(SEND_CHALLENGE_RESULT_SUCCESS_TITLE));
        };
        var onDeclined = (d) -> {Dialogs.info('${d.callee}' + Dictionary.getPhrase(SEND_CHALLENGE_RESULT_DECLINED), Dictionary.getPhrase(SEND_CHALLENGE_RESULT_DECLINED_TITLE));};
        var onSame = (d) -> {Dialogs.alert(Dictionary.getPhrase(SEND_CHALLENGE_RESULT_SAME), Dictionary.getPhrase(SEND_CHALLENGE_RESULT_ERROR_TITLE));};
        var onRepeated = (d) -> {Dialogs.alert(Dictionary.getPhrase(SEND_CHALLENGE_RESULT_REPEATED), Dictionary.getPhrase(SEND_CHALLENGE_RESULT_ERROR_TITLE));};
        var onOffline = (d) -> {Dialogs.alert(Dictionary.getPhrase(SEND_CHALLENGE_RESULT_OFFLINE), Dictionary.getPhrase(SEND_CHALLENGE_RESULT_ERROR_TITLE));};
        var onIngame = (d) -> {Dialogs.alert(Dictionary.getPhrase(SEND_CHALLENGE_RESULT_BUSY), Dictionary.getPhrase(SEND_CHALLENGE_RESULT_ERROR_TITLE));};

        once('challenge_declined', onDeclined);
        onceOneOf(['callee_same' => onSame, 'callout_success' => onSuccess, 'repeated_callout' => onRepeated, 'callee_unavailable' => onOffline, 'callee_ingame' => onIngame]);
        emit('callout', {caller_login: Networker.login, callee_login: callee, secsStart: secsStart, secsBonus: secsBonus, color: color == null? null : color.getName()});
    }

    /*********************************************************************************************************************************************
        Basic underlying methods
    **********************************************************************************************************************************************/

    public static function on(eventName:String, callback:Dynamic->Void) 
    {
        eventMap[eventName] = callback;
    }

    public static function once(eventName:String, callback:Dynamic->Void) 
    {
        eventMap[eventName] = off.bind(eventName).combineSecond(callback);
    }

    public static function onceOneOf(callbacks:Map<String, Dynamic->Void>) 
    {
        var disableAll:Void->Void = () -> {
            for (eventName in callbacks.keys())
                off(eventName);
        };
        
        for (eventName => callback in callbacks.keyValueIterator())
            on(eventName, disableAll.combineSecond(callback));
    }

    public static function off(eventName:String) 
    {
        eventMap.remove(eventName);
    }

    public static function emitEvent(event:OutgoingEvent)
    {
        emit(eventNameByConstructor(event.getName()), event.getParameters()[0]);
    }

    private static function emit(eventName:String, data:Dynamic) 
    {
        var event:RawNetEvent = {name: eventName, data: data};
        _ws.send(Json.stringify(event));
    }
}