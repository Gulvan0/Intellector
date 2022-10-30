package;

import hx.ws.Types.MessageType;
import haxe.Unserializer;
import haxe.Serializer;
import js.html.Event;
import net.shared.ClientEvent;
import net.shared.ServerEvent;
import net.shared.SessionRestorationResult;
import net.EventProcessingQueue;
import gfx.Dialogs;
import gfx.SceneManager;
import hx.ws.WebSocket;
import haxe.Timer;

using utils.CallbackTools;
using StringTools;
using Lambda;

class Networker
{
    private static var _ws:WebSocket;

    public static var eventQueue:EventProcessingQueue = new EventProcessingQueue();
    public static var onConnectionEstabilished:Void->Void;

    private static var suppressAlert:Bool;
    private static var backoffDelay:Float;
    private static var doNotReconnect:Bool = false;
    private static var reconnectionToken:String = "not_set";
    public static var ignoreEmitCalls:Bool = false; 

    public static function launch() 
    {
        Serializer.USE_ENUM_INDEX = true;

        eventQueue.flush();

        #if prod
        _ws = new WebSocket("wss://play-intellector.ru:5000");
        #else
        _ws = new WebSocket("ws://localhost:5000");
        #end
        _ws.onopen = onConnectionOpen;
        _ws.onmessage = onMessageRecieved;
        _ws.onclose = onConnectionClosed;
        _ws.onerror = startReconnectionAttempts.bind(onConnectionOpen); //Will be changed to SceneManager handler after the connection is open
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

    private static function onMessageRecieved(msg:MessageType)
    {
        var event:ServerEvent;

        switch msg 
        {
            case BytesMessage(content):
                trace("Unexpected bytes: " + content.readAllAvailableBytes().toString());
                return;
            case StrMessage(content):
                try
                {
                    event = Unserializer.run(content);
                }
                catch (e)
                {
                    trace("Unexpected message: " + content);
                    return;
                }
        }

        switch event
        {
            case DontReconnect:
                onReconnectionForbidden();
            case SessionToken(token):
                reconnectionToken = token;
                LoginManager.sessionID = token.split('_')[1];
            default:
                eventQueue.processEvent(event);
        }
    }

    private static function onConnectionClosed()
    {
        SceneManager.clearScreen();

        if (suppressAlert)
            trace("Connection closed");
        else
        {
            Dialogs.alert(CONNECTION_LOST_ERROR, CONNECTION_ERROR_DIALOG_TITLE);
            suppressAlert = true;
        }
        
        if (!doNotReconnect)
            startReconnectionAttempts(onConnectionOpen);
    }

    private static function onConnectionError(err:Event)
    {
        trace("Connection error: " + err.type);
        SceneManager.onConnectionError();
    }

    public static function startReconnectionAttempts(onConnected:Void->Void)
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

    public static function startSessionRestorationAttempts(onRestored:Void->Void, onNotRestored:Void->Void)
    {
        startReconnectionAttempts(() -> {
            addHandler(sessionRestorationHandler.bind(onRestored, onNotRestored));
            emitEvent(RestoreSession(reconnectionToken));
        });
    }

    private static function sessionRestorationHandler(onRestored:Void->Void, onNotRestored:Void->Void, event:ServerEvent):Bool
    {
        switch event 
        {
            case RestoreSessionResult(result):
                switch result 
                {
                    case Restored(missedEvents):
                        for (missedEvent in missedEvents)
                            eventQueue.processEvent(missedEvent);
                        onRestored();
                    case NotRestored:
                        onNotRestored();
                }
            default:
                return false;
        }
        return true;
    }

    private static function onReconnectionForbidden() 
    {
        doNotReconnect = true;
        suppressAlert = true;
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
            _ws.send(Serializer.run(event));
    }
}