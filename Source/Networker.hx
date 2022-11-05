package;

import js.Browser;
import serialization.GameLogParser;
import gfx.ScreenNavigator;
import browser.CredentialCookies;
import net.shared.GreetingResponseData;
import net.Requests;
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

    private static var suppressAlert:Bool;
    private static var backoffDelay:Float;
    private static var doNotReconnect:Bool = false;
    private static var reconnectionToken:String = "not_set";
    public static var ignoreEmitCalls:Bool = false; 

    public static function getSessionID():String
    {
        return reconnectionToken.split('_')[1];
    }

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

    private static function onConnectionFailed(e)
    {
        ScreenNavigator.toAnalysis();
        //TODO: Show explanatory dialog
        startReconnectionAttempts(onConnectionOpen);
    }

    private static function onConnectionOpen()
    {
        _ws.onerror = onConnectionError;
        suppressAlert = false;

        SceneManager.observeNetEvents();

        if (CredentialCookies.hasLoginDetails())
            Requests.greet(Login(CredentialCookies.getLogin(), CredentialCookies.getPassword()), onGreetingAnswered);
		else
            Requests.greet(Simple, onGreetingAnswered);
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
                    trace("Failed to deserialize message: " + content);
                    trace(e);
                    return;
                }
        }

        switch event
        {
            case DontReconnect:
                doNotReconnect = true;
                suppressAlert = true;
                Dialogs.alert(SESSION_CLOSED_ALERT_TEXT, SESSION_CLOSED_ALERT_TITLE);
            default:
                eventQueue.processEvent(event);
        }
    }

    private static function onConnectionClosed()
    {
        if (doNotReconnect)
        {
            SceneManager.clearScreen();

            if (!suppressAlert)
            {
                Dialogs.alert(CONNECTION_LOST_ERROR, CONNECTION_ERROR_DIALOG_TITLE);
                suppressAlert = true;
            }
            else
                trace("Connection closed");
        }
        else
        {
            SceneManager.onDisconnected();
            Dialogs.reconnectionDialog();
            startReconnectionAttempts(onConnectionReopened);
        }
    }

    private static function onConnectionError(err:Event)
    {
        trace("Connection error: " + err.type);
    }

    private static function onConnectionReopened()
    {
        _ws.onerror = onConnectionError;
        suppressAlert = false;
        Requests.greet(Reconnect(reconnectionToken), onGreetingAnswered);
    }

	private static function onGreetingAnswered(data:GreetingResponseData)
	{
		switch data 
		{
			case ConnectedAsGuest(token, invalidCredentials):
                reconnectionToken = token;
                if (invalidCredentials)
                    CredentialCookies.removeLoginDetails();
				ScreenNavigator.navigate();
			case Logged(token, incomingChallenges, ongoingFiniteGame):
                reconnectionToken = token;
                LoginManager.assignCredentials(CredentialCookies.getLogin(), CredentialCookies.getPassword(), None);
                GlobalBroadcaster.broadcast(IncomingChallengesBatch(incomingChallenges));
                if (ongoingFiniteGame != null)
                {
                    var parsedData:GameLogParserOutput = GameLogParser.parse(ongoingFiniteGame.currentLog);
                    SceneManager.toScreen(LiveGame(ongoingFiniteGame.id, Ongoing(parsedData, ongoingFiniteGame.timeData, null)));
                }
                else
				    ScreenNavigator.navigate();
			case Reconnected(missedEvents):
                Dialogs.closeReconnectionDialog();
                SceneManager.onConnected();
                for (missedEvent in missedEvents)
                    eventQueue.processEvent(missedEvent);
            case NotReconnected:
                Browser.location.reload(false);
		}
	}

    public static function startReconnectionAttempts(onOpen:Void->Void)
    {
        backoffDelay = 1000;
        _ws.onopen = onOpen;
        _ws.onerror = (e) -> {
            Timer.delay(_ws.open, Math.round(backoffDelay));
            if (backoffDelay < 16000)
                backoffDelay += backoffDelay * (Math.random() - 0.5);
            else
                backoffDelay += 1000 * (Math.random() - 0.5);
        };
        _ws.open();
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