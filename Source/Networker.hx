package;

import js.html.Event;
import net.shared.ClientEvent;
import net.shared.ServerEvent;
import net.EventProcessingQueue;
import gfx.Dialogs;
import gfx.ScreenManager;
import struct.PieceColor;
import dict.Dictionary;
import struct.PieceType;
import openfl.utils.Assets;
import js.Browser;
import haxe.Json;
import hx.ws.WebSocket;
import haxe.Timer;

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

    public static var eventQueue:EventProcessingQueue = new EventProcessingQueue();
    public static var onConnectionEstabilished:Void->Void;
    public static var onConnectionFailed:Event->Void;

    private static var suppressAlert:Bool;
    private static var backoffDelay:Float;
    private static var doNotReconnect:Bool = false;
    public static var ignoreEmitCalls:Bool = false; 

    public static function launch() 
    {
        eventQueue.flush();

        #if prod
        _ws = new WebSocket("wss://play-intellector.ru:5000");
        #else
        _ws = new WebSocket("ws://localhost:5000");
        #end
        _ws.onopen = onConnectionOpen;
        _ws.onmessage = onMessageRecieved;
        _ws.onclose = onConnectionClosed;
        _ws.onerror = onConnectionFailed;
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
        _ws.onerror = onConnectionError;
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
            if (event == DontReconnect)
                onReconnectionForbidden();
            else
                eventQueue.processEvent(event);
        }
        else
            trace("Unexpected event: " + rawEvent.name);
    }

    private static function onConnectionClosed() //TODO: Check logic
    {
        ScreenManager.clearScreen();
        if (suppressAlert)
            trace("Connection closed");
        else
        {
            Dialogs.alert(CONNECTION_LOST_ERROR, CONNECTION_ERROR_DIALOG_TITLE);
            suppressAlert = true;
        }
        if (!doNotReconnect)
            startReconnectAttempts(onConnectionOpen);
    }

    private static function onConnectionError(err:Event)
    {
        trace("Connection error: " + err.type);
        ScreenManager.onConnectionError();
    }

    public static function startReconnectAttempts(onConnected:Void->Void)
    {
        backoffDelay = 1000;
        _ws.onopen = onConnected;
        _ws.onerror = (e) -> {
            Timer.delay(_ws.open, Math.round(backoffDelay));
            if (backoffDelay < 16000)
                backoffDelay += backoffDelay * (Math.random() - 0.5);
            else
                backoffDelay += 1000 * (Math.random() - 0.5);
        };
        _ws.open();
    }

    private static function onReconnectionForbidden() 
    {
        doNotReconnect = true;
        Dialogs.alert(SESSION_CLOSED_ALERT_TEXT, SESSION_CLOSED_ALERT_TITLE);
    }

    //------------------------------------------------------------------------------------------------------------------------------------------------------

    public static function addHandler(handler:ServerEvent->Bool)
    {
        eventQueue.addHandler(handler);
    }

    public static function removeHandler(handler:ServerEvent->Bool)
    {
        eventQueue.removeHandler(handler);
    }

    public static function removeObserver(observer:INetObserver)
    {
        eventQueue.removeObserver(observer);
    }

    public static function addObserver(observer:INetObserver)
    {
        eventQueue.addObserver(observer);
    }

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