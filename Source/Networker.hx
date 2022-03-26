package;

import net.GeneralObserver;
import net.Handler;
import net.ClientEvent;
import net.ServerEvent;
import net.EventProcessingQueue;
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

using utils.CallbackTools;
using StringTools;
using Lambda;

typedef RawNetEvent =
{
    var name:String;
    var data:Dynamic;
}

class Networker
{
    private static var _ws:WebSocket;

    public static var eventQueue:EventProcessingQueue;
    public static var onConnectionEstabilished:Void->Void;

    public static var suppressAlert:Bool;
    public static var doNotReconnect:Bool = false;
    public static var ignoreEmitCalls:Bool = false; 

    public static function connect() 
    {
        var generalObserver:GeneralObserver = new GeneralObserver();
        eventQueue = new EventProcessingQueue();
        eventQueue.addObserver(generalObserver);

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
        onConnectionEstabilished();
    }

    private static function onMessageRecieved(msg)
    {
        var str:String = msg.toString();
        var rawEvent:RawNetEvent = Json.parse(str.substring(11, str.length - 1));

        if (ServerEvent.getConstructors().has(rawEvent.name))
        {
            var event:ServerEvent = ServerEvent.createByName(rawEvent.name, rawEvent.data);
            eventQueue.processEvent(event);
        }
        else
            trace("Unexpected event: " + rawEvent.name);
    }

    private static function onConnectionClosed()
    {
        _ws = null;
        ScreenManager.clearScreen();
        if (suppressAlert)
            trace("Connection closed");
        else
        {
            Dialogs.alert(Dictionary.getPhrase(CONNECTION_LOST_ERROR), "Alert");
            suppressAlert = true;
        }
        if (!doNotReconnect)
            connect();
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

    //------------------------------------------------------------------------------------------------------------------------------------------------------

    //TODO: Move to ChallengeManager (or smth like that)

    /*public static function acceptOpen(caller:String) 
    {
        if (Networker.login == null)
            Networker.login = "guest_" + Math.ceil(Math.random() * 100000);
        once("one_time_login_details", (data) ->
        {
            Utils.saveLoginDetails(login, data.password);
        });
        emit('accept_open_challenge', {caller_login: caller, callee_login: Networker.login});
    }*/

    //=======================================================================================================================

    public static function emitEvent(event:ClientEvent)
    {
        if (ignoreEmitCalls)
            trace(event.getName(), event.getParameters());
        else
            emit(event.getName(), event.getParameters());
    }

    private static function emit(eventName:String, data:Dynamic) 
    {
        var event:RawNetEvent = {name: eventName, data: data};
        _ws.send(Json.stringify(event));
    }
}